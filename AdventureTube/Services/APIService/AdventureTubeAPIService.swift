//
//  AdventureTubeAPIService.swift
//  AdventureTube
//
//  Created by chris Lee on 29/11/2023.
//https://medium.com/@hemalasanka/making-api-calls-with-ios-combines-future-publisher-7a5011f81c2

import Foundation
import UIKit
import Combine

class AdventureTubeAPIService : NSObject {
    //This is SingleTon Parttern
    static let shared = AdventureTubeAPIService()
    
    private var cancellables = Set<AnyCancellable>() // (3)
    
    func getData<T: Decodable>(endpoint: String, id: Int? = nil, type: T.Type) -> Future<T, Error> {
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
