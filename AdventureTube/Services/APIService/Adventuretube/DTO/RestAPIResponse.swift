//
//  RestAPIResponse.swift
//  AdventureTube
//
//  Created by chris Lee on 4/7/2024.
//

import Foundation
struct RestAPIResponse: Codable {
    let message: String?
    let details: String?
    let statusCode: Int
    let timestamp: Int
}
