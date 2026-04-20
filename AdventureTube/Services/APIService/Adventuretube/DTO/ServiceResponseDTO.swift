//
//  ServiceResponseDTO.swift
//  AdventureTube
//
//  Created by chris Lee on 18/4/2026.
//

import Foundation
struct ServiceResponse<T: Decodable>: Decodable {
    let success: Bool
    let message: String?
    let errorCode: String?
    let data: T?
    let timestamp: String?
}
