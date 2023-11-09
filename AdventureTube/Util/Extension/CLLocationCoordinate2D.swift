//
//  CLLocationCoordinate2D.swift
//  AdventureTube
//
//  Created by chris Lee on 9/5/22.
//

import Foundation
import CoreLocation

extension CLLocationCoordinate2D : Codable {
    public init(from decoder: Decoder) throws {
        var arrayContainer = try decoder.unkeyedContainer()
        if arrayContainer.count == 2 {
            let lat = try arrayContainer.decode(CLLocationDegrees.self)
            let lng = try arrayContainer.decode(CLLocationDegrees.self)
            self.init(latitude: lat, longitude: lng)
        } else {
            throw DecodingError.dataCorruptedError(in: arrayContainer, debugDescription: "Coordinate array must contain two items")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var arrayContainer = encoder.unkeyedContainer()
        try arrayContainer.encode(contentsOf: [latitude, longitude])
    }
}
