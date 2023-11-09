//
//  AdventureTubeData.swift
//  AdventureTube
//
//  Created by chris Lee on 11/5/22.
//

import Foundation
import CoreLocation

// MARK: - AdventureTubeData
struct AdventureTubeData :Codable {
    var coreDataID : String
    var youtubeContentID : String
    var youtubeTitle: String
    var youtubeDescription : String?
    
    var userContentCategory : [Category]
    var userTripDuration :Duration
    var userContentType : ContentType
    //made custom extention of CLLocationCoordinate2D
    //for Codable already
    var places : [AdventureTubePlace]
    var chapters : [AdventureTubeChapter]
    //optional
    var gpsData : Data?
    var geoCaches: Int?
    var isPublished = false
//    
//    enum CodingKeys : String , CodingKey{
//        case coreDataID, youtubeContentID,youtubeTitle,youtubeDescription,userContentCategory,userTripDuration,
//             userContentType, chapters ,gpsData,geoCaches, places
//    }
}



struct AdventureTubeChapter : Codable {
    
    var categories:[Category]
    var youtubeId :String
    var youtubeTime : Int
    var place : AdventureTubePlace
//    enum CodingKeys : String , CodingKey {
//        case categories,youtubeId,youtubeTime, place
//    }
}


//now its became a Hashable and  Equatable  only base the  place name
struct AdventureTubePlace : Codable , Hashable{
    
    //for Equatable
    static func == (lhs: AdventureTubePlace, rhs: AdventureTubePlace) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    

    var location :GeoJson?
    var coordinate :CLLocationCoordinate2D
    var name : String
    var youtubeTime : Int
    var contentCategory : [Category]
    var placeID: String?
    var plusCode : String?
    var website : URL?
    
    //for Hashable only based on  place name
    func hash(into hasher: inout Hasher) {
       hasher.combine(name)
     }
    
//    enum CodingKeys : String , CodingKey{
//        case coordinate, name , index , youtubeTime,contentCategory, placeID , plusCode , website
//    }
}

//lonitude , latitude
struct GeoJson: Codable{
    var type = "Point"
    var coordinates:[Double]
}



enum Duration: String , CaseIterable , Identifiable , Codable {
    // use this for Bining<String>
    //    var id : RawValue{rawValue}
    
    //use  Self for Bining<Self.Type>
    var id: Self {self}
    case select ,singleday ,multipleday , overweek, multipleweeks , lessthanmonth , overmonth , unknown
    
    static func build(rawValue: String ) -> Duration {
        return Duration(rawValue: rawValue) ?? .unknown
    }
}

enum ContentType: String ,CaseIterable ,Identifiable , Codable{
    // use this for Bining<String>
    //    var id : RawValue{rawValue}
    var id: Self {self}
    case select , single ,couple ,family ,friends ,multiGroup ,unknown
    
    static func build(rawValue: String ) -> ContentType {
        return ContentType(rawValue: rawValue) ?? .unknown
    }
}


enum Category : String ,CaseIterable ,Identifiable  , Codable{
    var id: RawValue { rawValue }

    case camping,caravan,hiking,campfire,geocaching,cooking,bbq,lookout,driving,navigation,
         swimming,mtb,marine,fishing,dirtbike,surf,scubadiving,kayak,
         party,beer,music,
         
         unknown
    
    var key: String {
        switch self{
        case .camping :
            return "camping"
        case .hiking :
            return "hiking"
        case .campfire :
            return "campfire"
        case .geocaching :
            return "geocaching"
        case .cooking :
            return "cooking"
        case .caravan :
            return "caravan"
        case .bbq :
            return "bbq"
        case .lookout :
            return "lookout"
        case .driving :
            return "driving"
        case .navigation :
            return "navigation"


        case .swimming :
            return "swimming"
        case .mtb :
            return "mtb"
        case .marine :
            return "marine"
        case .fishing :
            return "fishing"
        case .dirtbike :
            return "dirtbike"
        case .surf :
            return "surf"
        case .scubadiving :
            return "scubadiving"
        case .kayak :
            return "kayak"

        case .party :
            return "party"
        case .beer :
            return "beer"
        case .music :
            return "music"
            
        case .unknown :
             return "unknown"

//        default :
//            return "unknown"

        }
    }
    //https://stackoverflow.com/questions/35119647/overriding-enum-initrawvalue-string-to-not-be-optional 3rd solution
    static func build(rawValue: String ) -> Category {
        return Category(rawValue: rawValue) ?? .unknown
    }
    
}
