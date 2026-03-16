//
//  AddStoryViewModel.swift
//  AdventureTube
//
//  Created by chris Lee on 29/3/22.
//

import Foundation
import Combine
import CoreData
import SwiftUI
import GoogleMaps
import GooglePlaces

enum SaveError : Error {
    case needActivityType
    case needTriopDuration
    case needVideoType
    case needLocationData
    case needMatchLocationWithTime(location:String)
}

extension SaveError:LocalizedError{
    var errorDescription: String?{
        switch self {
        case .needActivityType :
            return NSLocalizedString(
                "Plase choose at least one  or muitlple activity for all story chaptor you will create   ", comment: "")
        case .needTriopDuration :
            return NSLocalizedString(
                "Plase choose  duration of your trip for story", comment: "")
        case .needVideoType :
            return NSLocalizedString(
                "Plase choose  type of video for story", comment: "")
        case .needLocationData :
            return NSLocalizedString(
                "Plase choose  at least one location for story ", comment: "")
        case .needMatchLocationWithTime(let placeName) :
            return NSLocalizedString("Plase create chapter for  \" \(placeName) \"  at specific time on youtube", comment: "")
        }
    }
}
enum PublishingStatus {
    case idle
    case uploading
    case streaming
    case pollingFallback
    case completed(chaptersCount: Int, placesCount: Int)
    case deleted
    case duplicate
    case failed(message: String)
}

class AddStoryViewVM : ObservableObject {
    @Published var adventureTubeData : AdventureTubeData?
    let youtubeContentItem       : YoutubeContentItem

    @Published  var actionSheet : AddStoryViewActiveSheet?

    // MARK: - Publishing Status
    @Published var publishingStatus: PublishingStatus = .idle
    @Published var isPublishing: Bool = false
    @Published var isStoryPublished: Bool = false

    //These are all data to store in core data
    @Published var categorySelection : [Category] = []
    @Published var durationSelection : Duration = .select {
        didSet{
            createChapterViewVM.durationSelection = durationSelection
            if let storyEntity = storyEntity{
                storyEntity.userTripDuration = durationSelection.rawValue
                manager.save()
            }
        }
    }
    @Published var videoTypeSelection : ContentType = .select {
        didSet{
            createChapterViewVM.videoTypeSelection = videoTypeSelection
            if let storyEntity = storyEntity{
                storyEntity.userContentType = videoTypeSelection.rawValue
                manager.save()
            }

        }
    }
    //This will updated along with confimedPlace in AddStoryMapViewViewModel by subscriber
    //this chapter need to be sorted by time
    @OrderedChapterArrayPublished var chapters : [AdventureTubeChapter]
    //    @Published var orderedChapters:[Chapter] = []

    @Published var places : [GoogleMapAPIPlace] = []



    var stories : [StoryEntity] = []

    @Published var isShowErrorMessage = false
    @Published var errorMessage = ""

    @Published var savedEntities : [StoryEntity] = []
    @Published var hasChapter = false
    //This crearteChapterViewVM
    //1) will be filled up confirmedPlace & confimedMarker & processState
    //2) confimedPlace wil be subscribed to update AddStory
    let createChapterViewVM : CreateChapterViewVM
    var cancellables = Set<AnyCancellable>()
    let manager = CoreDataManager.instance
    var storyEntity: StoryEntity?


    init(youtubeContentItem : YoutubeContentItem , adventureTubeData : AdventureTubeData?){
        self.youtubeContentItem = youtubeContentItem
        self.adventureTubeData = adventureTubeData
        self.createChapterViewVM = CreateChapterViewVM(youtubeContentItem: youtubeContentItem)



        /// checkComposedStory will convert adventureTubeData to
        /// all kind of datatyoe for
        /// category , duration , video type and location
        /// and also setup all confirmedPlace in createChapterViewVM
        checkStoryAndSetValues()
        //listening update of Chapters from createChapterViewVM
        subscribeChapterFromCreateChapterViewVM()
        storyHasChapter()
        initStoryEntity()

    }
    /*
     This will fill up the all the data for

     AddStoryViewVM
     CreateChaptorViewVM
     */
    private func  checkStoryAndSetValues(){
        if let adventureTubeData = adventureTubeData {
            //set the all  published Data
            let tempCategorySelection :[Category] = adventureTubeData.userContentCategory
            categorySelection = tempCategorySelection
            durationSelection = adventureTubeData.userTripDuration
            videoTypeSelection = adventureTubeData.userContentType
            //save chapter for both ViewVM
            chapters = adventureTubeData.chapters
            //This is really important to syn data display between AddStoryView with CreateNewChapterView
            createChapterViewVM.chapters = adventureTubeData.chapters

            // defalut first selected marker : GMSMarker
            if let adventureTubeLocation = chapters.first?.place,
               let coord = adventureTubeLocation.coordinate {

                let marker =  GMSMarker(position: coord)

                marker.title = adventureTubeLocation.name
                marker.icon =  UIImage(systemName: "1.circle.fill")?
                    .resize(maxWidthHeight: 35)?
                    .maskWithColor(color: .red)
                createChapterViewVM.selectedMarker = marker
            }

            //confimed marker: GMSMarker
            createChapterViewVM.markers =  chapters.enumerated().compactMap{ (index ,chapter) -> GMSMarker? in
                guard let coord = chapter.place.coordinate else { return nil }
                let marker =  GMSMarker(position: coord)
                marker.title = chapter.place.name
                marker.icon = UIImage(systemName: "\(index+1).circle.fill")?
                    .resize(maxWidthHeight: 35)?
                    .maskWithColor(color: .red)
                return marker
            }




            //selected Marker
            //createChapterViewVM.processStatus = .finish

        }
    }

    func storyHasChapter(){
        if chapters.count > 0 {
            hasChapter = true
        }
    }
    //Syncronize chapters between AddStoryViewVM with CreateChapterViewVM
    //listening chapter in CreateChapterViewVM  => chapter will be editted
    //any change will applies to chapter in AddStoryViewVM => chapter will be displayed
    private func subscribeChapterFromCreateChapterViewVM(){
        createChapterViewVM.$chapters
            .sink {[weak self] chapters in
                guard let self = self else{return}
                print("createChapterViewVM.$chapters  has been changed")
                //Synch chapter
                self.chapters = chapters
                //update status
                DispatchQueue.main.async {
                    self.storyHasChapter()
                }
            }
            .store(in: &cancellables)
    }

    //Content Category need 2 dimention Package
    func getCategoryList() -> [[ContentCategory]]{
        let retrunCartegoryArray :[[ContentCategory]] =

        [[.tent , .caravan , .campfire ,.cooking , .hiking ,.mountainbike ],//campimng activity
         [.scuberdive ,.fishing , .canue , .kayak , .yart , .sulf] , //water acticity
         [.mountainbike , .horseriding , .biketour ,.dirtbike , .climing , .ski],
         [.reading , .restaurant, .dog , .music  , .motorbiketour ,.filming]]
        return retrunCartegoryArray
    }
}
