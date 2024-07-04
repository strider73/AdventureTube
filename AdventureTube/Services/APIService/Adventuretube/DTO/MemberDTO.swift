//
//  MemberDTO.swift
//  AdventureTube
//
//  Created by chris Lee on 4/7/2024.
//

import Foundation
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
