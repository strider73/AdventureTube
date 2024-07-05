//
//  PreviewProvider.swift
//  AdventureTube
//
//  Created by chris Lee on 30/12/21.
//

import Foundation
import SwiftUI
import GoogleSignIn
import CoreLocation

extension PreviewProvider{
    static var dev: DeveloperPreview{
        return DeveloperPreview.instance
    }
}


class DeveloperPreview{
    //This is Key To change the Login State in Preview
    var userLogin : Bool = true
    
    static let instance = DeveloperPreview()
    let loginManager = LoginManager.shared
    
    var youtubeContentResource : YoutubeContentResource
    var youtubeContentItems : [YoutubeContentItem] = []
    let myStoryVM : MyStoryListViewVM
    let addStoryViewVM : AddStoryViewVM
    let customTabBarVM : CustomTabBarViewVM
    let myStoryCommonDetailViewVM : MyStoryCommonDetailViewVM
    
    init() {
        //setup login Data for Login process test
        if userLogin{
            loginManager.userData =  UserModel(signed_in: true,
                                               emailAddress: "test@gmail.com",
                                               fullName: "Test Lee",
                                               givenName: "Test",
                                               familyName: "Lee",
                                               profilePicUrl: "https://lh3.googleusercontent.com/a-/AFdZucomQYbiADF3x-oBZj0yYyvijMhDsrtdpZQozVqf5Q=s135")
            loginManager.loginState = .signedIn
            
            
        }else{
            loginManager.userData =  UserModel(signed_in: false,
                                               emailAddress: nil,
                                               fullName: nil,
                                               givenName: nil,
                                               familyName: nil,
                                               profilePicUrl: nil)
            loginManager.loginState = .signedOut
        }
        
        //setup json data for uiTest
    
        self.youtubeContentResource = ReadJsonData().youtubeContentResource
        
        
        //setup the data that can be called from core dataz
        //and setup AdventureTubeData for "Sharps Camping Area" which is first and third story
        
        let tentCategory  = Category.build(rawValue: "tent")
        let hikingCategory =  Category.build(rawValue: "hiking")
        let campFireCategory = Category.build(rawValue: "campFire")
        let fishingCategory = Category.build(rawValue: "fishing")
        let climingCategory = Category.build(rawValue: "climing")
    
        let sharCampArea  = AdventureTubePlace(coordinate: CLLocationCoordinate2D(latitude: -38.5515209, longitude: 143.932041),
                                                name: "Sharps Camping Area",
                                               youtubeTime: 0,
                                               contentCategory: [tentCategory,hikingCategory,campFireCategory],
                                             placeID: "ChIJ8xekrJhl02oRwOANtAQuVHU",
                                            plusCode: "4RH5CWXJ+9R")
        
        let hendersonFalls = AdventureTubePlace(coordinate: CLLocationCoordinate2D(latitude: -38.5485328, longitude: 143.933701),
                                                name: "Henderson Falls",
                                          youtubeTime: 0,
                                          contentCategory: [fishingCategory],
                                             placeID: "ChIJgVQ5FaBl02oRLDsQrABsuHw",
                                            plusCode: "4RH5FW2M+HF")
        
        let wonWondahFalls =  AdventureTubePlace(coordinate: CLLocationCoordinate2D(latitude: -38.5500425, longitude: 143.938156),
                                                       name: "Won Wondah Falls",
                                                 youtubeTime: 0,
                                                 contentCategory: [hikingCategory],
                                                    placeID: "ChIJweDTS6dl02oR3avfiUdQ-oM",
                                                   plusCode: "4RH5CWXQ+X7")
       
        //setup location
        let adventureTubeLocations : [AdventureTubePlace] = [sharCampArea,hendersonFalls,wonWondahFalls]
        
        //setup Chapter
        let chapters :[AdventureTubeChapter] = [AdventureTubeChapter(categories: [Category.build(rawValue: "tent"),
                                                        Category.build(rawValue: "hiking"),
                                                        Category.build(rawValue:  "campfire")],
                                           youtubeId: "CCIS3-ohsJE", youtubeTime: 110,place: sharCampArea) ,
                                   AdventureTubeChapter(categories: [ Category.build(rawValue: "fishing")],
                                           youtubeId: "CCIS3-ohsJE", youtubeTime: 512,place: hendersonFalls) ,
                                   AdventureTubeChapter(categories: [Category.build(rawValue: "climing")],
                                                        youtubeId: "CCIS3-ohsJE", youtubeTime: 730,place: wonWondahFalls)]
        
        //setup AdventureTubeData
       let  mockAdventureTubeData = AdventureTubeData(coreDataID: "6A96A074-4779-436C-B52F-E1CD6691A76D",
                           youtubeContentID: "CCIS3-ohsJE",
                           youtubeTitle: "Sharps Camping Area   and Hiking at Sheoak Picnic area  4K",
                           youtubeDescription: "Sharps Camping Area   and Hiking at Sheoak Picnic area  4K",
                           userContentCategory: [tentCategory, hikingCategory, campFireCategory],
                           userTripDuration: Duration.multipleday,
                           userContentType: ContentType.family,
                           places: adventureTubeLocations,
                           chapters: chapters,
                           isPublished: true)

        //mapping to youtubeContentItems
        youtubeContentItems = youtubeContentResource.items.map{ youtubeContentItem -> YoutubeContentItem in
            var composedYoutubeContentItem = youtubeContentItem
            if composedYoutubeContentItem.contentDetails.videoId == mockAdventureTubeData.youtubeContentID {
                composedYoutubeContentItem.snippet.adventureTubeData = mockAdventureTubeData
            }
             return composedYoutubeContentItem
        }
       
         
        
        myStoryVM = MyStoryListViewVM()
        myStoryVM.youtubeContentItems = youtubeContentItems
        
        
        customTabBarVM = CustomTabBarViewVM.shared
        //        print("=============youtubeContent==============")
        //        print(youtubeContentResource)
        //        print("=============youtubeContentItem==============")
        //        print(youtubeContentItem)
        
        
        //setup addStoryViewVM
        let youtubeContentItem = youtubeContentItems.first!
        self.addStoryViewVM = AddStoryViewVM(youtubeContentItem: youtubeContentItem,adventureTubeData: mockAdventureTubeData)
        myStoryCommonDetailViewVM = MyStoryCommonDetailViewVM(youtubeContentItem: youtubeContentItem, adventureTubeData:myStoryVM.$adventureTubeData)

        addStoryViewVM.createChapterViewVM.processStatus = .searchLocation
        var selectedPlace = GoogleMapAPIPlace(name: "Test Place in Melton South")
        selectedPlace.youtubeTime = 356
        addStoryViewVM.createChapterViewVM.placeForChapter = selectedPlace
        //createChapterViewVM.tempCategory = [.bbq , .camping , .caravan , .cooking, .driving , .geocaching , .hiking]
        addStoryViewVM.createChapterViewVM.chapterCategory = [.camping ,.caravan, .cooking, .driving,.geocaching]

    }
    
    
    
}
