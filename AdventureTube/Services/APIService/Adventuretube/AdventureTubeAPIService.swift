//
//  AdventureTubeAPIService.swift
//  AdventureTube
//
//  Created by chris Lee on 29/11/2023.
//  API Service  will be used by user
//  with adventuretube_id, refresh_token , access_token ....
//  so its crutial that user data has been set and update accordingly
//  in order to do that userdata will come from LoginManager.userData

import Foundation
import UIKit
import Combine

class AdventureTubeAPIService : NSObject , AdventureTubeAPIProtocol {

    //This is SingleTon Parttern
    static let shared = AdventureTubeAPIService()
    private var cancellables = Set<AnyCancellable>()
    //private  var targetServerAddress: String = "http://192.168.1.105:8030"
    private  var targetServerAddress: String = "https://api.travel-tube.com"

    /// Active SSE client for job status streaming
    private var activeSSEClient: SSEClient?

    // URLSession with timeout configuration
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 600 // 30 seconds for request timeout
        configuration.timeoutIntervalForResource = 600 // 60 seconds for resource timeout
        return URLSession(configuration: configuration)
    }()

    // MARK: - Utility / Shared Helpers

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
                }, receiveValue: {  data in
                    promise(.success(data)
                    ) })
                .store(in: &self.cancellables)
        }
    }

    private func decodeError<T:Decodable> (_ data:Data, to type: T.Type , defaultMessage: String) -> String {
        let decodedError = try? JSONDecoder().decode(type, from:  data)
        return (decodedError as? AuthResponse)?.errorMessage ?? defaultMessage
    }

    private func handleHttpResponse<T:Decodable>(_ result:URLSession.DataTaskPublisher.Output, decodingType: T.Type) throws -> T{
        guard let httpResponse  = result.response as? HTTPURLResponse else {
            throw BackendError.unknownError
        }
        switch httpResponse.statusCode {
            case 200...299:
                return try JSONDecoder().decode(decodingType, from: result.data)
            case 401:
                let errorMessage = decodeError( result.data, to: AuthResponse.self, defaultMessage: NSLocalizedString("Unauthorized access.", comment: ""))
                throw BackendError.unauthorized(message: errorMessage)
            case 404:
                let errorMessage = decodeError( result.data, to: AuthResponse.self, defaultMessage: NSLocalizedString("Resource not found.", comment: ""))
                throw BackendError.notFound(message: errorMessage)
            case 409:
                let errorMessage = decodeError( result.data, to: AuthResponse.self, defaultMessage: NSLocalizedString("Resource conflict.", comment: ""))
                throw BackendError.conflict(message: errorMessage)
            case 500:
                let errorMessage = decodeError( result.data, to: AuthResponse.self, defaultMessage: NSLocalizedString("Internal server error.", comment: ""))
                throw BackendError.internalServerError(message: errorMessage)
            case 502, 503, 504:
                if let serviceResponse = try? JSONDecoder().decode(ServiceResponse<String>.self, from: result.data),
                   let message = serviceResponse.message {
                    throw BackendError.serverError(message: message)
                }
                let rawBody = String(data: result.data, encoding: .utf8) ?? "Service unavailable"
                throw BackendError.serverError(message: "Service temporarily unavailable (\(httpResponse.statusCode)): \(rawBody)")
            default:
                let errorMessage = decodeError( result.data, to: AuthResponse.self, defaultMessage: NSLocalizedString("Unknown error.", comment: ""))
                throw BackendError.serverError(message: errorMessage)
            }
    }

    // MARK: - Token Refresh Interceptor

    /// Wraps an authenticated request with automatic token refresh on 401.
    /// 1. Executes the request with the current access token
    /// 2. If 401 → calls refreshToken() → updates LoginManager → retries once
    /// 3. If refresh fails → forces sign out → login screen
    private func withTokenRefresh<T>(
        _ makeRequest: @escaping (String) -> AnyPublisher<T, Error>
    ) -> AnyPublisher<T, Error> {
        guard let accessToken = LoginManager.shared.userData.adventuretubeAcessJWTToken else {
            return Fail(error: BackendError.unauthorized(message: "No access token available"))
                .eraseToAnyPublisher()
        }

        return makeRequest(accessToken)
            .catch { [weak self] error -> AnyPublisher<T, Error> in
                // Only attempt refresh for unauthorized errors
                guard let self = self,
                      let backendError = error as? BackendError,
                      case .unauthorized = backendError else {
                    return Fail(error: error).eraseToAnyPublisher()
                }

                print("401 detected — attempting token refresh")

                let userData = LoginManager.shared.userData
                return self.refreshToken(adventureUser: userData)
                    .flatMap { authResponse -> AnyPublisher<T, Error> in
                        guard let newAccessToken = authResponse.accessToken,
                              let newRefreshToken = authResponse.refreshToken else {
                            return Fail(error: BackendError.unauthorized(message: "Token refresh returned no tokens"))
                                .eraseToAnyPublisher()
                        }

                        // Update stored tokens
                        DispatchQueue.main.async {
                            var updatedUser = LoginManager.shared.userData
                            updatedUser.adventuretubeAcessJWTToken = newAccessToken
                            updatedUser.adventuretubeRefreshJWTToken = newRefreshToken
                            LoginManager.shared.updateUserData(updatedUser)
                        }

                        print("Token refreshed — retrying original request")

                        // Retry with new token
                        return makeRequest(newAccessToken)
                    }
                    .catch { refreshError -> AnyPublisher<T, Error> in
                        // Refresh failed — force sign out
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

    // MARK: - Authentication (Create/Read tokens)

    func registerUser(adventureUser: UserModel) -> AnyPublisher<AuthResponse, Error> {
        guard let url = URL(string: "\(targetServerAddress)/auth/users") else {
            fatalError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Safely unwrap optional properties
        guard let idToken = adventureUser.idToken,
              let email = adventureUser.emailAddress
        else {
            fatalError("Missing user information")
        }
        let body: [String: Any] = [
            "googleIdToken": idToken,"email":email
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        print("Request URL: \(url.absoluteString)")
        print("googleIdToken : \(idToken)")
        print("googleIdToken : \(email)")

        return self.session.dataTaskPublisher(for: request)
            .tryMap {
                try self.handleHttpResponse($0, decodingType: AuthResponse.self)
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

    func loginWithPassword(adventureUser: UserModel) -> AnyPublisher<AuthResponse, Error> {
        guard let url = URL(string: "\(targetServerAddress)/auth/token") else {
            fatalError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Safely unwrap optional properties
        guard let idToken = adventureUser.idToken
        else {
            fatalError("Missing user information")
        }
        let body: [String: Any] = [
            "googleIdToken": idToken,
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        print("googleIdToken : \(idToken)")
        print("Request URL: \(url.absoluteString)")

        return self.session.dataTaskPublisher(for: request)
            .tryMap { result -> AuthResponse in
                // Add detailed logging
                if let httpResponse = result.response as? HTTPURLResponse {
                    print("Response Status Code: \(httpResponse.statusCode)")
                }
                if let responseString = String(data: result.data, encoding: .utf8) {
                    print("Response Body: \(responseString)")
                }
                return try self.handleHttpResponse(result, decodingType: AuthResponse.self)
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

    func refreshToken(adventureUser: UserModel) -> AnyPublisher<AuthResponse, Error> {
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
        guard let idToken = adventureUser.idToken
        else {
            fatalError("Missing user information")
        }
        let body: [String: Any] = [
            "googleIdToken": idToken
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        print("Sending refreshToken request to \(url.absoluteString) with refreshToken: \(refreshToken)")

        return self.session.dataTaskPublisher(for: request)
            .tryMap { try self.handleHttpResponse($0, decodingType: AuthResponse.self)
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

    func signOut() -> AnyPublisher<RestAPIResponse, Error> {
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
            .tryMap { try self.handleHttpResponse($0, decodingType: RestAPIResponse.self)
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

    // MARK: - Story CRUD (via /auth/geo/* — Kafka + SSE flow)

    // MARK: Create

    /// Publish geo data asynchronously via Kafka.
    /// Returns 202 Accepted with a trackingId for SSE streaming.
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

    // MARK: Read

    /// Fetch public geo data (adventure stories with locations) from backend
    /// - Returns: Publisher with array of AdventureTubeData or Error
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

    /// Open an SSE stream for real-time job status updates.
    func streamJobStatus(trackingId: String) -> AnyPublisher<JobStatusDTO, Error> {
        guard let url = URL(string: "\(targetServerAddress)/auth/geo/status/stream/\(trackingId)") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }

        guard let accessToken = LoginManager.shared.userData.adventuretubeAcessJWTToken else {
            return Fail(error: BackendError.unauthorized(message: "No access token available"))
                .eraseToAnyPublisher()
        }

        // Disconnect previous SSE client if any
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

    /// REST fallback to poll job status.
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

    // MARK: Delete

    /// Delete published geo data by youtubeContentId
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

    /// Cancel any active SSE connection
    func cancelSSEStream() {
        activeSSEClient?.disconnect()
        activeSSEClient = nil
    }

    // MARK: - Story/Moments Sync (via /api/stories/* — DEAD CODE, not called anywhere in the app)

    // MARK: Create

    /// Sync a complete story with all chapters and moments to backend
    func syncStory(_ story: StoryEntity) -> AnyPublisher<StoryResponse, Error> {
        guard let url = URL(string: "\(targetServerAddress)/api/stories") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }

        guard let accessToken = LoginManager.shared.userData.adventuretubeAcessJWTToken else {
            return Fail(error: BackendError.unauthorized(message: "No access token available"))
                .eraseToAnyPublisher()
        }

        // Convert CoreData entity to DTO
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

    // MARK: Read

    /// Fetch all stories for the current user from backend
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

    // MARK: Update

    /// Update an existing story on the backend
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

    // MARK: Delete

    /// Delete a story from the backend
    func deleteStory(_ storyId: String) -> AnyPublisher<RestAPIResponse, Error> {
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
            .tryMap { try self.handleHttpResponse($0, decodingType: RestAPIResponse.self) }
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
enum BackendError: LocalizedError {
    case unauthorized(message: String)
    case notFound(message: String)
    case conflict(message: String)
    case internalServerError(message: String)
    case serverError(message: String)
    case decodingError(message: String)
    case unknownError

    var errorDescription: String? {
        switch self {
            case .unauthorized(let message),
                    .notFound(let message),
                    .conflict(let message),
                    .internalServerError(let message),
                    .serverError(let message),
                    .decodingError(let message):
                return message
            case .unknownError:
                return NSLocalizedString("An unknown error occurred", comment: "")
        }
    }
}

enum NetworkError : Error {
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
