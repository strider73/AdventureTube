//
//  AdventureTubeAPIService+Map.swift
//  AdventureTube
//
//  Map data endpoints: fetch stories for map display, bounding box queries,
//  SSE streaming, and job status polling
//

import Foundation
import Combine

extension AdventureTubeAPIService {

    // MARK: - Map Data Queries (public, no auth)

    /// Fetch public geo data within a bounding box — no authentication required
    /// Endpoint: GET /web/geo/data/bounds?swLat=&swLng=&neLat=&neLng=
    func fetchStoryInBounds(swLat: Double, swLng: Double, neLat: Double, neLng: Double) -> AnyPublisher<[AdventureTubeData], Error> {
        guard let url = URL(string: "\(targetServerAddress)/web/geo/data/bounds?swLat=\(swLat)&swLng=\(swLng)&neLat=\(neLat)&neLng=\(neLng)") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        print("Fetching geo data in bounds from \(url.absoluteString)")

        return self.session.dataTaskPublisher(for: request)
            .tryMap { (data, response) -> GeoDataResponse in
                guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                    throw NetworkError.responseError
                }
                return try JSONDecoder().decode(GeoDataResponse.self, from: data)
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

    /// Fetch all public geo data — no authentication required
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

}
