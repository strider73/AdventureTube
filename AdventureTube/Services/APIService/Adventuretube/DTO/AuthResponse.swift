//
//  AuthResponse.swift
//  AdventureTube
//
//  Created by chris Lee on 4/7/2024.
//

import Foundation
struct AuthResponse: Codable {
    let userDetails: MemberDTO?
    let accessToken: String?
    let refreshToken: String?
    let errorMessage: String?

}
