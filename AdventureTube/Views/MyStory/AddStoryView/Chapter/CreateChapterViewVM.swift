//
//  PlacesContentViewViewModel.swift
//  AdventureTube
//
//  Created by chris Lee on 6/4/22.
//

import Foundation
import GoogleMaps
import GooglePlaces
import Combine
import CoreData
// MARK: Error Section
enum createChaptorError : Error {
    case setChaptorOnYoutubeTime
    case setCategoryOnChaptor
}


extension createChaptorError : LocalizedError {
    var errorDescription: String?{
        switch self{
        case .setCategoryOnChaptor:
            return NSLocalizedString("Please choose at least on category for chapter", comment: "")
        case .setChaptorOnYoutubeTime :
            return NSLocalizedString("Please set chaptor at specific youtube time ", comment: "")
        }
    }
}

enum LocationOnMapStatus : String {
    var id: Self {self}
    case searchLocation , // when user search mode
         selectLocation , // user select one place from prediction
         confirmLocation, // user confirm the location   => user can go back to search mode
         //         deleteLocation ,
         //         focusLocation ,
         finish
    //         save
}
/// This class initialize in inside of AddStoryViewViewModel
/// since   AddStoryViewViewModel class will have responsibilty to store all information
/// for the Story liker activity type , duration , video type  and  locations to the core data
class CreateChapterViewVM : ObservableObject {
    
    @Published var processStatus : LocationOnMapStatus = .searchLocation // initial state
    @Published  var searchResultPlaces : [GoogleMapAPIPlace] = []
    
    //These are go to the GoogleMapViewControllerBridge
    var markers :[GMSMarker] = []
    var selectedMarker : GMSMarker?{
        didSet{
            isMarkerWillRedrawing = true
        }
    }
    var isMarkerWillRedrawing = false
    var isGoogleMapSheetMode  = false
    
    //This selected Place need to be confimed in order to become a chapter
    //this one has coordinate data and will be added on confirmedPlace after confirmed process
    var placeForChapter : GoogleMapAPIPlace?
    
    //    This will allow map to pinned all location that has been returned  GMSPlace
    //    at this moment user need to confirmed for the place instead
    //    @Published  var atGmsPlaces : [GMSPlace] {
    //        didSet{
    //            markers = atGmsPlaces.map{ gmsPlace -> GMSMarker in
    //                let marker = GMSMarker(position: gmsPlace.coordinate)
    //                marker.title = gmsPlace.name
    //                return marker
    //            }
    //
    //        }
    //    }
    //this goes to the AddStoryView & CreateChapterView
    @OrderedChapterArrayPublished var chapters : [AdventureTubeChapter]
    
    
    @Published var chapterCategory : [Category] = []
    @Published  var isSearchResultListShow : Bool = false
    @Published var searchText : String  = ""
    
    
    //this value will be set when number on the map has been clicked
    @Published var selectedChapterIndex  = 0
    let filter : GMSAutocompleteFilter
    let neBoundsCorner : CLLocationCoordinate2D
    let swBoundsCorner : CLLocationCoordinate2D
    
    private var cancellables = Set<AnyCancellable>()
    private let googleMapAPIService  = GoogleMapAndPlaceAPIService()
    
    
    private let manager = CoreDataManager.instance
    @Published var isShowErrorMessage = false
    @Published var errorMessage = ""
    
    var storyEntity: StoryEntity?
    
    let youtubeContentItem : YoutubeContentItem
    var durationSelection : Duration = .select
    var videoTypeSelection : ContentType = .select
    init(youtubeContentItem:YoutubeContentItem){
        
        // initial for search
        print("init AddStoryMapViewViewModel~~")
        self.youtubeContentItem = youtubeContentItem
        filter = GMSAutocompleteFilter()
        filter.type = .noFilter
        // Set bounds to inner-west Sydney Australia.
        neBoundsCorner = CLLocationCoordinate2D(latitude: -33.843366,
                                                longitude: 151.134002)
        swBoundsCorner = CLLocationCoordinate2D(latitude: -33.875725,
                                                longitude: 151.200349)
        filter.countries = ["au", "nz"]
        
        searchResultPlaces = []
        //self must be called after all property has been initialized properly
        addSearchTextSubscriber()
    }

