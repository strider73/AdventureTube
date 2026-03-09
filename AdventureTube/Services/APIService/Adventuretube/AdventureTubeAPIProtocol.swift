//
//  AdventureTubeAPIProtocol.swift
//  AdventureTube
//
//  Created by chris Lee on 2/7/2024.
//

import Foundation
import Combine

protocol AdventureTubeAPIProtocol:AnyObject{
    
    
    func registerUser (adventureUser: UserModel) -> AnyPublisher<AuthResponse, Error>
    func loginWithPassword(adventureUser:UserModel) ->AnyPublisher<AuthResponse,Error>
    func refreshToken(adventureUser:UserModel) ->AnyPublisher<AuthResponse,Error>
    func signOut() -> AnyPublisher<RestAPIResponse, Error>
    
    func getData<T: Decodable>(endpoint: String, id: Int?, returnData: T.Type) -> Future<T, Error>
    func syncStory(_ story: StoryEntity) -> AnyPublisher<StoryResponse, Error>
    func updateStory(_ story: StoryEntity) -> AnyPublisher<StoryResponse, Error>
    func syncMoments(_ moments: [PlaceEntity], toStory storyId: String) -> AnyPublisher<MomentSyncResponse, Error>
    func fetchUserStories() -> AnyPublisher<[StoryDTO], Error>
    func deleteStory(_ storyId: String) -> AnyPublisher<RestAPIResponse, Error>
    func fetchGeoData() -> AnyPublisher<[AdventureTubeData], Error>

    // MARK: - Async Publish with SSE Job Tracking
    func publishGeoData(_ jsonData: Data) -> AnyPublisher<ServiceResponse<JobStatusDTO>, Error>
    func streamJobStatus(trackingId: String) -> AnyPublisher<JobStatusDTO, Error>
    func pollJobStatus(trackingId: String) -> AnyPublisher<ServiceResponse<JobStatusDTO>, Error>
    func deleteGeoData(youtubeContentId: String) -> AnyPublisher<Bool, Error>
}
