//
//  AdventureTubeAPIService.swift
//  AdventureTube
//
//  Created by chris Lee on 29/11/2023.
//  API Service  will be used by user
//  with adventuretube_id, refresh_token , access_token ....
//  so its crutial that user data has been set and update accordingly
//  in order to do that userdata will come from LoginManager.userData

//https://medium.com/@hemalasanka/making-api-calls-with-ios-combines-future-publisher-7a5011f81c2

import Foundation
import UIKit
import Combine

class AdventureTubeAPIService : NSObject , AdventureTubeAPIPrototol {
    
    
    //This is SingleTon Parttern
    static let shared = AdventureTubeAPIService()
    private var cancellables = Set<AnyCancellable>() // (3)
    //    private var accessToken : String?
    //    private var refreshToken : String?
    private  var targetServerAddress: String = "http://192.168.1.106:8030"
    
    //    private  var targetServerAddress: String = "http://192.168.0.20:8030"
    //private  var targetServerAddress: String = "https://api.adventuretube.net"
    
    
    // URLSession with timeout configuration
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10 // 30 seconds for request timeout
        configuration.timeoutIntervalForResource = 10 // 60 seconds for resource timeout
        return URLSession(configuration: configuration)
    }()
    
    
    func getData<T: Decodable>(endpoint: String, id: Int? = nil, returnData: T.Type) -> Future<T, Error> {
        return Future<T, Error> { [weak self] promise in  // (4) -> Future Publisher
            guard let self = self, let url = URL(string: endpoint) else {
                return promise(.failure(NetworkError.invalidURL))
            }
            print("URL is \(url.absoluteString)")
            self.session.dataTaskPublisher(for: url) // (5) -> Publisher
                .tryMap { (data, response) -> Data in  // (6) -> Operator
                    guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                        throw NetworkError.responseError
                    }
                    return data
                }
                .decode(type: T.self, decoder: JSONDecoder())  // (7) -> Operator
                .receive(on: RunLoop.main) // (8) -> Sheduler Operator
                .sink(receiveCompletion: { (completion) in  // (9) -> Subscriber
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
                }, receiveValue: {  data in  // (10)
                    //print(data)
                    promise(.success(data)
                    ) })
                .store(in: &self.cancellables)  // (11)
        }
    }
    
    func registerUser(adventureUser: UserModel) -> AnyPublisher<AuthResponse, Error> {
        guard let url = URL(string: "\(targetServerAddress)/auth/register") else {
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
        return self.session.dataTaskPublisher(for: request)
            .tryMap { result -> Data in
                guard let httpResponse = result.response as? HTTPURLResponse else {
                    throw BackendError.unknownError
                }
                
                
                switch httpResponse.statusCode{
                    case 200...299:
                        return  result.data
                    case 401:
                        let errorResponse = try? JSONDecoder().decode(AuthResponse.self, from: result.data)
                        let errorMessage = errorResponse?.errorMessage ?? NSLocalizedString("Unauthorized access.", comment: "")
                        throw BackendError.unauthorized(message: errorMessage)
                    case 404:
                        let errorResponse = try? JSONDecoder().decode(AuthResponse.self, from: result.data)
                        let errorMessage = errorResponse?.errorMessage ?? NSLocalizedString("Resource not found.", comment: "")
                        throw BackendError.notFound(message: errorMessage)
                    case 409:
                        let errorResponse = try? JSONDecoder().decode(AuthResponse.self, from: result.data)
                        let errorMessage = errorResponse?.errorMessage ?? NSLocalizedString("Resource conflict", comment: "")
                        throw BackendError.notFound(message: errorMessage)
                    case 500:
                        let errorResponse = try? JSONDecoder().decode(AuthResponse.self, from: result.data)
                        let errorMessage = errorResponse?.errorMessage ?? NSLocalizedString("Internal server error.", comment: "")
                        throw BackendError.internalServerError(message: errorMessage)
                    default:
                        let errorResponse = try? JSONDecoder().decode(AuthResponse.self, from: result.data)
                        let errorMessage = errorResponse?.errorMessage ?? NSLocalizedString("Unknown Error", comment: "")
                        throw BackendError.serverError(message: errorMessage)
                }
                
            }
            .decode(type: AuthResponse.self, decoder: JSONDecoder())
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
        guard let url = URL(string: "\(targetServerAddress)/auth/login") else {
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
        return self.session.dataTaskPublisher(for: request)
            .tryMap { result -> Data in
                guard let httpResponse = result.response as? HTTPURLResponse else {
                    throw BackendError.unknownError
                }
                
                switch httpResponse.statusCode{
                    case 200...299:
                        return  result.data
                    case 401:
                        let errorResponse = try? JSONDecoder().decode(AuthResponse.self, from: result.data)
                        let errorMessage = errorResponse?.errorMessage ?? NSLocalizedString("Unauthorized access.", comment: "")
                        throw BackendError.unauthorized(message: errorMessage)
                    case 404:
                        let errorResponse = try? JSONDecoder().decode(AuthResponse.self, from: result.data)
                        let errorMessage = errorResponse?.errorMessage ?? NSLocalizedString("Resource not found.", comment: "")
                        throw BackendError.notFound(message: errorMessage)
                    case 409:
                        let errorResponse = try? JSONDecoder().decode(AuthResponse.self, from: result.data)
                        let errorMessage = errorResponse?.errorMessage ?? NSLocalizedString("Resource conflict", comment: "")
                        throw BackendError.notFound(message: errorMessage)
                    case 500:
                        let errorResponse = try? JSONDecoder().decode(AuthResponse.self, from: result.data)
                        let errorMessage = errorResponse?.errorMessage ?? NSLocalizedString("Internal server error.", comment: "")
                        throw BackendError.internalServerError(message: errorMessage)
                    default:
                        let errorResponse = try? JSONDecoder().decode(AuthResponse.self, from: result.data)
                        let errorMessage = errorResponse?.errorMessage ?? NSLocalizedString("Unknown Error", comment: "")
                        throw BackendError.serverError(message: errorMessage)
                }
            }
            .decode(type: AuthResponse.self, decoder: JSONDecoder())
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
    
    func refreshToken(adventureUser: UserModel) -> AnyPublisher<AuthResponse, Error> {
        guard let url = URL(string: "\(targetServerAddress)/auth/refreshToken") else {
            fatalError("Invalid URL")
        }
        
        guard let refreshToken = LoginManager.shared.userData.adventuretubeRefreshJWTToken else {
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
            .tryMap { result -> Data in
                guard let httpResponse = result.response as? HTTPURLResponse else {
                    throw BackendError.unknownError
                }
                
                
                switch httpResponse.statusCode{
                    case 200...299:
                        return  result.data
                    case 401:
                        let errorResponse = try? JSONDecoder().decode(RestAPIResponse.self, from: result.data)
                        let errorMessage = errorResponse?.message ?? NSLocalizedString("Unauthorized access.", comment: "")
                        throw BackendError.unauthorized(message: errorMessage)
                    case 404:
                        let errorResponse = try? JSONDecoder().decode(RestAPIResponse.self, from: result.data)
                        let errorMessage = errorResponse?.message ?? NSLocalizedString("Resource not found.", comment: "")
                        throw BackendError.notFound(message: errorMessage)
                    case 409:
                        let errorResponse = try? JSONDecoder().decode(RestAPIResponse.self, from: result.data)
                        let errorMessage = errorResponse?.message ?? NSLocalizedString("Resource conflict", comment: "")
                        throw BackendError.notFound(message: errorMessage)
                    case 500:
                        let errorResponse = try? JSONDecoder().decode(RestAPIResponse.self, from: result.data)
                        let errorMessage = errorResponse?.message ?? NSLocalizedString("Internal server error.", comment: "")
                        throw BackendError.internalServerError(message: errorMessage)
                    default:
                        let errorResponse = try? JSONDecoder().decode(RestAPIResponse.self, from: result.data)
                        let errorMessage = errorResponse?.message ?? NSLocalizedString("Unknown Error", comment: "")
                        throw BackendError.serverError(message: errorMessage)
                }
            }
            .decode(type: AuthResponse.self, decoder: JSONDecoder())
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
        guard let url = URL(string: "\(targetServerAddress)/auth/logout") else {
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
            .tryMap { result -> Data in
                guard let httpResponse = result.response as? HTTPURLResponse else {
                    throw BackendError.unknownError
                }
                
                
                switch httpResponse.statusCode{
                    case 200...299:
                        return  result.data
                    case 401:
                        let errorResponse = try? JSONDecoder().decode(AuthResponse.self, from: result.data)
                        let errorMessage = errorResponse?.errorMessage ?? NSLocalizedString("Unauthorized access.", comment: "")
                        throw BackendError.unauthorized(message: errorMessage)
                    case 404:
                        let errorResponse = try? JSONDecoder().decode(AuthResponse.self, from: result.data)
                        let errorMessage = errorResponse?.errorMessage ?? NSLocalizedString("Resource not found.", comment: "")
                        throw BackendError.notFound(message: errorMessage)
                    case 409:
                        let errorResponse = try? JSONDecoder().decode(AuthResponse.self, from: result.data)
                        let errorMessage = errorResponse?.errorMessage ?? NSLocalizedString("Resource conflict", comment: "")
                        throw BackendError.notFound(message: errorMessage)
                    case 500:
                        let errorResponse = try? JSONDecoder().decode(AuthResponse.self, from: result.data)
                        let errorMessage = errorResponse?.errorMessage ?? NSLocalizedString("Internal server error.", comment: "")
                        throw BackendError.internalServerError(message: errorMessage)
                    default:
                        let errorResponse = try? JSONDecoder().decode(AuthResponse.self, from: result.data)
                        let errorMessage = errorResponse?.errorMessage ?? NSLocalizedString("Unknown Error", comment: "")
                        throw BackendError.serverError(message: errorMessage)
                }
            }
            .decode(type: RestAPIResponse.self, decoder: JSONDecoder())
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
    case internalServerError(message: String)
    case serverError(message: String)
    case decodingError(message: String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
            case .unauthorized(let message),
                    .notFound(let message),
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