    func addSearchTextSubscriber(){
        
        
        $searchText
            .debounce(for: .seconds(0.2), scheduler: DispatchQueue.main)
        //TODO:    1)before return the result we can filter onemore time and mapping here as well
        //       2) still want to priotise
            .sink {[weak self] updatedSearchText in
                //make sure updatedSearchText is  more than  4 letter
                guard updatedSearchText.count >  3,
                      let self = self  else {return}
                
                self.isSearchResultListShow = true
                self.googleMapAPIService
                    .autoCompletePrediction(fromQuery: updatedSearchText ,
                                            filter: self.filter){ places in
                        self.searchResultPlaces = places.map { place in
                            var searchPlace : GoogleMapAPIPlace = GoogleMapAPIPlace(name: place.attributedPrimaryText.string)
                            searchPlace.name = place.attributedPrimaryText.string
                            searchPlace.fullName = place.attributedFullText
                            searchPlace.primaryName =  place.attributedPrimaryText
                            if let secondaryName = place.attributedSecondaryText {
                                searchPlace.secondryName = secondaryName
                            }
                            searchPlace.placeId = place.placeID
                            searchPlace.types = place.types
                            
                            return searchPlace
                        }
                    }
            }.store(in: &cancellables)
    }
    
    
    /// atGooglePlace at the parameter has only information GMSAutocomplete which is name and place id  !!!!!
    /// even without CLLocation info
    ///
    /// after click the search list all essential data will get from GMSPlace
    func setCandidatePlaceFromSearchList(googleMapAPIPlace : GoogleMapAPIPlace , completion:@escaping () -> ()){
        //print(" call and get the geoLocation info from GoogleMapServiceAPI")
        //The placeId can be a nil
        guard let placeId = googleMapAPIPlace.placeId else{
            print("no place id error")
            return
        }
        
        googleMapAPIService.getPlaceFieldCoordinate(placeId: placeId) {[weak self] place in
            guard let self = self else{ return}
            
            //all data from Google Place has been set
            self.placeForChapter = GoogleMapAPIPlace(id: UUID().uuidString,
                                                                  name: place.name ?? "no name",
                                                                  fullName: googleMapAPIPlace.fullName,
                                                                  primaryName: googleMapAPIPlace.primaryName,
                                                                  secondryName: googleMapAPIPlace.secondryName,
                                                                  coordinate: place.coordinate,
                                                                  types: place.types,
                                                                  //placeId: place.placeID,
                                                                  placeId:placeId,
                                                                  plusCode: place.plusCode?.globalCode)
            // set the marker for the map
            if let coordinate = self.placeForChapter?.coordinate {
                let marker = GMSMarker(position: coordinate)
                marker.title = self.placeForChapter?.name
                //self.isMarkerWillRedrawing = true
                self.selectedMarker = marker
                self.isSearchResultListShow = false
                self.processStatus = .selectLocation
                completion()
            }
            
        }
    }
    
    //1 if user tapping on the google map
    //2 This method will be called by mapView didTapPOI by deligation
    //3 will be set the selectedPlace
    //4 that cause call the updateUIViewController
    
    func setSelectedPlaceByTapAt(marker: GMSMarker,
                                 placeId : String,
                                 completion:@escaping (GoogleMapAPIPlace) -> ()){
        self.placeForChapter = GoogleMapAPIPlace(id: UUID().uuidString,
                                                              name: marker.title ?? "unNamedPlace",
                                                              coordinate: marker.position,
                                                              placeId: placeId,
                                                              youtubeTime: 0)
       //isMarkerWillRedrawing = true
        self.selectedMarker = marker
        self.isSearchResultListShow = false
        self.processStatus = .selectLocation
        if let selectedPlace = self.placeForChapter{
            completion(selectedPlace)
        }
    }
    
    func searchTextFieldTapped(){
        processStatus = .searchLocation
    }
    func focusOnSelectedMarkerBy(atIndex :Int ){
        //isMarkerWillRedrawing = true
        selectedChapterIndex = atIndex
        selectedMarker = markers[atIndex]
    }
    
    

    //icon update for marker does't require redrawing marker.!!!!
    //so it doesn't require to set
    func confirmSelectedPlace(){
        print("confirmSelectedPlace")
        guard let confirmedMarker = selectedMarker ,
              let confimedPlace  = placeForChapter else {
            return
        }
        
        //might better to checking duplicate here  and return the error if that is case
        //custom marker
        //let iconNumber = chapters.count+1
        
        confirmedMarker.icon =  UIImage(systemName: "pencil.tip.crop.circle.badge.plus")?
            .resize(maxWidthHeight: 35)?
            .maskWithColor(color: .red)
        //this can causing a multiple confirmed marker
        // if user keep cofirming without create chapter
        //markers.append(confirmedMarker)// update GoogleMap
        selectedMarker = confirmedMarker
        
        processStatus = .confirmLocation
    }
    
