//
//  AdventureTubeAPIProtocol.swift
//  AdventureTube
//
//  Created by chris Lee on 2/7/2024.
//

import Foundation
import Combine

protocol AdventureTubeAPIPrototol:AdventureTubeAPIService{
    func getData<T: Decodable>(endpoint: String, id: Int?, returnData: T.Type) -> Future<T, Error>
    func registerUser (adventureUser: UserModel) -> AnyPublisher<AuthResponse, Error>
    func loginWithPassword(adventureUser:UserModel) ->AnyPublisher<AuthResponse,Error>
    func refreshToken(adventureUser:UserModel) ->AnyPublisher<AuthResponse,Error>
    func signOut() -> AnyPublisher<RestAPIResponse, Error>

}
