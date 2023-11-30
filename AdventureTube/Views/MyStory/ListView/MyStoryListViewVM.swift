//
//  MyStoryViewModel.swift
//  AdventureTube
//
//  Created by chris Lee on 23/2/22.
//

import Foundation
import Combine
import SwiftUI
import CoreData
import CoreLocation

final class MyStoryListViewVM:ObservableObject{
    @Published  var youtubeContentItems : [YoutubeContentItem] = []
    @Published  var isShowRefreshAlert = false
    
    /*This property will  store any new data or update
     
     which meaning is this value is NOT set when downloadYotubeContentsAndMappedWithCoreData() called
     it will be only set when listenCoreDataSaveAndUpdate() is called !!!!
     which meaning that when it some of StoryEntity has been
             insert,update,  NOT deleted !!!!!
     
     and every
          MyStoryCellView (with condition of "if let adventureTubeData = myStoryCommonDetailVM.adventureTubeData" )
          StoryLoadingView
          StoryView
          AddStoryView
          PlayChapterView  => currently not used ß
     
     
     except
          CreateChapterView
          ConfirmChapterView
     
          
     */
    @Published  var adventureTubeData : AdventureTubeData?
    private let limitOfYoutubeContentItem = 100
    //This will be a stroy entity has been composed after user put additional information
    //    @Published  var story : StoryEntity?
    
    //These are the stories that has been dispatched from coredata
    private var coreDataStorage  = CoreDataStorage()
    private var context = CoreDataManager.instance.context
    var stories : [StoryEntity] = []
    private var cancellable : AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    let youtubeAPIService  = YoutubeAPIService()
    
 
    
    init(){
        print("init MainStoryListViewModel")
        listenCoreDataSaveAndUpdate()
    }
    
    // when the user change the channel id MyStoryListView  need to be delete exsiting story
    func deleteExistingYoutubeContent(){
        youtubeContentItems = []
    }
    
    /*    func getYoutubeContentById() -> YoutubeContentItem?{
     //
     //
     //        var searchedYoutubeContentItem : YoutubeContentItem?
     //
     //        youtubeContentItems.forEach { youtubeContentItem in
     //            if youtubeContentItem.id == selectedYoutubeContentItemId {
     //                searchedYoutubeContentItem = youtubeContentItem
     //            }
     //        }
     //        return searchedYoutubeContentItem ?? nil
     //    }
     */
    
    
    