    //after delete if no place has been set it will force to input for search
    func deleteChapter(index: Int){
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
        
        chapters.remove(at: index)

        
        AllMarkerIconReset()
        //4 move selectectedChapterIndex accordingly
        
//        if index - 1 > 0 {
//            selectedChapterIndex = index - 1
//        }else{
//            selectedChapterIndex = 0
//        }

        //if there is no chapter consider that it require search
        var isSearchRequire = false
        if chapters.count > 0 {
            processStatus = .confirmLocation
        } else {
            isSearchRequire = true
            processStatus = .searchLocation
        }
        
        
    }
    
    func deleteMarkerAfterCancel(){
        //1  delete current selectedMaker
        
        selectedMarker = nil
        
//        var index = 1
//        markers.forEach{ marker in
//            marker.icon = UIImage(systemName: "\(index).circle.fill")?
//                .resize(maxWidthHeight: 35)?
//                .maskWithColor(color: .red)
//            index = index + 1
//        }
    }
    
    //This need to be delete search result since user will search for new result
    func deleteSearchFieldAndResult(){
        searchText = ""
        searchResultPlaces = []
        selectedMarker = nil // This will delete selected Marker on the map
        
        processStatus = .searchLocation
        //        if confirmedPlaces.count > 0 {
        //            processStatus = .confirmLocation
        //        }else{
        //            processStatus = .searchLocation
        //        }
    }
    
    func validateSearchText() -> Bool{
        var isSearchTextValidate = false
        if  searchText.count > 0 {
            isSearchTextValidate = true
        }
        
        return isSearchTextValidate
    }
    
    
    func searchDone() -> Bool{
        var isSearchDone = true
        if chapters.count > 0 {
            processStatus = .confirmLocation
        }else{
            processStatus = .searchLocation
            isSearchDone = false
        }
        return isSearchDone
    }
    
    //
    func validateNewChapter(index:Int) -> Bool{
        var isValdate = false
        if self.chapters[index].youtubeTime > 0 &&
            self.chapters[index].categories.count > 0 {
            isValdate = true
        }
        return isValdate
    }
    
    func getCategoryList()  -> [Category]{
        return [.camping,.caravan,.hiking,.campfire,.geocaching,.cooking,.bbq,.lookout,.driving,.navigation,
                .swimming,.mtb,.marine,.fishing,.dirtbike,.surf,.scubadiving,.kayak,
                .party,.beer,.music]
    }
    
    //    func allLocationHasBeenSet(){
    //        print("store location count is \(confirmedPlaces.count)")
    //        processStatus = .finish
    //    }
    
    //    func update(){
    //        processStatus = .searchLocation
    //    }
    
    
    //CoreData Section
    
    
    // This will insert or update storyentity
    
    //save  new story
    
