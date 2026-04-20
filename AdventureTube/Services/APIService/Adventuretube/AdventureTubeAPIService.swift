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
//
//  File Organization:
//  - AdventureTubeAPIService.swift          — Core infrastructure (this file)
//  - AdventureTubeAPIService+Auth.swift     — Authentication endpoints
//  - AdventureTubeAPIService+Geo.swift      — Geo data endpoints (publish, delete, fetch, SSE)
//  - AdventureTubeAPIService+Story.swift    — Story/Moments sync (currently unused)

import Foundation
import UIKit
import Combine

class AdventureTubeAPIService: NSObject, AdventureTubeAPIProtocol {

    // MARK: - Singleton

    static let shared = AdventureTubeAPIService()

    // MARK: - Properties

    var cancellables = Set<AnyCancellable>()
    var targetServerAddress: String = "https://api.travel-tube.com"
    var activeSSEClient: SSEClient?

    let session: URLSession = {
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
    func decodeError(_ data: Data, defaultMessage: String) -> (message: String, errorCode: String?) {
        guard let serviceResponse = try? JSONDecoder().decode(ServiceResponse<String>.self, from: data),
           let message = serviceResponse.message else {
            return (defaultMessage, nil)
        }
        return (message, serviceResponse.errorCode)
    }

    /// Unified HTTP response handler — maps status codes to BackendError cases
    /// Used by all API methods to ensure consistent error handling
    func handleHttpResponse<T: Decodable>(_ result: URLSession.DataTaskPublisher.Output, decodingType: T.Type) throws -> T {
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
    func withTokenRefresh<T>(
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

                        print("Token  refreshed — retrying original request")
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
