//
//  AddStoryViewVM+CoreData.swift
//  AdventureTube
//
//  Created by chris Lee on 29/3/22.
//

import Foundation
import CoreData

extension AddStoryViewVM {

    func initStoryEntity() {
        let reqeust = NSFetchRequest<StoryEntity>(entityName:"StoryEntity")
        let filter = NSPredicate(format: "youtubeId == %@", youtubeContentItem.contentDetails.videoId)
        reqeust.predicate = filter


        do{
            let stories = try manager.context.fetch(reqeust)
            if stories.count > 0{
                storyEntity = stories.first
                createChapterViewVM.storyEntity = stories.first
                isStoryPublished = stories.first?.isPublished ?? false
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
            newChapter.youtubeId = chapter.youtubeId ?? ""


            //create place for chapter
            let placeOfChapter: AdventureTubePlace = chapter.place
            let newPlace = PlaceEntity(context: manager.context)
            newPlace.id = UUID().uuidString
            newPlace.youtubeTime = Int16(placeOfChapter.youtubeTime)
            newPlace.name = placeOfChapter.name
            newPlace.placeID = placeOfChapter.placeID ?? "no placeID"
            newPlace.pluscode = placeOfChapter.plusCode
            //newLocation.types  = place.types ?? []
            newPlace.latitude = placeOfChapter.coordinate?.latitude ?? 0
            newPlace.longitude = placeOfChapter.coordinate?.longitude ?? 0
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

    func deleteAllChapterAndPlace(){
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

    func deleteStoryEntity(entity: StoryEntity) {
        manager.context.delete(entity)
        save()
    }

    func deleteChapterEntity(entity: ChapterEntity) {
        manager.context.delete(entity)
        save()
    }

    func deletePlaceEntity(entity: PlaceEntity) {
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
