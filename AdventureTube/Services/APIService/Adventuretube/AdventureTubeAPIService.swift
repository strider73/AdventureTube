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

class AdventureTubeAPIService : NSObject , AdventureTubeAPIProtocol {
    
    
    //This is SingleTon Parttern
    static let shared = AdventureTubeAPIService()
    private var cancellables = Set<AnyCancellable>() // (3)
    //private  var targetServerAddress: String = "http://192.168.1.105:8030"
    private  var targetServerAddress: String = "https://api.travel-tube.com"
    
    // URLSession with timeout configuration
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 600 // 30 seconds for request timeout
        configuration.timeoutIntervalForResource = 600 // 60 seconds for resource timeout
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
                throw BackendError.notFound(message: errorMessage)
            case 500:
                let errorMessage = decodeError( result.data, to: AuthResponse.self, defaultMessage: NSLocalizedString("Internal server error.", comment: ""))
                throw BackendError.internalServerError(message: errorMessage)
            default:
                let errorMessage = decodeError( result.data, to: AuthResponse.self, defaultMessage: NSLocalizedString("Unknown error.", comment: ""))
                throw BackendError.serverError(message: errorMessage)
            }
    }
    
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
    
    // MARK: - Story/Moments Sync Methods
    
    /// Sync a complete story with all chapters and moments to backend
    /// - Parameter story: StoryEntity from CoreData
    /// - Returns: Publisher with StoryResponse or Error
    func syncStory(_ story: StoryEntity) -> AnyPublisher<StoryResponse, Error> {
        guard let url = URL(string: "\(targetServerAddress)/api/stories") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        guard let accessToken = LoginManager.shared.userData.adventuretubeJWTToken else {
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
    
    /// Update an existing story on the backend
    /// - Parameter story: StoryEntity from CoreData
    /// - Returns: Publisher with StoryResponse or Error
    func updateStory(_ story: StoryEntity) -> AnyPublisher<StoryResponse, Error> {
        guard let url = URL(string: "\(targetServerAddress)/api/stories/\(story.id)") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        guard let accessToken = LoginManager.shared.userData.adventuretubeJWTToken else {
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
    
    /// Sync individual moments (places) to a specific story
    /// - Parameters:
    ///   - moments: Array of PlaceEntity objects
    ///   - storyId: The story ID these moments belong to
    /// - Returns: Publisher with MomentSyncResponse or Error
    func syncMoments(_ moments: [PlaceEntity], toStory storyId: String) -> AnyPublisher<MomentSyncResponse, Error> {
        guard let url = URL(string: "\(targetServerAddress)/api/stories/\(storyId)/moments") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        guard let accessToken = LoginManager.shared.userData.adventuretubeJWTToken else {
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
    /// - Returns: Publisher with array of StoryDTO or Error
    func fetchUserStories() -> AnyPublisher<[StoryDTO], Error> {
        guard let url = URL(string: "\(targetServerAddress)/api/stories") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        guard let accessToken = LoginManager.shared.userData.adventuretubeJWTToken else {
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
    
    /// Fetch public geo data (adventure stories with locations) from backend
    /// - Returns: Publisher with array of AdventureTubeData or Error
    func fetchGeoData() -> AnyPublisher<[AdventureTubeData], Error> {
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

    /// Delete a story from the backend
    /// - Parameter storyId: The ID of the story to delete
    /// - Returns: Publisher with RestAPIResponse or Error
    func deleteStory(_ storyId: String) -> AnyPublisher<RestAPIResponse, Error> {
        guard let url = URL(string: "\(targetServerAddress)/api/stories/\(storyId)") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        guard let accessToken = LoginManager.shared.userData.adventuretubeJWTToken else {
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
