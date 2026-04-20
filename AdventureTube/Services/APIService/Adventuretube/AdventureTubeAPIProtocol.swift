//
//  AdventureTubeAPIProtocol.swift
//  AdventureTube
//
//  Created by chris Lee on 2/7/2024.
//

import Foundation
import Combine

protocol AdventureTubeAPIProtocol: AnyObject {

    // MARK: - Common
    func getData<T: Decodable>(endpoint: String, id: Int?, returnData: T.Type) -> Future<T, Error>

    // MARK: - Authentication (+Auth)
    func registerUser(adventureUser: UserModel) -> AnyPublisher<ServiceResponse<AuthTokenData>, Error>
    func loginWithGoogleIdToken(adventureUser: UserModel) -> AnyPublisher<ServiceResponse<AuthTokenData>, Error>
    func refreshToken(adventureUser: UserModel) -> AnyPublisher<ServiceResponse<AuthTokenData>, Error>
    func signOut() -> AnyPublisher<ServiceResponse<String>, Error>

    // MARK: - Map (+Map)
    func fetchStory() -> AnyPublisher<[AdventureTubeData], Error>
    func fetchStoryInBounds(swLat: Double, swLng: Double, neLat: Double, neLng: Double) -> AnyPublisher<[AdventureTubeData], Error>

    // MARK: - Story (+Story)
    func publishStory(_ jsonData: Data) -> AnyPublisher<ServiceResponse<JobStatusDTO>, Error>
    func deleteStory(youtubeContentId: String) -> AnyPublisher<ServiceResponse<JobStatusDTO>, Error>
    func streamJobStatus(trackingId: String) -> AnyPublisher<JobStatusDTO, Error>
    func pollJobStatus(trackingId: String) -> AnyPublisher<ServiceResponse<JobStatusDTO>, Error>
    func syncStory(_ story: StoryEntity) -> AnyPublisher<StoryResponse, Error>
    func updateStory(_ story: StoryEntity) -> AnyPublisher<StoryResponse, Error>
    func syncMoments(_ moments: [PlaceEntity], toStory storyId: String) -> AnyPublisher<MomentSyncResponse, Error>
    func fetchUserStories() -> AnyPublisher<[StoryDTO], Error>
    func deleteStory(_ storyId: String) -> AnyPublisher<ServiceResponse<String>, Error>
}
