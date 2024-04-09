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
class AddStoryViewVM : ObservableObject {
    @Published var adventureTubeData : AdventureTubeData?
    let youtubeContentItem       : YoutubeContentItem
    
    @Published  var actionSheet : AddStoryViewActiveSheet?
    
    
    @Published var buttons : [CustomNavBarButtonItem] = []
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
    private var cancellables = Set<AnyCancellable>()
    private let manager = CoreDataManager.instance
    private var storyEntity: StoryEntity?
    
    
    init(youtubeContentItem : YoutubeContentItem , adventureTubeData : AdventureTubeData?){
        self.youtubeContentItem = youtubeContentItem
        self.adventureTubeData = adventureTubeData
        self.createChapterViewVM = CreateChapterViewVM(youtubeContentItem: youtubeContentItem)
        
        
        
        /// checkComposedStory will convert adventureTubeData to
        /// all kind of datatyoe for
        /// category , duration , video type and location
        /// and also setup all confirmedPlace in createChapterViewVM
        buttons = [.back]
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
            if let adventureTubeLocation = chapters.first?.place{
                
                let marker =  GMSMarker(position: adventureTubeLocation.coordinate)
                
                marker.title = adventureTubeLocation.name
                marker.icon =  UIImage(systemName: "1.circle.fill")?
                    .resize(maxWidthHeight: 35)?
                    .maskWithColor(color: .red)
                createChapterViewVM.selectedMarker = marker
            }
            
            //confimed marker: GMSMarker
            createChapterViewVM.markers =  chapters.enumerated().map{ (index ,chapter) -> GMSMarker in
                let marker =  GMSMarker(position: chapter.place.coordinate)
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
    func initStoryEntity() {
        let reqeust = NSFetchRequest<StoryEntity>(entityName:"StoryEntity")
        let filter = NSPredicate(format: "youtubeId == %@", youtubeContentItem.contentDetails.videoId)
        reqeust.predicate = filter
        
        
        do{
            let stories = try manager.context.fetch(reqeust)
            if stories.count > 0{
                storyEntity = stories.first
                createChapterViewVM.storyEntity = stories.first
                print("found story entity from coredata")
            }else{
                //create new storyentity
                let storyEntity = StoryEntity(context: manager.context)
                //1) Delete Process if necessary
                if storyEntity.id.count == 0 {
                    storyEntity.id = UUID().uuidString
                }
                
                //setting storyentity
                
                storyEntity.youtubeId = youtubeContentItem.contentDetails.videoId
                storyEntity.youtubeDescription = youtubeContentItem.snippet.description ?? "Please update description"
                storyEntity.youtubeTitle = youtubeContentItem.snippet.title
                storyEntity.youtubePublishedAt = youtubeContentItem.snippet.publishedAt
                storyEntity.youtubeMaxresThumbnailURL = youtubeContentItem.snippet.thumbnails.maxres?.url
                storyEntity.youtubehighThumbnailURL = youtubeContentItem.snippet.thumbnails.high?.url
                storyEntity.youtubeMediumThumbnailURL = youtubeContentItem.snippet.thumbnails.medium?.url
                storyEntity.youtubeStandardThumbnailURL = youtubeContentItem.snippet.thumbnails.standard?.url
                storyEntity.youtubeDefaultThumbnailURL = youtubeContentItem.snippet.thumbnails.thumbnailsDefault?.url
                storyEntity.userTripDuration = durationSelection.rawValue
                storyEntity.userContentType = videoTypeSelection.rawValue
                
                manager.save()
                
                self.storyEntity = storyEntity
                createChapterViewVM.storyEntity = storyEntity
                
            }
        }catch let error {
            print("Error fetching.\(error.localizedDescription)")
        }
        
        
        
    }
    
    private func storyHasChapter(){
        if chapters.count > 0 {
            hasChapter = true
            self.buttons = [.checkUpdateBeforeBack(addStoryViewVM: self) ,
                             .uploadStory(addStoryViewVM:self)]
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
    
    //https://word-sentences.com/code-examples/google-ios-sdk-swift-fit-bounds/#google-ios-sdk-swift-fit-bounds
    
    //    func fitAllMarkers() {
    //        var bounds = GMSCoordinateBounds()
    //
    //        for marker in markerList {
    //            bounds = bounds.includingCoordinate(marker.position)
    //        }
    //
    //        map.animateWithCameraUpdate(GMSCameraUpdate.fitBounds(bounds))
    //        //For Swift 5 use the one below
    //        //self.mapView.animate(with: GMSCameraUpdate.fit(bounds))
    //    }
    
    //    func checkUpdatedDataFromAdventureTubeData() -> Bool {
    //        var isAnyContentsUpdated = true
    //
    //        var contentTypeMatch = false
    //        var contentDurationMatch = false
    //        var contentCategoryMatch = false
    //        var confirmedPlaceMatch = false
    //
    //        if let adventureTubeData = adventureTubeData {
    //            contentTypeMatch =   adventureTubeData.userContentType == videoTypeSelection
    //            contentDurationMatch = adventureTubeData.userTripDuration == durationSelection
    //            contentCategoryMatch =  categorySelection == adventureTubeData.userContentCategory
    //
    //            confirmedPlaceMatch = places == adventureTubeData.places.map { adventureTubeLocation -> GoogleMapAPIPlace in
    //                var googleMapAPIPlace = GoogleMapAPIPlace(name:adventureTubeLocation.name)
    //
    //                googleMapAPIPlace.youtubeTime = adventureTubeLocation.youtubeTime
    //                googleMapAPIPlace.contentCategories = adventureTubeLocation.contentCategory
    //                googleMapAPIPlace.placeId = adventureTubeLocation.placeID
    //                googleMapAPIPlace.plusCode = adventureTubeLocation.plusCode
    //                googleMapAPIPlace.coordinate =  CLLocationCoordinate2D(latitude: adventureTubeLocation.coordinate.latitude,
    //                                                                       longitude: adventureTubeLocation.coordinate.longitude)
    //                return googleMapAPIPlace
    //            }
    //        }
    //
    //        if( contentTypeMatch && contentDurationMatch && contentCategoryMatch && confirmedPlaceMatch ){
    //            isAnyContentsUpdated = false
    //        }
    //
    //        print("isAnyContentsUpdated  is \(isAnyContentsUpdated)")
    //        return isAnyContentsUpdated
    //    }
    //    func fetchStory(){
    //        let request = NSFetchRequest<StoryEntity>(entityName:"StoryEntity")
    //
    //        do {
    //            savedEntities = try container.viewContext.fetch(request)
    //        }catch let error {
    //            print("Error fetching. \(error)")
    //        }
    //    }
    
    //Content Category need 2 dimention Package
    func getCategoryList() -> [[ContentCategory]]{
        let retrunCartegoryArray :[[ContentCategory]] =
        
        [[.tent , .caravan , .campfire ,.cooking , .hiking ,.mountainbike ],//campimng activity
         [.scuberdive ,.fishing , .canue , .kayak , .yart , .sulf] , //water acticity
         [.mountainbike , .horseriding , .biketour ,.dirtbike , .climing , .ski],
         [.reading , .restaurant, .dog , .music  , .motorbiketour ,.filming]]
        return retrunCartegoryArray
    }
    
    
    
    func deleteChapterAt(index: Int){
        //step 1 delete core data
        guard let storyEntity = storyEntity else {
            print("fail to retrive storyEntity")
            return
        }
        let chapterEntity : ChapterEntity =  storyEntity.chapters[index] as! ChapterEntity
        let placeEntity : PlaceEntity = chapterEntity.place
        //delete chapterEntity from storyEntity
        storyEntity.removeFromChapters(chapterEntity)
        
        deleteChapterEntity(entity: chapterEntity)
        deletePlaceEntity(entity: placeEntity)
        
        //step 2 delete chapter value from createChapterViewVM
        //and it will apply to AddStoryViewVM autometically
        createChapterViewVM.chapters.remove(at: index)
        
        
        //4 delete all icon
        createChapterViewVM.AllMarkerIconReset()
    }
    
    
    //save  new story
    func  saveNewStory(){
        //check the validate of Data for Activity/ duration /type /location
        do{
            try validaterAllContentsBeforeStoreToCoreData()
            //all validation has been passed
            //StoreCode DATA !!!!!!!!
            print("story will be saved in coredata")
            let newStory  = StoryEntity(context: manager.context)
            ApplyStoryToCoreData(storyEntity: newStory)
            
        }catch{
            print("there is error \(error.localizedDescription)")
            isShowErrorMessage = true
            errorMessage = error.localizedDescription
        }
        
        
    }
    
    func validateForCreateChaptor(completion : (Bool) -> ()){
        do{
            try validaterExceptLocation()
            completion(isShowErrorMessage)
        }catch{
            print("there is error \(error.localizedDescription)")
            isShowErrorMessage = true
            completion(isShowErrorMessage)
            errorMessage = error.localizedDescription
        }
    }
    //1) validate
    //2) bring the target entity from coredata
    //3) update coredata accordingly
    //4) save updated  form categorySelection , durationSelection , videoTypeSelection , confirmedPlace  Not from adventureTubeData
    func  saveUpdatedStory(){
        //check the validate of Data for Activity/ duration /type /location
        
        do{
            try validaterAllContentsBeforeStoreToCoreData()
            //all validation has been passed
            //bring the target entity from coredata
            //            print("story will be saved in coredata")
            //            addStoryToCoreData()
            
        }catch{
            print("there is error \(error.localizedDescription)")
            isShowErrorMessage = true
            errorMessage = error.localizedDescription
        }
        
        let request = NSFetchRequest<StoryEntity>(entityName:"StoryEntity")
        let filter = NSPredicate(format: "youtubeId == %@", youtubeContentItem.contentDetails.videoId)
        request.predicate = filter
        
        var targetStoryEntity : StoryEntity?
        
        do{
            let stories = try manager.context.fetch(request)
            if stories.count > 0 {
                targetStoryEntity = stories.first
                print("found story from coreData")
                
                
            }
        }catch let error {
            print("Error fetching. \(error.localizedDescription)")
        }
        
        
        //update story entity and save
        if let storyEntity = targetStoryEntity{
            ApplyStoryToCoreData(storyEntity: storyEntity)
        }
    }
    //{"places.location":{$near :  {$maxDistance :250000 , $geometry:{type:"Point",coordinates:[141.6041,-38.3]}}}}
    func uploadStory(){
        
        do{
            try validaterAllContentsBeforeStoreToCoreData()
            //all validation has been passed
            //bring the target entity from coredata
            //            print("story will be saved in coredata")
            //            addStoryToCoreData()
            
        }catch{
            print("there is error \(error.localizedDescription)")
            isShowErrorMessage = true
            errorMessage = error.localizedDescription
        }
        
        let request = NSFetchRequest<StoryEntity>(entityName:"StoryEntity")
        let filter = NSPredicate(format: "youtubeId == %@", youtubeContentItem.contentDetails.videoId)
        request.predicate = filter
        
        var targetStoryEntity : StoryEntity?
        
        do{
            let stories = try manager.context.fetch(request)
            if stories.count > 0 {
                targetStoryEntity = stories.first
                print("found story from coreData")
                
                
            }
        }catch let error {
            print("Error fetching. \(error.localizedDescription)")
        }
        
        do {
            if let storyEntity = targetStoryEntity {
                
                guard let url = URL(string: APIService.rasberryTestServer.address) else { return }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try createJsonFromStory(storyEntity: storyEntity)
                
                URLSession.DataTaskPublisher(request: request, session: .shared)
                //inspect response before inspection the data
                //and throw an Error if the response is unacceptable
                    .tryMap { data,response -> Data in
                        guard let httpResponse = response as? HTTPURLResponse,
                              (200...299).contains(httpResponse.statusCode) else{
                            if let mimeType = response.mimeType,
                               mimeType == "application/json"{
                                
                                let responseMessage = try JSONDecoder().decode(ResponseMessage.self, from: data)
                                DispatchQueue.main.async {
                                    self.actionSheet = .uploadFailByYoutubeIdSheet
                                }
                                throw APIError.apiError(reason: responseMessage.message)
                            }
                            throw APIError.unknown
                        }
                        return data
                    }
                    .decode(type: ResponseMessage.self, decoder: JSONDecoder())
                    .sink(receiveCompletion: { completion in
                        switch completion{
                        case .finished:
                            break
                        case .failure(let error):
                            print(error.localizedDescription)
                        }
                    }, receiveValue: { responseMessage in
                        print("responseMessage \(responseMessage)")
                        DispatchQueue.main.async {
                            self.actionSheet = .uploadSuccessSheet
                            storyEntity.isPublished = true
                            self.manager.save()
                        }                    })
                    .store(in: &cancellables)
            }
        }catch let error{
            print("Error create json. \(error.localizedDescription)")
        }
    }
    
    enum APIError: Error, LocalizedError {
        case unknown, apiError(reason: String)
        
        var errorDescription: String? {
            switch self {
            case .unknown:
                return "Unknown error"
            case .apiError(let reason):
                return reason
            }
        }
    }
    
    
    func createJsonFromStory( storyEntity: StoryEntity) throws ->  Data  {
        var chapters : [AdventureTubeChapter] = []
        var categroies : [Category] = []
        var places : [AdventureTubePlace] = []
        
        
        storyEntity.chapters.forEach { chapter  in
            guard let chapterEntiry = chapter as? ChapterEntity else{ return }
            let placeEntity = chapterEntiry.place
            //1) set AdventureTubePlace
            let adventureTubePlace = AdventureTubePlace(location: GeoJson(coordinates: [placeEntity.longitude,placeEntity.latitude]),
                                                        coordinate: CLLocationCoordinate2D(latitude: placeEntity.latitude, longitude: placeEntity.longitude),
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
        let newAdventureTubeData =  AdventureTubeData(coreDataID: storyEntity.id,
                                                      youtubeContentID: storyEntity.youtubeId,
                                                      youtubeTitle: storyEntity.youtubeTitle,
                                                      youtubeDescription: storyEntity.youtubeDescription,
                                                      userContentCategory: uniqueCategories,
                                                      userTripDuration: Duration.build(rawValue:storyEntity.userTripDuration),
                                                      userContentType: ContentType.build(rawValue:storyEntity.userContentType),
                                                      places: uniquePlaces,
                                                      chapters:chapters)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonResultData = try encoder.encode(newAdventureTubeData)
        
        print(String(data: jsonResultData, encoding: .utf8)!)
        return jsonResultData
    }
    
    /* func updateStoryFromCoreData()
     func updateStoryFromCoreData(){
     
     
     let request = NSFetchRequest<StoryEntity>(entityName:"StoryEntity")
     let fileter = NSPredicate(format: "youtubeId == %@", youtubeContentItem.id)
     request.predicate = fileter
     do{
     let stories = try manager.context.fetch(request)
     if stories.count > 0 {
     //                story = stories.first
     //                isStoryComposed = true
     print("found story from coreData")
     }
     }catch let error {
     print("Error fetching. \(error.localizedDescription)")
     }
     
     }
     */
    
    private func validaterAllContentsBeforeStoreToCoreData() throws{
        //        guard categorySelection.count > 0 else{
        //            throw SaveError.needActivityType
        //        }
        
        guard durationSelection != .select else{
            throw SaveError.needTriopDuration
        }
        
        guard  videoTypeSelection != .select  else{
            throw SaveError.needVideoType
        }
        
        //        guard confirmedPlaces.count > 0 else{
        //            throw SaveError.needLocationData
        //        }
        //
        //       try confirmedPlaces.map { place in
        //            guard place.youtubeTime != 0 else{
        //                throw SaveError.needMatchLocationWithTime(location: place.name)
        //            }
        //        }
    }
    
    private func validaterExceptLocation() throws{
        //        guard categorySelection.count > 0 else{
        //            throw SaveError.needActivityType
        //        }
        
        guard durationSelection != .select else{
            throw SaveError.needTriopDuration
        }
        
        guard  videoTypeSelection != .select  else{
            throw SaveError.needVideoType
        }
    }
    
    // This will insert or update storyentity
    func ApplyStoryToCoreData(storyEntity : StoryEntity){
        
        //1) Delete Process if necessary
        if storyEntity.id.count == 0 {
            storyEntity.id = UUID().uuidString
        }else{
            
            //delete all chapter if there is any
            storyEntity.chapters.forEach { chapter in
                if let chapter = chapter as? ChapterEntity{
                    storyEntity.removeFromChapters(chapter)
                    deleteChapterEntity(entity: chapter)
                }
            }
            manager.save()
            
            
            //delete all location if there is any
            storyEntity.places.forEach { place in
                if let place = place as? PlaceEntity{
                    //delete place relastion info from Story first
                    storyEntity.removeFromPlaces(place)
                    //delete place itself
                    deletePlaceEntity(entity: place)
                }
            }
            manager.save()
        }
        //
        storyEntity.youtubeId = youtubeContentItem.contentDetails.videoId
        storyEntity.youtubeDescription = youtubeContentItem.snippet.description ?? "Please update description"
        storyEntity.youtubeTitle = youtubeContentItem.snippet.title
        storyEntity.youtubePublishedAt = youtubeContentItem.snippet.publishedAt
        storyEntity.youtubeMaxresThumbnailURL = youtubeContentItem.snippet.thumbnails.maxres?.url
        storyEntity.youtubehighThumbnailURL = youtubeContentItem.snippet.thumbnails.high?.url
        storyEntity.youtubeMediumThumbnailURL = youtubeContentItem.snippet.thumbnails.medium?.url
        storyEntity.youtubeStandardThumbnailURL = youtubeContentItem.snippet.thumbnails.standard?.url
        storyEntity.youtubeDefaultThumbnailURL = youtubeContentItem.snippet.thumbnails.thumbnailsDefault?.url
        
        
        storyEntity.userTripDuration = durationSelection.rawValue
        storyEntity.userContentType = videoTypeSelection.rawValue
        
        
        //savew  Chapter and place with replationship
        let chapterEntityArray =  chapters.enumerated().map {( index, chapter) -> ChapterEntity in
            let newChapter = ChapterEntity(context: manager.context)
            newChapter.id = UUID().uuidString
            newChapter.category = chapter.categories.map{$0.rawValue}
            newChapter.youtubeTime = Int16(chapter.youtubeTime)
            newChapter.youtubeId = chapter.youtubeId
            
            
            //create place for chapter
            let placeOfChapter: AdventureTubePlace = chapter.place
            let newPlace = PlaceEntity(context: manager.context)
            newPlace.id = UUID().uuidString
            newPlace.youtubeTime = Int16(placeOfChapter.youtubeTime)
            newPlace.name = placeOfChapter.name
            newPlace.placeID = placeOfChapter.placeID ?? "no placeID"
            newPlace.pluscode = placeOfChapter.plusCode
            //newLocation.types  = place.types ?? []
            newPlace.latitude = placeOfChapter.coordinate.latitude
            newPlace.longitude = placeOfChapter.coordinate.longitude
            newChapter.place = newPlace
            return newChapter
        }
        
        //save chapter array
        let nsOrderChapterEntitySet = NSOrderedSet(array: chapterEntityArray)
        storyEntity.chapters = nsOrderChapterEntitySet
        save()
        
        //3 insert all comnfirmed location
        let placeEntityArray =  places.enumerated().map{ (index , googleMapAPIPlace) -> PlaceEntity  in
            let newPlace = PlaceEntity(context: manager.context)
            //            guard let place = atGooglePlace.googlePlace else {
            //                print("place info is not able to get so will not stored in coredata")
            //                return newLocation
            //            }
            newPlace.id = UUID().uuidString
            newPlace.youtubeTime = Int16(googleMapAPIPlace.youtubeTime)
            newPlace.name = googleMapAPIPlace.name
            newPlace.placeID = googleMapAPIPlace.placeId ?? "no placeID"
            newPlace.pluscode = googleMapAPIPlace.plusCode
            //newLocation.types  = place.types ?? []
            newPlace.latitude = googleMapAPIPlace.coordinate?.latitude ?? 0
            newPlace.longitude = googleMapAPIPlace.coordinate?.longitude ??  0
            return newPlace
        }
        //        .reduce(Set<LocationEntity>() ,{ partialResult, locationlEntity in
        //            var locationSet =  partialResult
        //            locationSet.insert(locationlEntity)
        //            return locationSet
        //        })
        
        let nsPlaceEntitySet = NSSet(array: placeEntityArray)
        storyEntity.places = nsPlaceEntitySet
        save()
        
    }
    private func deleteAllChapterAndPlace(){
        if let storyEntity = storyEntity {
            //delete all chapter if there is any
            storyEntity.chapters.forEach { chapter in
                if let chapter = chapter as? ChapterEntity{
                    storyEntity.removeFromChapters(chapter)
                    deleteChapterEntity(entity: chapter)
                }
            }
            manager.save()
            
            
            //delete all location if there is any
            storyEntity.places.forEach { place in
                if let place = place as? PlaceEntity{
                    //delete place relastion info from Story first
                    storyEntity.removeFromPlaces(place)
                    //delete place itself
                    deletePlaceEntity(entity: place)
                }
            }
            manager.save()
        }
    }
    
    private func deleteStoryEntity(entity: StoryEntity) {
        manager.context.delete(entity)
        save()
    }
    
    private func deleteChapterEntity(entity: ChapterEntity) {
        manager.context.delete(entity)
        save()
    }
    
    private func deletePlaceEntity(entity: PlaceEntity) {
        manager.context.delete(entity)
        save()
    }
    
    
    func save(){
        manager.save()
    }
    
    func getStories() {
        let request = NSFetchRequest<StoryEntity>(entityName: "StoryEntity")
        do {
            stories = try manager.context.fetch(request)
            
            print("you have \(stories.count) stories on core data")
        }catch let error {
            print("Error fetching . \(error.localizedDescription)")
        }
    }
}


struct ResponseMessage:Codable{
    var timestamp:String
    var message:String
    var contentId:String
    var contentTitle:String
}
