//
//  ChapterEntity+CoreDataProperties.swift
//  AdventureTube
//
//  Created by chris Lee on 31/8/2022.
//
//

import Foundation
import CoreData


extension ChapterEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChapterEntity> {
        return NSFetchRequest<ChapterEntity>(entityName: "ChapterEntity")
    }

    @NSManaged public var category: [String]
    @NSManaged public var id: String
    @NSManaged public var thumbnail: Data?
    @NSManaged public var youtubeId: String
    @NSManaged public var youtubeTime: Int16
    @NSManaged public var place: PlaceEntity
    @NSManaged public var story: StoryEntity

}

extension ChapterEntity : Identifiable {

}
