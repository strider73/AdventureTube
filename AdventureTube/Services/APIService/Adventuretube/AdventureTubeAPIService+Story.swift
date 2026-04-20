//
//  AdventureTubeAPIService+Story.swift
//  AdventureTube
//
//  User's story CRUD: publish, delete, sync, update
//

import Foundation
import Combine

extension AdventureTubeAPIService {

    // MARK: - Story Publish & Delete (via /auth/geo/* — Kafka + SSE flow)

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

            //TODO: need to check the screenshot job status first before delete process
            
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

    // MARK: - Job Status (SSE + Polling)

    /// Open an SSE stream for real-time job status updates
    /// Endpoint: GET /auth/geo/status/stream/{trackingId}
    func streamJobStatus(trackingId: String) -> AnyPublisher<JobStatusDTO, Error> {
        guard let url = URL(string: "\(targetServerAddress)/auth/geo/status/stream/\(trackingId)") else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }

        guard let accessToken = LoginManager.shared.userData.adventuretubeAcessJWTToken else {
            return Fail(error: BackendError.unauthorized(message: "No access token available")).eraseToAnyPublisher()
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
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }

        guard let accessToken = LoginManager.shared.userData.adventuretubeAcessJWTToken else {
            return Fail(error: BackendError.unauthorized(message: "No access token available")).eraseToAnyPublisher()
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