    //Step1) get the Youtube Data
    func downloadYotubeContentsAndMappedWithCoreData(){
        
        youtubeAPIService.youtubeContentResourcePublisher {[weak self] publisher  in
            guard let self = self else {return}
            
            self.cancellable =  publisher.sink(receiveCompletion: {
                completion in
                switch completion{
                    case .finished:
                        print("===========youtubeAPIService.youtubeContentResourcePublisher has been finished ===============")
                        if self.youtubeAPIService.nextPageToken != nil && self.youtubeContentItems.count < self.limitOfYoutubeContentItem {
                            self.downloadYotubeContentsAndMappedWithCoreData()
                        }
                        break
                    case .failure(let error):
                        print("Error retrieving for Data \(error)")
                }
            }, receiveValue: {  youtubeContentResource in
                print("===========Value has been received ===============")
                print(youtubeContentResource)
                //set the pageToken
                
                
                //store pageToken
                if let nextPageToken = youtubeContentResource.nextPageToken{
                    print("set nextPageToken")
                    self.youtubeAPIService.nextPageToken = nextPageToken
                }else{
                    self.youtubeAPIService.nextPageToken = nil
                }
                if let prevPageToken = youtubeContentResource.prevPageToken{
                    print("set prevPageToken")
                    self.youtubeAPIService.prevPageToken = prevPageToken
                }else{
                    self.youtubeAPIService.prevPageToken = nil
                }
                
                
                //Step2) Mapping with CoreData
                let request = NSFetchRequest<StoryEntity>(entityName: "StoryEntity")
                
                //check the YoutubeContentResource.YoutubeContentItem.YoutubeContentDetails.videoId
                //with StoryEntity from CoreData
                //and create the AdventureTubeData if there is any  matches accordingly
                do{
                    let  coreDataStories = try self.context.fetch(request)
                    
                    /*
                     This process will !!!
                        1)check the youtubeContentItem inside YoutubeContentResource by
                           checking the youtubeId
                        2)if there any matches videoId  between StoryEntity with youtubeContentItem
                        3)Set the  AdventureTubeData and set this to youtubeContentItem
                     */
                    let tempYoutuebeContentItem = youtubeContentResource.items.map { youtubeContentItem -> YoutubeContentItem  in
                        
                        var tempYoutubeContentItem = youtubeContentItem
                        coreDataStories.forEach { storyEntity in
                            if(storyEntity.youtubeId == tempYoutubeContentItem.contentDetails.videoId){
                                
                                let newAdventureTubeData : AdventureTubeData
                                
                                var chapters : [AdventureTubeChapter] = []
                                var categroies : [Category] = []
                                var places : [AdventureTubePlace] = []
                                
                                storyEntity.chapters.forEach { chapter  in
                                    guard let chapterEntiry = chapter as? ChapterEntity else{ return }
                                    let placeEntity = chapterEntiry.place
                                    //1) set AdventureTubePlace
                                    let adventureTubePlace = AdventureTubePlace(coordinate: CLLocationCoordinate2D(latitude: placeEntity.latitude, longitude: placeEntity.longitude),
                                                                                name: placeEntity.name,
                                                                                youtubeTime: Int(placeEntity.youtubeTime),
                                                                                contentCategory: placeEntity.placeCategory.compactMap{Category(rawValue: $0)},
                                                                                placeID: placeEntity.placeID,
                                                                                plusCode: placeEntity.pluscode,
                                                                                website: placeEntity.website)
                                    //2) set a chapters
                                    let chapterCategories = chapterEntiry.category.compactMap{Category(rawValue: $0)}
                                    let chapter = AdventureTubeChapter(categories: chapterCategories,// category set for each chapter
                                                                       youtubeId: chapterEntiry.story.youtubeId,
                                                                       youtubeTime: Int(chapterEntiry.youtubeTime),
                                                                       place: adventureTubePlace)
                                    chapters.append(chapter)
                                    
                                    //3 set a places after remove duplicate
                                    places.append(adventureTubePlace)
                                    categroies.append(contentsOf: chapterCategories)
                                    
                                }
                                
                                //remove duplicate
                                let uniqueCategories =  categroies.removingDuplicates()
                                let uniquePlaces = places.removingDuplicates()
                                
                                //5 set a adventureTubData
                                newAdventureTubeData =  AdventureTubeData(coreDataID: storyEntity.id,
                                                                              youtubeContentID: storyEntity.youtubeId,
                                                                              youtubeTitle: storyEntity.youtubeTitle,
                                                                              youtubeDescription: storyEntity.youtubeDescription,
                                                                              userContentCategory: uniqueCategories,
                                                                              userTripDuration: Duration.build(rawValue:storyEntity.userTripDuration),
                                                                              userContentType: ContentType.build(rawValue:storyEntity.userContentType),
                                                                              places: uniquePlaces,
                                                                              chapters:chapters,
                                                                              isPublished: storyEntity.isPublished)
                                
                                tempYoutubeContentItem.snippet.adventureTubeData = newAdventureTubeData
                                print("List  YoutubeContentItem.snippet.adventureTubeData \(tempYoutubeContentItem.snippet.adventureTubeData)")
                            }
                            
                        }
                        return tempYoutubeContentItem
                    }
                    
                    self.youtubeContentItems.append(contentsOf: tempYoutuebeContentItem)
                }catch let error {
                    print("Error fetching \(error.localizedDescription) ")
                }
            })
        }
    }
    