    func createNewChapter(){
        guard let placeForChapter = placeForChapter ,
              let coordinate  = placeForChapter.coordinate
        else {
            print("create new chapter has been failed")
            return
        }
        
        //1 set place chapter
        let adventureTubePlace : AdventureTubePlace = AdventureTubePlace(
                                                            coordinate: coordinate,
                                                            name: placeForChapter.name,
                                                            youtubeTime: placeForChapter.youtubeTime,
                                                            contentCategory: chapterCategory)
        
        let newChapter : AdventureTubeChapter = AdventureTubeChapter(categories: self.chapterCategory,
                                        youtubeId: youtubeContentItem.contentDetails.videoId,
                                        youtubeTime: placeForChapter.youtubeTime,
                                        place: adventureTubePlace)
        
        //2 update coredata
        if let storyEntity = storyEntity {
            
            
            //create chapter entity
            let chapterEntity = ChapterEntity(context: manager.context)
            chapterEntity.id = UUID().uuidString
            chapterEntity.category = newChapter.categories.map{$0.rawValue}
            chapterEntity.youtubeTime = Int16(newChapter.youtubeTime)
            chapterEntity.youtubeId = newChapter.youtubeId
            //manager.save()
            
            //create place for chapter
            let placeEnity = PlaceEntity(context: manager.context)
            placeEnity.id = UUID().uuidString
            placeEnity.youtubeTime = Int16(adventureTubePlace.youtubeTime)
            placeEnity.youtubeId = youtubeContentItem.contentDetails.videoId
            placeEnity.placeCategory = chapterCategory.map{$0.rawValue}
            placeEnity.name = adventureTubePlace.name
            placeEnity.placeID = adventureTubePlace.placeID ?? "no placeID"
            placeEnity.pluscode = adventureTubePlace.plusCode
            //newLocation.types  = place.types ?? []
            placeEnity.latitude = adventureTubePlace.coordinate.latitude
            placeEnity.longitude = adventureTubePlace.coordinate.longitude
            manager.save()
            
            storyEntity.addToChapters(chapterEntity)
            storyEntity.addToPlaces(placeEnity)
            chapterEntity.place = placeEnity
            manager.save()
            
        }
        //3 after update chapters property
        // need update marker since CreateChapterView will not  update
        // which number in number section will not update  but dont know why
        chapters.append(newChapter)
        
      
        //4 delete all icon
        markers.removeAll()
        //5 delete selected image on marker
        //  this will delete selectedMaker on GoogleMap
        //selectedMarker = nil
        
        //6 redraw all the marker image
        //  and set the new marker image  on the property
        //  this will update all marker image on google map with correct order autometically
        selectedMarker = nil

        markers =  chapters.enumerated().map{ (index ,chapter) -> GMSMarker in
            let marker =  GMSMarker(position: chapter.place.coordinate)
            marker.title = chapter.place.name
            marker.icon = UIImage(systemName: "\(index+1).circle.fill")?
                .resize(maxWidthHeight: 35)?
                .maskWithColor(color: .red)
            if chapter.place.name == newChapter.place.name{
                //7 newchapter become a  selectedChapter
                selectedChapterIndex = index
                //????
                selectedMarker = marker
            }
            return marker
        }
        //isMarkerWillRedrawing = true
        //delete choosen chapter category
        chapterCategory.removeAll()

    }
    
    func AllMarkerIconReset(){
        markers.removeAll()
        selectedMarker = nil
        //5 delete selected image on marker
        //  this will delete selectedMaker on GoogleMap
        //selectedMarker = nil
        
        //6 redraw all the marker image
        //  and set the new marker image  on the property
        //  this will update all marker image on google map with correct order autometically
        //isMarkerWillRedrawing = true
        markers =  chapters.enumerated().map{ (index ,chapter) -> GMSMarker in
            let marker =  GMSMarker(position: chapter.place.coordinate)
            marker.title = chapter.place.name
            marker.icon = UIImage(systemName: "\(index+1).circle.fill")?
                .resize(maxWidthHeight: 35)?
                .maskWithColor(color: .red)
            return marker
        }

        if markers.count > 0 {
            selectedMarker = markers[0]
        }
    }

    
    
    //    func  saveNewStory(){
    //        //check the validate of Data for Activity/ duration /type /location
    //        do{
    //            let newStory  = StoryEntity(context: manager.context)
    //            ApplyStoryToCoreData(storyEntity: newStory)
    //        }catch{
    //            print("there is error \(error.localizedDescription)")
    ////            isShowErrorMessage = true
    ////            errorMessage = error.localizedDescription
    //        }
    //
    //
    //    }
    
    
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
        
        
        //save  Chapter and place with replationship
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
        let placeEntityArray =  chapters.enumerated().map{ (index , chapter) -> PlaceEntity  in
            let newPlace = PlaceEntity(context: manager.context)
            //            guard let place = atGooglePlace.googlePlace else {
            //                print("place info is not able to get so will not stored in coredata")
            //                return newLocation
            //            }
                  
            var googleMapAPIPlace = chapter.place
            
            newPlace.id = UUID().uuidString
            newPlace.youtubeTime = Int16(googleMapAPIPlace.youtubeTime)
            newPlace.name = googleMapAPIPlace.name
            newPlace.placeID = googleMapAPIPlace.placeID ?? "no placeID"
            newPlace.pluscode = googleMapAPIPlace.plusCode
            //newLocation.types  = place.types ?? []
            newPlace.latitude = googleMapAPIPlace.coordinate.latitude ?? 0
            newPlace.longitude = googleMapAPIPlace.coordinate.longitude ??  0
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
    
    private func deleteStory(entity: StoryEntity) {
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
    
}
