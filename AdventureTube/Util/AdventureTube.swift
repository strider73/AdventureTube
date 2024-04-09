//
//  AdventureTubeColor.swift
//  AdventureTube
//
//  Created by chris Lee on 16/2/22.
//

import Foundation
import SwiftUI

enum APIService :String {
    
    case  rasberryTestServer , AWSRealServer
    
    var address : String {
        switch self {
            case .rasberryTestServer :
                return "https://mobile.adventuretube.net/api/v1"
               //   return  "https://192.168.1.100:8888/api/vi/adventuretubedata"
            case .AWSRealServer :
                return ""
        }
    }
}

enum ColorConstant : Hashable {
    case  background , foreground , videobackground
    
    var color : Color  {
        switch self {
        case .background:
            return Color.white
            //            return  Color(hex: "F5F3F1")
        case .foreground:
            return Color.black
        case .videobackground:
            return Color.gray
            
        }
    }
    
}



enum FolderConstant : Hashable {
    case file , image
    
    var name : String {
        switch self {
        case .image :
            return "Image"
        case .file :
            return "File"
        }
        
    }
    
}


//enum ContentDuration: String , CaseIterable , Identifiable {
//    // use this for Bining<String>
//    //    var id : RawValue{rawValue}
//    
//    //use  Self for Bining<Self.Type>
//    var id: Self {self}
//    case select ,singleday ,multipleday , overweek, multipleweeks , lessthanmonth , overmonth
//}
//
//enum ContentPeopleType: String ,CaseIterable ,Identifiable{
//    // use this for Bining<String>
//    //    var id : RawValue{rawValue}
//    var id: Self {self}
//    case select , single ,couple ,family ,friends ,multiGroup
//}
//
//
//enum Category : String ,CaseIterable ,Identifiable {
//    var id: RawValue { rawValue }
//
//    case camping,caravan,hiking,campfire,geocaching,cooking,bbq,lookout,driving,navigation,
//         swimming,mtb,marine,fishing,dirtbike,surf,scubadiving,kayak,
//         party,beer,music,
//    
//         unknown
//    
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
//        case .unknown  :
//             return "unknown"
//            
//        }
//    }
//}


enum ContentCategory : String , CaseIterable ,Identifiable{
    //rawValue is best value that can be identifiable for String
    var id: RawValue { rawValue }
    
    case hiking,canue,campfire,tent,caravan,cooking,
         kayak,dog,music,restaurant,horseriding,
         mountainbike,reading,scuberdive,yart,ski,sulf,
         biketour,
         fishing , dirtbike,filming ,motorbiketour,climing,
         cycling , unknown
    var key :String {
        switch self{
        case .hiking ://
            return "G"
        case .canue ://
            return "K"
        case .campfire ://
            return "U"
        case .tent ://
            return "l"
        case .caravan ://
            return "m"
        case .cooking ://
            return "q"
        case .kayak ://
            return "Z"
        case .dog ://
            return "c"
        case .music://
            return "R"
        case .restaurant://
            return "Y"
        case .horseriding://
            return "J"
        case .mountainbike://
            return "Q"
        case .reading://
            return "j"
        case .scuberdive://
            return "u"
        case .yart://
            return "2"
        case .ski://
            return "5"
        case .sulf://
            return "9"
        case .biketour://
            return "g"
        case .fishing ://
            return "x"
        case .dirtbike ://
            return "T"
        case .filming ://
            return "P"
        case .motorbiketour://
            return "h"
        case .climing :
            return "o"
        case .cycling :
            return "s"
        case .unknown :
            return "?"
        }
    }
}
