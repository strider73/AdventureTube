//
//  AdventureTubeAPIService.swift
//  AdventureTube
//
//  Created by chris Lee on 29/11/2023.
//
//  Backend API service layer for AdventureTube iOS app.
//  All authenticated requests require valid JWT tokens managed via LoginManager.userData.
//
//  Architecture:
//  - Singleton pattern via `shared` instance
//  - Uses Combine publishers for async request/response
//  - Token lifecycle: accessToken (short-lived) + refreshToken (long-lived)
//  - Gateway validates tokens before forwarding — expired tokens get 401 at gateway level
//
//  Token Refresh Flow:
//  1. On app launch: restorePreviousSignIn → refreshToken() called directly
//     - If 401 (expired/invalid refresh token) → signs user out
//     - Gateway now catches expired tokens early and returns 401 immediately
//  2. During normal usage: withTokenRefresh() interceptor wraps authenticated requests
//     - If 401 → auto-refreshes token → retries original request once
//     - If refresh also fails → forces sign out

import Foundation
import UIKit
import Combine

class AdventureTubeAPIService: NSObject, AdventureTubeAPIProtocol {

    // MARK: - Singleton

    static let shared = AdventureTubeAPIService()

    // MARK: - Properties

    private var cancellables = Set<AnyCancellable>()
    private var targetServerAddress: String = "https://api.travel-tube.com"
    private var activeSSEClient: SSEClient?

