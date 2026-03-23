//
//  AuthTokenData.swift
//  AdventureTube
//
//  Created by chris Lee on 23/3/2026.
//

import Foundation

struct  AuthTokenData : Decodable {
    let userId: UUID?
    let accessToken : String?
    let refreshToken : String?
}
