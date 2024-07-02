//
//  AdventureTubeAPIService.swift
//  AdventureTube
//
//  Created by chris Lee on 29/11/2023.
//https://medium.com/@hemalasanka/making-api-calls-with-ios-combines-future-publisher-7a5011f81c2

import Foundation
import UIKit
import Combine

class AdventureTubeAPIService : NSObject , AdventureTubeAPIPrototol {

    
    //This is SingleTon Parttern
    static let shared = AdventureTubeAPIService()
    private var cancellables = Set<AnyCancellable>() // (3)
    private var accessToken : String?
    private var refreshToken : String?
    func getData<T: Decodable>(endpoint: String, id: Int? = nil, returnData: T.Type) -> Future<T, Error> {
        return Future<T, Error> { [weak self] promise in  // (4) -> Future Publisher
            guard let self = self, let url = URL(string: endpoint) else {
                return promise(.failure(NetworkError.invalidURL))
            }
            print("URL is \(url.absoluteString)")
            URLSession.shared.dataTaskPublisher(for: url) // (5) -> Publisher
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
    
    func signIn(adventureUser: UserModel) -> AnyPublisher<AuthResponse, Error> {
        guard let url = URL(string: "http://192.168.1.106:8030/auth/register") else {
            fatalError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Safely unwrap optional properties
           guard let idToken = adventureUser.idToken,
                 let fullName = adventureUser.fullName,
                 let emailAddress = adventureUser.emailAddress,
                 let password = adventureUser.userId
            else {
               fatalError("Missing user information")
           }
        let body: [String: Any] = [
                "googleIdToken": idToken,
                "username": fullName,
                "email": emailAddress,
                "role": "USER",
                "password": "1111111"
            ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        print("googleIdToken : \(idToken)")
        return URLSession.shared.dataTaskPublisher(for: request)
                .tryMap { result -> Data in
                    guard let httpResponse = result.response as? HTTPURLResponse else {
                        throw BackendError.unknownError
                    }

                    if (200...299).contains(httpResponse.statusCode) {
                        return result.data
                    } else {
                        let errorResponse = try? JSONDecoder().decode(AuthResponse.self, from: result.data)
                        let errorMessage = errorResponse?.errorMessage ?? "Unknown server error"
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
                .handleEvents(receiveOutput: { [weak self] authResponse in
                           self?.accessToken = authResponse.accessToken
                           self?.refreshToken = authResponse.refreshToken
                 })
                .eraseToAnyPublisher()
    }
    
    func signOut() -> AnyPublisher<RestAPIResponse, Error> {
        guard let url = URL(string: "http://192.168.1.106:8030/auth/logout") else {
            fatalError("Invalid URL")
        }
        
        guard let refreshToken = refreshToken else {
               return Fail(error: NetworkError.invalidURL)
                   .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(refreshToken, forHTTPHeaderField: "Authorization")
        print("Sending signOut request to \(url.absoluteString) with refreshToken: \(refreshToken)")

        return URLSession.shared.dataTaskPublisher(for: request)
                .tryMap { result -> Data in
                    guard let httpResponse = result.response as? HTTPURLResponse else {
                        throw BackendError.unknownError
                    }

                    if (200...299).contains(httpResponse.statusCode) {
                        return result.data
                    } else {
                        let errorResponse = try? JSONDecoder().decode(AuthResponse.self, from: result.data)
                        let errorMessage = errorResponse?.errorMessage ?? "Unknown server error"
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

enum NetworkError : Error {
    case invalidURL
    case responseError
    case unknown
}

// Define the response model
struct AuthResponse: Codable {
    let userDetails: MemberDTO?
    let accessToken: String?
    let refreshToken: String?
    let errorMessage: String?

}

struct RestAPIResponse: Codable {
    let message: String?
    let details: String?
    let statusCode: Int
    let timestamp: Int
}
struct MemberDTO: Codable {
    let id: Int?
    let email: String?
    let password: String?
    let username: String?
    let googleIdToken: String?
    let googleIdTokenExp: Int?
    let googleIdTokenIat: Int?
    let googleIdTokenSub: String?
    let googleProfilePicture: String?
    let channelId: String?
    let role: String?
}

enum BackendError: LocalizedError {
    case serverError(message: String)
    case decodingError(message: String)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .serverError(let message):
            return message
        case .decodingError(let message):
            return message
        case .unknownError:
            return "An unknown error occurred"
        }
    }
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
