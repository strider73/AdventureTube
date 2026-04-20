//
//  AddStoryViewVM+JSON.swift
//  AdventureTube
//
//  Created by chris Lee on 29/3/22.
//

import Foundation
import CoreLocation

extension AddStoryViewVM {

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

        //4) remove duplicate
        let uniqueCategories =  categroies.removingDuplicates()
        let uniquePlaces = places.removingDuplicates()

        //5) set a adventureTubData
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
}

struct ResponseMessage:Codable{
    var timestamp:String
    var message:String
    var contentId:String
    var contentTitle:String
}
