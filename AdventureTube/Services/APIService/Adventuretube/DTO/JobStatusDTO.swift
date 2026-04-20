//
//  JobStatusDTO.swift
//  AdventureTube
//
//  Created by chris Lee on 9/3/2026.
//

import Foundation


struct JobStatusDTO: Decodable {
    let trackingId: String
    let youtubeContentID: String
    let status: JobStatusType
    let errorMessage: String?
    let chaptersCount: Int
    let placesCount: Int
}

enum JobStatusType: String, Decodable {
    case PENDING, COMPLETED,DUPLICATED, FAILED
    var isTerminal: Bool { self != .PENDING }
}