    private let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 600
        configuration.timeoutIntervalForResource = 600
        return URLSession(configuration: configuration)
    }()

    // MARK: - Utility / Shared Helpers

    /// Generic GET request for any Decodable type (no auth required)
    func getData<T: Decodable>(endpoint: String, id: Int? = nil, returnData: T.Type) -> Future<T, Error> {
        return Future<T, Error> { [weak self] promise in
            guard let self = self, let url = URL(string: endpoint) else {
                return promise(.failure(NetworkError.invalidURL))
            }
            print("URL is \(url.absoluteString)")
            self.session.dataTaskPublisher(for: url)
                .tryMap { (data, response) -> Data in
                    guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                        throw NetworkError.responseError
                    }
                    return data
                }
                .decode(type: T.self, decoder: JSONDecoder())
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: { (completion) in
                    if case let .failure(error) = completion {
                        switch error {
                            case let decodingError as DecodingError:
                                promise(.failure(decodingError))
                            case let apiError as NetworkError:
                                promise(.failure(apiError))
                            default:
                                promise(.failure(NetworkError.unknown))
                        }
                    }
                }, receiveValue: { data in
                    promise(.success(data))
                })
                .store(in: &self.cancellables)
        }
    }

  /// Decode a ServiceResponse error body, falling back to a default message.
    private func decodeError(_ data: Data, defaultMessage: String) -> (message: String, errorCode: String?) {
        // Try ServiceResponse format first: {success, message, errorCode, data, timestamp}
        guard let serviceResponse = try? JSONDecoder().decode(ServiceResponse<String>.self, from: data),
           let message = serviceResponse.message else {
            return (defaultMessage, nil)
        }
        return (message, serviceResponse.errorCode)

    }

    /// Unified HTTP response handler — maps status codes to BackendError cases
    /// Used by all API methods to ensure consistent error handling
    private func handleHttpResponse<T: Decodable>(_ result: URLSession.DataTaskPublisher.Output, decodingType: T.Type) throws -> T {
        guard let httpResponse = result.response as? HTTPURLResponse else {
            throw BackendError.unknownError
        }
        switch httpResponse.statusCode {
            case 200...299:
                return try JSONDecoder().decode(decodingType, from: result.data)
            case 400:
                let error = decodeError(result.data, defaultMessage: NSLocalizedString("Validation failed.", comment: ""))
                throw BackendError.badRequest(message: error.message, errorCode: error.errorCode)
            case 401:
                let error = decodeError(result.data, defaultMessage: NSLocalizedString("Unauthorized access.", comment: ""))
                throw BackendError.unauthorized(message: error.message, errorCode: error.errorCode)
            case 404:
                let error = decodeError(result.data, defaultMessage: NSLocalizedString("Resource not found.", comment: ""))
                throw BackendError.notFound(message: error.message, errorCode: error.errorCode)
            case 409:
                let error = decodeError(result.data, defaultMessage: NSLocalizedString("Resource conflict.", comment: ""))
                throw BackendError.conflict(message: error.message, errorCode: error.errorCode)
            case 500:
                let error = decodeError(result.data, defaultMessage: NSLocalizedString("Internal server error.", comment: ""))
                throw BackendError.internalServerError(message: error.message, errorCode: error.errorCode)
            case 502, 503, 504:
                let error = decodeError(result.data, defaultMessage: "Service temporarily unavailable (\(httpResponse.statusCode))")
                throw BackendError.serverError(message: error.message, errorCode: error.errorCode)
            default:
                let error = decodeError(result.data, defaultMessage: NSLocalizedString("Unknown error.", comment: ""))
                throw BackendError.serverError(message: error.message, errorCode: error.errorCode)
        }
    }

    // MARK: - Token Refresh Interceptor

    /// Wraps an authenticated request with automatic token refresh on 401.
    ///
    /// Flow:
    /// 1. Executes the request with the current access token
    /// 2. If 401 → calls refreshToken() → updates LoginManager → retries once
    /// 3. If refresh also fails → forces sign out → returns to login screen
    ///
    /// Note: This is used for in-session API calls (publishStory, deleteStory, etc.).
    /// The initial app launch uses refreshToken() directly from restorePreviousSignIn.
    private func withTokenRefresh<T>(
        _ makeRequest: @escaping (String) -> AnyPublisher<T, Error>
    ) -> AnyPublisher<T, Error> {
        guard let accessToken = LoginManager.shared.userData.adventuretubeAcessJWTToken else {
            return Fail(error: BackendError.unauthorized(message: "No access token available"))
                .eraseToAnyPublisher()
        }

        return makeRequest(accessToken)
            .catch { [weak self] error -> AnyPublisher<T, Error> in
                guard let self = self,
                      let backendError = error as? BackendError,
                      case .unauthorized = backendError else {
                    return Fail(error: error).eraseToAnyPublisher()
                }

                print("401 detected — attempting token refresh")

                let userData = LoginManager.shared.userData
                return self.refreshToken(adventureUser: userData)
                    .flatMap { response -> AnyPublisher<T, Error> in
                        guard let tokenData = response.data,
                              let newAccessToken = tokenData.accessToken,
                              let newRefreshToken = tokenData.refreshToken else {
                            return Fail(error: BackendError.unauthorized(message: "Token refresh returned no tokens"))
                                .eraseToAnyPublisher()
                        }

                        DispatchQueue.main.async {
                            var updatedUser = LoginManager.shared.userData
                            updatedUser.adventuretubeAcessJWTToken = newAccessToken
                            updatedUser.adventuretubeRefreshJWTToken = newRefreshToken
                            LoginManager.shared.updateUserData(updatedUser)
                        }

                        print("Token refreshed — retrying original request")
                        return makeRequest(newAccessToken)
                    }
                    .catch { refreshError -> AnyPublisher<T, Error> in
                        print("Token refresh failed — signing out")
                        DispatchQueue.main.async {
                            LoginManager.shared.updateLoginState(.signedOut)
                        }
                        return Fail(error: refreshError).eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Authentication

    /// Register a new user with Google ID token
    /// Endpoint: POST /auth/users
    func registerUser(adventureUser: UserModel) -> AnyPublisher<ServiceResponse<AuthTokenData>, Error> {
        guard let url = URL(string: "\(targetServerAddress)/auth/users") else {
            fatalError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        guard let idToken = adventureUser.idToken,
              let email = adventureUser.emailAddress
        else {
            fatalError("Missing user information")
        }
        let body: [String: Any] = [
            "googleIdToken": idToken, "email": email
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        print("Request URL: \(url.absoluteString)")
        print("googleIdToken: \(idToken)")
        print("email: \(email)")

        return self.session.dataTaskPublisher(for: request)
            .tryMap {
                try self.handleHttpResponse($0, decodingType: ServiceResponse<AuthTokenData>.self)
            }
            .mapError { error -> BackendError in
                if let backendError = error as? BackendError {
                    return backendError
                } else if let decodingError = error as? DecodingError {
                    return BackendError.decodingError(message: decodingError.localizedDescription)
                } else {
                    return BackendError.unknownError
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Login with Google ID token to obtain access + refresh tokens
    /// Endpoint: POST /auth/token
    func loginWithPassword(adventureUser: UserModel) -> AnyPublisher<ServiceResponse<AuthTokenData>, Error> {
        guard let url = URL(string: "\(targetServerAddress)/auth/token") else {
            fatalError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        guard let idToken = adventureUser.idToken else {
            fatalError("Missing user information")
        }
        let body: [String: Any] = [
            "googleIdToken": idToken,
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        print("googleIdToken: \(idToken)")
        print("Request URL: \(url.absoluteString)")

        return self.session.dataTaskPublisher(for: request)
            .tryMap { result -> ServiceResponse<AuthTokenData> in
                if let httpResponse = result.response as? HTTPURLResponse {
                    print("Response Status Code: \(httpResponse.statusCode)")
                }
                if let responseString = String(data: result.data, encoding: .utf8) {
                    print("Response Body: \(responseString)")
                }
                return try self.handleHttpResponse(result, decodingType: ServiceResponse<AuthTokenData>.self)
            }
            .mapError { error -> BackendError in
                print("Error Details: \(error)")
                print("Error Type: \(type(of: error))")
                if let backendError = error as? BackendError {
                    print("BackendError: \(backendError.localizedDescription)")
                    return backendError
                } else if let decodingError = error as? DecodingError {
                    print("DecodingError: \(decodingError)")
                    return BackendError.decodingError(message: decodingError.localizedDescription)
                } else {
                    print("Unknown error type: \(error.localizedDescription)")
                    return BackendError.unknownError
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Refresh the access token using the stored refresh token.
    /// Used in two scenarios:
    /// 1. App launch — called directly from restorePreviousSignIn to restore session
    /// 2. Token expired during usage — called by withTokenRefresh() interceptor
    ///
    /// The gateway validates the refresh token before forwarding to auth-service.
    //authRes/ If expired/invalid, gateway returns 401 immediately (no downstream service calls).
    /// Endpoint: POST /auth/token/refresh
    func refreshToken(adventureUser: UserModel) -> AnyPublisher<ServiceResponse<AuthTokenData>, Error> {
        guard let url = URL(string: "\(targetServerAddress)/auth/token/refresh") else {
            fatalError("Invalid URL")
        }

        guard let refreshToken = LoginManager.shared.userData.adventuretubeRefreshJWTToken else {
            print("refreshToken() - No refresh token available, skipping refresh")
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(refreshToken, forHTTPHeaderField: "Authorization")

        guard let idToken = adventureUser.idToken else {
            fatalError("Missing user information")
        }
        let body: [String: Any] = [
            "googleIdToken": idToken
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        print("Sending refreshToken request to \(url.absoluteString) with refreshToken: \(refreshToken)")

        return self.session.dataTaskPublisher(for: request)
            .tryMap { try self.handleHttpResponse($0, decodingType: ServiceResponse<AuthTokenData>.self) }
            .mapError { error -> BackendError in
                if let backendError = error as? BackendError {
                    return backendError
                } else if let decodingError = error as? DecodingError {
                    return BackendError.decodingError(message: decodingError.localizedDescription)
                } else {
                    return BackendError.unknownError
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Revoke the refresh token (sign out from backend)
    /// Endpoint: POST /auth/token/revoke
    ///  SignOut using a refresh token instead access because
    ///   1. This is delete process exposing of refresh token shouldn't be a issue because after deleting from DB, token become useless
    ///   2. Lot less chance of rejecting from gateway becuase of long life span
    func signOut() -> AnyPublisher<ServiceResponse<String>, Error> {
        guard let url = URL(string: "\(targetServerAddress)/auth/token/revoke") else {
            fatalError("Invalid URL")
        }

        guard let refreshToken = LoginManager.shared.userData.adventuretubeRefreshJWTToken else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(refreshToken, forHTTPHeaderField: "Authorization")
        print("Sending signOut request to \(url.absoluteString) with refreshToken: \(refreshToken)")

        return self.session.dataTaskPublisher(for: request)
            .tryMap { try self.handleHttpResponse($0, decodingType: ServiceResponse<String>.self) }
            .mapError { error -> BackendError in
                if let backendError = error as? BackendError {
                    return backendError
                } else if let decodingError = error as? DecodingError {
                    return BackendError.decodingError(message: decodingError.localizedDescription)
                } else {
                    return BackendError.unknownError
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Geo Story CRUD (via /auth/geo/* — Kafka + SSE flow)

    /// Publish geo data asynchronously via Kafka.
    /// Returns 202 Accepted with a trackingId for SSE streaming.
    /// Wrapped with withTokenRefresh for automatic 401 retry.
    /// Endpoint: POST /auth/geo/save
    func publishStory(_ jsonData: Data) -> AnyPublisher<ServiceResponse<JobStatusDTO>, Error> {
        guard let url = URL(string: "\(targetServerAddress)/auth/geo/save") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }

        return withTokenRefresh { accessToken in
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.httpBody = jsonData

            print("Publishing geo data to \(url.absoluteString)")

            return self.session.dataTaskPublisher(for: request)
                .tryMap { (data, response) -> ServiceResponse<JobStatusDTO> in
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        if let httpResponse = response as? HTTPURLResponse {
                            if httpResponse.statusCode == 401 {
                                let errorMessage = String(data: data, encoding: .utf8) ?? "Unauthorized"
                                throw BackendError.unauthorized(message: errorMessage)
                            }
                            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                            throw BackendError.serverError(message: "Publish failed (\(httpResponse.statusCode)): \(errorMessage)")
                        }
                        throw BackendError.unknownError
                    }
                    return try JSONDecoder().decode(ServiceResponse<JobStatusDTO>.self, from: data)
                }
                .mapError { error -> Error in error }
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    }

    /// Delete published geo data by youtubeContentId.
    /// Wrapped with withTokenRefresh for automatic 401 retry.
    /// Endpoint: DELETE /auth/geo/{youtubeContentId}
    func deleteStory(youtubeContentId: String) -> AnyPublisher<ServiceResponse<JobStatusDTO>, Error> {
        guard let url = URL(string: "\(targetServerAddress)/auth/geo/\(youtubeContentId)") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }

        return withTokenRefresh { accessToken in
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            print("Deleting geo data at \(url.absoluteString)")

            return self.session.dataTaskPublisher(for: request)
                .tryMap { (data, response) -> ServiceResponse<JobStatusDTO> in
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        if let httpResponse = response as? HTTPURLResponse {
                            if httpResponse.statusCode == 401 {
                                let errorMessage = String(data: data, encoding: .utf8) ?? "Unauthorized"
                                throw BackendError.unauthorized(message: errorMessage)
                            }
                            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                            throw BackendError.serverError(message: "Deleting failed (\(httpResponse.statusCode)): \(errorMessage)")
                        }
                        throw BackendError.unknownError
                    }
                    return try JSONDecoder().decode(ServiceResponse<JobStatusDTO>.self, from: data)
                }
                .mapError { error -> Error in error }
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    }

    /// Fetch public geo data — no authentication required
    /// Endpoint: GET /web/geo/data
    func fetchStory() -> AnyPublisher<[AdventureTubeData], Error> {
        guard let url = URL(string: "\(targetServerAddress)/web/geo/data") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        print("Fetching geo data from \(url.absoluteString)")

        return self.session.dataTaskPublisher(for: request)
            .tryMap { (data, response) -> GeoDataResponse in
                guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                    throw NetworkError.responseError
                }
                do {
                    return try JSONDecoder().decode(GeoDataResponse.self, from: data)
                } catch let decodingError as DecodingError {
                    print("GeoData DecodingError: \(decodingError)")
                    throw decodingError
                }
            }
            .map { $0.data }
            .mapError { error -> BackendError in
                if let backendError = error as? BackendError {
                    return backendError
                } else if let decodingError = error as? DecodingError {
                    return BackendError.decodingError(message: decodingError.localizedDescription)
                } else {
                    return BackendError.unknownError
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Job Status (SSE + Polling)

    /// Open an SSE stream for real-time job status updates
    /// Endpoint: GET /auth/geo/status/stream/{trackingId}
    func streamJobStatus(trackingId: String) -> AnyPublisher<JobStatusDTO, Error> {
        guard let url = URL(string: "\(targetServerAddress)/auth/geo/status/stream/\(trackingId)") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }

        guard let accessToken = LoginManager.shared.userData.adventuretubeAcessJWTToken else {
            return Fail(error: BackendError.unauthorized(message: "No access token available"))
                .eraseToAnyPublisher()
        }

        activeSSEClient?.disconnect()

        let sseClient = SSEClient()
        activeSSEClient = sseClient

        sseClient.connect(url: url, headers: [
            "Authorization": "Bearer \(accessToken)"
        ])

        print("SSE streaming job status from \(url.absoluteString)")

        return sseClient.publisher
            .tryMap { data -> JobStatusDTO in
                try JSONDecoder().decode(JobStatusDTO.self, from: data)
            }
            .eraseToAnyPublisher()
    }

    /// REST fallback to poll job status
    /// Endpoint: GET /auth/geo/status/{trackingId}
    func pollJobStatus(trackingId: String) -> AnyPublisher<ServiceResponse<JobStatusDTO>, Error> {
        guard let url = URL(string: "\(targetServerAddress)/auth/geo/status/\(trackingId)") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }

        guard let accessToken = LoginManager.shared.userData.adventuretubeAcessJWTToken else {
            return Fail(error: BackendError.unauthorized(message: "No access token available"))
                .eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        print("Polling job status from \(url.absoluteString)")

        return self.session.dataTaskPublisher(for: request)
            .tryMap { try self.handleHttpResponse($0, decodingType: ServiceResponse<JobStatusDTO>.self) }
            .mapError { error -> Error in error }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Cancel any active SSE connection
    func cancelSSEStream() {
        activeSSEClient?.disconnect()
        activeSSEClient = nil
    }

    // MARK: - Story/Moments Sync (via /api/stories/* — currently unused)

    /// Sync a complete story with all chapters and moments to backend
    /// Endpoint: POST /api/stories
    func syncStory(_ story: StoryEntity) -> AnyPublisher<StoryResponse, Error> {
        guard let url = URL(string: "\(targetServerAddress)/api/stories") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }

        guard let accessToken = LoginManager.shared.userData.adventuretubeAcessJWTToken else {
            return Fail(error: BackendError.unauthorized(message: "No access token available"))
                .eraseToAnyPublisher()
        }

        let storyDTO = story.toDTO()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONEncoder().encode(storyDTO)
            print("Syncing story to \(url.absoluteString)")
            print("Story ID: \(storyDTO.id), Youtube ID: \(storyDTO.youtubeId)")
        } catch {
            return Fail(error: BackendError.decodingError(message: "Failed to encode story: \(error.localizedDescription)"))
                .eraseToAnyPublisher()
        }

        return self.session.dataTaskPublisher(for: request)
            .tryMap { try self.handleHttpResponse($0, decodingType: StoryResponse.self) }
            .mapError { error -> BackendError in
                if let backendError = error as? BackendError {
                    return backendError
                } else if let decodingError = error as? DecodingError {
                    return BackendError.decodingError(message: decodingError.localizedDescription)
                } else {
                    return BackendError.unknownError
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Sync individual moments (places) to a specific story
    /// Endpoint: POST /api/stories/{storyId}/moments
    func syncMoments(_ moments: [PlaceEntity], toStory storyId: String) -> AnyPublisher<MomentSyncResponse, Error> {
        guard let url = URL(string: "\(targetServerAddress)/api/stories/\(storyId)/moments") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }

        guard let accessToken = LoginManager.shared.userData.adventuretubeAcessJWTToken else {
            return Fail(error: BackendError.unauthorized(message: "No access token available"))
                .eraseToAnyPublisher()
        }

        let momentDTOs = moments.map { $0.toDTO() }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONEncoder().encode(momentDTOs)
            print("Syncing \(momentDTOs.count) moments to story \(storyId)")
        } catch {
            return Fail(error: BackendError.decodingError(message: "Failed to encode moments: \(error.localizedDescription)"))
                .eraseToAnyPublisher()
        }

        return self.session.dataTaskPublisher(for: request)
            .tryMap { try self.handleHttpResponse($0, decodingType: MomentSyncResponse.self) }
            .mapError { error -> BackendError in
                if let backendError = error as? BackendError {
                    return backendError
                } else if let decodingError = error as? DecodingError {
                    return BackendError.decodingError(message: decodingError.localizedDescription)
                } else {
                    return BackendError.unknownError
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Fetch all stories for the current user from backend
    /// Endpoint: GET /api/stories
    func fetchUserStories() -> AnyPublisher<[StoryDTO], Error> {
        guard let url = URL(string: "\(targetServerAddress)/api/stories") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }

        guard let accessToken = LoginManager.shared.userData.adventuretubeAcessJWTToken else {
            return Fail(error: BackendError.unauthorized(message: "No access token available"))
                .eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        print("Fetching user stories from \(url.absoluteString)")

        return self.session.dataTaskPublisher(for: request)
            .tryMap { try self.handleHttpResponse($0, decodingType: [StoryDTO].self) }
            .mapError { error -> BackendError in
                if let backendError = error as? BackendError {
                    return backendError
                } else if let decodingError = error as? DecodingError {
                    return BackendError.decodingError(message: decodingError.localizedDescription)
                } else {
                    return BackendError.unknownError
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Update an existing story on the backend
    /// Endpoint: PUT /api/stories/{storyId}
    func updateStory(_ story: StoryEntity) -> AnyPublisher<StoryResponse, Error> {
        guard let url = URL(string: "\(targetServerAddress)/api/stories/\(story.id)") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }

        guard let accessToken = LoginManager.shared.userData.adventuretubeAcessJWTToken else {
            return Fail(error: BackendError.unauthorized(message: "No access token available"))
                .eraseToAnyPublisher()
        }

        let storyDTO = story.toDTO()

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONEncoder().encode(storyDTO)
            print("Updating story at \(url.absoluteString)")
        } catch {
            return Fail(error: BackendError.decodingError(message: "Failed to encode story: \(error.localizedDescription)"))
                .eraseToAnyPublisher()
        }

        return self.session.dataTaskPublisher(for: request)
            .tryMap { try self.handleHttpResponse($0, decodingType: StoryResponse.self) }
            .mapError { error -> BackendError in
                if let backendError = error as? BackendError {
                    return backendError
                } else if let decodingError = error as? DecodingError {
                    return BackendError.decodingError(message: decodingError.localizedDescription)
                } else {
                    return BackendError.unknownError
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Delete a story from the backend
    /// Endpoint: DELETE /api/stories/{storyId}
    func deleteStory(_ storyId: String) -> AnyPublisher<ServiceResponse<String>, Error> {
        guard let url = URL(string: "\(targetServerAddress)/api/stories/\(storyId)") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }

        guard let accessToken = LoginManager.shared.userData.adventuretubeAcessJWTToken else {
            return Fail(error: BackendError.unauthorized(message: "No access token available"))
                .eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        print("Deleting story \(storyId) from \(url.absoluteString)")

        return self.session.dataTaskPublisher(for: request)
            .tryMap { try self.handleHttpResponse($0, decodingType: ServiceResponse<String>.self) }
            .mapError { error -> BackendError in
                if let backendError = error as? BackendError {
                    return backendError
                } else if let decodingError = error as? DecodingError {
                    return BackendError.decodingError(message: decodingError.localizedDescription)
                } else {
                    return BackendError.unknownError
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - Error Types

enum BackendError: LocalizedError {
    case badRequest(message: String, errorCode: String? = nil)
    case unauthorized(message: String, errorCode: String? = nil)
    case notFound(message: String, errorCode: String? = nil)
    case conflict(message: String, errorCode: String? = nil)
    case internalServerError(message: String, errorCode: String? = nil)
    case serverError(message: String, errorCode: String? = nil)
    case decodingError(message: String)
    case unknownError

    var errorDescription: String? {
        switch self {
            case .badRequest(let message, _),
                    .unauthorized(let message, _),
                    .notFound(let message, _),
                    .conflict(let message, _),
                    .internalServerError(let message, _),
                    .serverError(let message, _),
                    .decodingError(let message):
                return message
            case .unknownError:
                return NSLocalizedString("An unknown error occurred", comment: "")
        }
    }

    var errorCode: String? {
        switch self {
            case .badRequest(_, let code),
                    .unauthorized(_, let code),
                    .notFound(_, let code),
                    .conflict(_, let code),
                    .internalServerError(_, let code),
                    .serverError(_, let code):
                return code
            case .decodingError, .unknownError:
                return nil
        }
    }
}

enum NetworkError: Error {
    case invalidURL
    case responseError
    case unknown
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
            case .invalidURL:
                return NSLocalizedString("Invalid URL", comment: "")
            case .responseError:
                return NSLocalizedString("Unexpected status code", comment: "")
            case .unknown:
                return NSLocalizedString("Unknown error", comment: "")
        }
    }
}
