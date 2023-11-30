//
//  Restaurants.swift
//  AdventureTube
//
//  Created by chris Lee on 30/11/2023.
//


import Foundation

// MARK: - Restaurants
struct Restaurants: Codable {
    let id: String
    let location: Location
    let name: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case location, name
    }
}

// MARK: - Location
struct Location: Codable {
    let coordinates: [Double]
    let type: String
}

