//
//  JobStatusDTO.swift
//  AdventureTube
//
//  Created by chris Lee on 9/3/2026.
//

import Foundation

struct ServiceResponse<T: Decodable>: Decodable {
    let success: Bool
    let message: String?
    let errorCode: String?
    let data: T?
    let timestamp: String?
}

struct JobStatusDTO: Decodable {
    let trackingId: String
    let youtubeContentID: String
    let status: JobStatusType
    let errorMessage: String?
    let chaptersCount: Int
    let placesCount: Int
}

enum JobStatusType: String, Decodable {
    case PENDING, COMPLETED, DUPLICATE, FAILED
    var isTerminal: Bool { self != .PENDING }
}