    func findStoryEntityForYoutubeId(atId : String) -> StoryEntity?{
        
        if let story = stories.first(where: { story  in
            story.youtubeId == atId
            //set the
            
        }) {
            return story
        }
        return nil
    }
    
    
    
    /// it will listenining any save  , update , delete from NSmangement Context
    /// and Published that Story
    func listenCoreDataSaveAndUpdate(){
        coreDataStorage.didSavePublisher(for: StoryEntity.self,
                                         in: CoreDataManager.instance.context,
                                         changeTypes: [.inserted,.deleted, .updated])
        .sink {[weak self] changes in
            guard   let self = self else{return}
            changes.forEach { (stories , changeType) in
                switch changeType {
                        //ATM StoryEntity will be initialized at AddStoryViewVM and shared with CreateStoryViewVM
                        //at that point there is no data for chapter or place at all
                        //so this logic is no use currentlty
                        //leave this now for any chance to create Story,Chapter,Place all together in the future
                    case .inserted :
                        if let updatedStoryEntity = stories.first {
                            
                            ///1) find youtube ContentItem that matches videoId with CoreData
                            ///2) create AdventureTubeData  using a data from CoreData
                            ///3) mapping on YoutubeContentItem.snippet.adventureTubeData
                            ///4) finally assign the data to the youtubeContentItems which will pulbshed any change throught the view hierarchy
                            print("story has been inserted")
                            self.youtubeContentItems =  self.youtubeContentItems.map { youtubeContentItem -> YoutubeContentItem in
                                var updateYoutubeContentItem = youtubeContentItem
                                
                                //set the Chapter first
                                if(updateYoutubeContentItem.contentDetails.videoId == updatedStoryEntity.youtubeId ){
                                    
                                    var chapters : [AdventureTubeChapter] = []
                                    var categroies : [Category] = []
                                    var places : [AdventureTubePlace] = []
                                    
                                    updatedStoryEntity.chapters.forEach { chapter  in
                                        guard let chapterEntiry = chapter as? ChapterEntity else{ return }
                                        let place = chapterEntiry.place
                                        //1) set AdventureTubePlace
                                        let adventureTubePlace = AdventureTubePlace(coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude),
                                                                                    name: place.name,
                                                                                    youtubeTime: Int(place.youtubeTime),
                                                                                    contentCategory: place.placeCategory.compactMap{Category(rawValue: $0)},
                                                                                    placeID: place.placeID,
                                                                                    plusCode: place.pluscode,
                                                                                    website: place.website)
                                        //2) set a chapters
                                        let chapterCategories = chapterEntiry.category.compactMap{Category(rawValue: $0)}
                                        let chapter = AdventureTubeChapter(categories: chapterCategories,// category set for each chapter
                                                                           youtubeId: chapterEntiry.story.youtubeId,
                                                                           youtubeTime: Int(chapterEntiry.youtubeTime),
                                                                           place: adventureTubePlace)
                                        chapters.append(chapter)
                                        
                                        //3 set a places and category
                                        places.append(adventureTubePlace)
                                        categroies.append(contentsOf: chapterCategories)
                                    }
                                    
                                    //remove duplicate
                                    let uniqueCategories =  categroies.removingDuplicates()
                                    let uniquePlaces = places.removingDuplicates()
                                    
                                    //5 set a adventureTubData
                                    let newAdventureTubeData =  AdventureTubeData(coreDataID: updatedStoryEntity.id,
                                                                                  youtubeContentID: updatedStoryEntity.youtubeId,
                                                                                  youtubeTitle: updatedStoryEntity.youtubeTitle,
                                                                                  youtubeDescription: updatedStoryEntity.youtubeDescription,
                                                                                  userContentCategory: uniqueCategories,
                                                                                  userTripDuration: Duration.build(rawValue:updatedStoryEntity.userTripDuration),
                                                                                  userContentType: ContentType.build(rawValue:updatedStoryEntity.userContentType),
                                                                                  places: uniquePlaces,
                                                                                  chapters:chapters,
                                                                                  isPublished: updatedStoryEntity.isPublished)
                                    
                                    updateYoutubeContentItem.snippet.adventureTubeData = newAdventureTubeData
                                    self.adventureTubeData = newAdventureTubeData
                                    print("insert  YoutubeContentItem.snippet.adventureTubeData \(updateYoutubeContentItem.snippet.adventureTubeData)")
                                }
                                return updateYoutubeContentItem
                            }
                        }
                        
                    case .updated :
                        //                        self.story = stories.first
                        print("story has been update")
                        if let updatedStoryEntity = stories.first {
                            /// find the story on the youtubeContentItems
                            /// add new composed story
                            /// publish
                            self.youtubeContentItems =  self.youtubeContentItems.map { youtubeContentItem -> YoutubeContentItem in
                                var updateYoutubeContentItem = youtubeContentItem
                                
                                if(updateYoutubeContentItem.contentDetails.videoId == updatedStoryEntity.youtubeId ){
                                    
                                    var chapters : [AdventureTubeChapter] = []
                                    var categroies : [Category] = []
                                    var places : [AdventureTubePlace] = []
                                    
                                    updatedStoryEntity.chapters.forEach { chapter  in
                                        guard let chapterEntiry = chapter as? ChapterEntity else{ return }
                                        let place = chapterEntiry.place
                                        //1) set AdventureTubePlace
                                        let adventureTubePlace = AdventureTubePlace(coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude),
                                                                                    name: place.name,
                                                                                    youtubeTime: Int(place.youtubeTime),
                                                                                    contentCategory: place.placeCategory.compactMap{Category(rawValue: $0)},
                                                                                    placeID: place.placeID,
                                                                                    plusCode: place.pluscode,
                                                                                    website: place.website)
                                        //place and chapter is not saved now
                                        //2) set a chapters
                                        let chapterCategories = chapterEntiry.category.compactMap{Category(rawValue: $0)}
                                        let chapter = AdventureTubeChapter(categories: chapterCategories,// category set for each chapter
                                                                           youtubeId: chapterEntiry.story.youtubeId,
                                                                           youtubeTime: Int(chapterEntiry.youtubeTime),
                                                                           place: adventureTubePlace)
                                        chapters.append(chapter)
                                        
                                        //3 set a places and category
                                        places.append(adventureTubePlace)
                                        categroies.append(contentsOf: chapterCategories)
                                    }
                                    
                                    let uniqueCategories =  categroies.removingDuplicates()
                                    let uniquePlaces = places.removingDuplicates()
                                    
                                    //5 set a adventureTubData
                                    let newAdventureTubeData =  AdventureTubeData(coreDataID: updatedStoryEntity.id,
                                                                                  youtubeContentID: updatedStoryEntity.youtubeId,
                                                                                  youtubeTitle: updatedStoryEntity.youtubeTitle,
                                                                                  youtubeDescription: updatedStoryEntity.youtubeDescription,
                                                                                  userContentCategory: uniqueCategories,
                                                                                  userTripDuration: Duration.build(rawValue:updatedStoryEntity.userTripDuration),
                                                                                  userContentType: ContentType.build(rawValue:updatedStoryEntity.userContentType),
                                                                                  places: uniquePlaces,
                                                                                  chapters:chapters,
                                                                                  isPublished: updatedStoryEntity.isPublished)
                                    
                                    updateYoutubeContentItem.snippet.adventureTubeData = newAdventureTubeData
                                    self.adventureTubeData = newAdventureTubeData
                                    print("update  YoutubeContentItem.snippet.adventureTubeData \(updateYoutubeContentItem.snippet.adventureTubeData)")
                                }
                                
                                return updateYoutubeContentItem
                            }
                            
                        }
                    case .deleted :
                        //                        self.story = stories.first
                        print("story has been delete")
                }
            }
            
        }
        .store(in: &cancellables)
    }
    
    
    deinit{
        print("MainStoryListViewModel is deinitizing now ~~~~")
    }
    
}
