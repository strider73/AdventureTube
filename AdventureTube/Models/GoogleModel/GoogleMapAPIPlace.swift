//
//  AdventureTubePlace.swift
//  AdventureTube
//
//  Created by chris Lee on 13/4/22.
//

import Foundation
import CoreLocation
import GooglePlaces


//This is model for search prediction list so data is came from GMSAutocompletePrediction
//struct  ATGooglePlace :  Identifiable , Equatable {
struct  GoogleMapAPIPlace :  Identifiable , Equatable {

    var id  = UUID().uuidString
    var name : String
    var fullName : NSAttributedString?
    var primaryName: NSAttributedString?
    var secondryName : NSAttributedString?
    var coordinate: CLLocationCoordinate2D?
    var contentCategories : [Category] = []
    var types :[String]?
    var placeId : String?
    var plusCode : String?
    var youtubeTime : Int = 0
    //GMSPlace's properties are not able to set so not able to create instance
    //var googlePlace : GMSPlace?
    
    static func == (lhs: GoogleMapAPIPlace, rhs: GoogleMapAPIPlace) -> Bool {
            return
                lhs.fullName == rhs.fullName &&
                lhs.placeId == rhs.placeId
        }
    
}
