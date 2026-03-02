//
//  AdventureTubeData.swift
//  AdventureTube
//
//  Created by chris Lee on 11/5/22.
//

import Foundation
import CoreLocation

// MARK: - GeoDataResponse (API envelope for /web/geo/data)
struct GeoDataResponse: Codable {
    let success: Bool
    let message: String?
    let data: [AdventureTubeData]
}

// MARK: - AdventureTubeData
struct AdventureTubeData :Codable {
    var id: String?  // MongoDB ObjectId from backend API
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
    var isPublished: Bool?
}



struct AdventureTubeChapter : Codable {
    
    var categories:[Category]
    var youtubeId :String?
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
    var coordinate :CLLocationCoordinate2D?
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

    enum CodingKeys : String , CodingKey{
        case location, coordinate, name, youtubeTime, contentCategory, placeID, plusCode, website
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        location = try container.decodeIfPresent(GeoJson.self, forKey: .location)
        coordinate = try container.decodeIfPresent(CLLocationCoordinate2D.self, forKey: .coordinate)
        name = try container.decode(String.self, forKey: .name)
        youtubeTime = try container.decode(Int.self, forKey: .youtubeTime)
        contentCategory = try container.decode([Category].self, forKey: .contentCategory)
        placeID = try container.decodeIfPresent(String.self, forKey: .placeID)
        plusCode = try container.decodeIfPresent(String.self, forKey: .plusCode)
        website = try container.decodeIfPresent(URL.self, forKey: .website)
    }

    init(location: GeoJson? = nil, coordinate: CLLocationCoordinate2D? = nil, name: String, youtubeTime: Int, contentCategory: [Category], placeID: String? = nil, plusCode: String? = nil, website: URL? = nil) {
        self.location = location
        self.coordinate = coordinate
        self.name = name
        self.youtubeTime = youtubeTime
        self.contentCategory = contentCategory
        self.placeID = placeID
        self.plusCode = plusCode
        self.website = website
    }
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

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Duration(rawValue: rawValue) ?? .unknown
    }

    static func build(rawValue: String ) -> Duration {
        return Duration(rawValue: rawValue) ?? .unknown
    }
}

enum ContentType: String ,CaseIterable ,Identifiable , Codable{
    // use this for Bining<String>
    //    var id : RawValue{rawValue}
    var id: Self {self}
    case select , single ,couple ,family ,friends ,multiGroup ,unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = ContentType(rawValue: rawValue) ?? .unknown
    }

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

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Category(rawValue: rawValue) ?? .unknown
    }
    var key: String {
      return rawValue

//    var key: String {
//        switch self{
//        case .camping :
//            return "camping"
//        case .hiking :
//            return "hiking"
//        case .campfire :
//            return "campfire"
//        case .geocaching :
//            return "geocaching"
//        case .cooking :
//            return "cooking"
//        case .caravan :
//            return "caravan"
//        case .bbq :
//            return "bbq"
//        case .lookout :
//            return "lookout"
//        case .driving :
//            return "driving"
//        case .navigation :
//            return "navigation"
//
//
//        case .swimming :
//            return "swimming"
//        case .mtb :
//            return "mtb"
//        case .marine :
//            return "marine"
//        case .fishing :
//            return "fishing"
//        case .dirtbike :
//            return "dirtbike"
//        case .surf :
//            return "surf"
//        case .scubadiving :
//            return "scubadiving"
//        case .kayak :
//            return "kayak"
//
//        case .party :
//            return "party"
//        case .beer :
//            return "beer"
//        case .music :
//            return "music"
//            
//        case .unknown :
//             return "unknown"
//
////        default :
////            return "unknown"
//
//        }
    }
    //https://stackoverflow.com/questions/35119647/overriding-enum-initrawvalue-string-to-not-be-optional 3rd solution
    static func build(rawValue: String ) -> Category {
        return Category(rawValue: rawValue) ?? .unknown
    }
    
}
