//
//  UserModel.swift
//  AdventureTube
//
//  Created by chris Lee on 20/12/21.
//

import Foundation
import SwiftUI


struct UserModel : Codable{
    //User Profile Data
    //    @AppStorage("signed_in")    var currentUserSignedIn : Bool = false
    //    @AppStorage("emailAddress") var emailAddress : String = ""
    //    @AppStorage("fullName")     var fullName : String = ""switch
    //    @AppStorage("givenName")    var givenName : String = ""
    //    @AppStorage("familyName")   var familyName : String = ""
    //    @AppStorage("profilePicUrl")var profilePicUrl : String = ""
    
    //about login user
    var signed_in : Bool = false
    var isYoutubeAccountReady : Bool = false
    var storedScopes: [String] = []{
        didSet {
            print("userData storedScopes changed to")
            storedScopes.forEach { scope in
                print( scope )
            }
        }
    }

    
    
    var emailAddress : String?
    var fullName     : String?
    var givenName    : String?
    var familyName   : String?
    var profilePicUrl : String?
    //for youtube
    var idToken : String?
    var googleUserId  : String?
    //for Adventuretube
    var adventureTube_id : UUID?
    var adventuretubeJWTToken: String? {
        didSet {
            print("adventuretubeJWTToken changed to: \(adventuretubeJWTToken ?? "nil")")
        }
    }
    var adventuretubeRefreshJWTToken: String? {
        didSet {
            print("adventuretubeRefreshJWTToken changed to: \(adventuretubeRefreshJWTToken ?? "nil")")
        }
    }
    var loginSource : LoginSource?
    
    enum UserKeys: String {
        case signed_in
        case emailAddress
        case fullName
        case givenName
        case familyName
        case profilePicUrl
        case loginSource
    }
}


//extension SettingModel : RawRepresentable {
//
//    public init?(rawValue: String) {
//        guard let data = rawValue.data(using: .utf8),
//              let result = try? JSONDecoder().decode(SettingModel.self, from: data)
//// for array like     @AppStorage("itemsInt") var itemsInt = [1, 2, 3]
////              let result = try? JSONDecoder().decode([Element].self, from: data)
//
//        else {
//            print("jsondecoder has been failed !!!")
//            return nil
//        }
//        self = result
//    }
//
//    public var rawValue: String {
//        guard let data = try? JSONEncoder().encode(self),
//              let result = String(data: data, encoding: .utf8)
//        else {
//            print("jsonencoder has been failed !!!")
//            return "[]"
//        }
//        return result
//    }
//}
