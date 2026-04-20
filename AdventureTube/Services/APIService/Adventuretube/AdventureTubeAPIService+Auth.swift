//
//  AdventureTubeAPIService+Auth.swift
//  AdventureTube
//
//  Authentication endpoints: register, login, refresh, signOut
//

import Foundation
import Combine

extension AdventureTubeAPIService {

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

        
        
        
        /*
           output here is: (data: Data, response: URLResponse)
           - data:     raw JSON bytes sent from the server (e.g. ServiceResponse body)
           - response: HTTP response containing status code, headers, and URL
           Both are needed: status code routes the error handling, data carries the payload to decode
           */    
        return self.session.dataTaskPublisher(for: request)
            .tryMap { output in
                 try self.handleHttpResponse(output, decodingType: ServiceResponse<AuthTokenData>.self)
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
    func loginWithGoogleIdToken(adventureUser: UserModel) -> AnyPublisher<ServiceResponse<AuthTokenData>, Error> {
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
    /// If expired/invalid, gateway returns 401 immediately (no downstream service calls).
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
}
