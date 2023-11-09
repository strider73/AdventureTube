//
//  PlaceEntity+CoreDataProperties.swift
//  AdventureTube
//
//  Created by chris Lee on 31/8/2022.
//
//

import Foundation
import CoreData


extension PlaceEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlaceEntity> {
        return NSFetchRequest<PlaceEntity>(entityName: "PlaceEntity")
    }

    @NSManaged public var id: String
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var name: String
    @NSManaged public var photo: Data?
    @NSManaged public var placeCategory: [String]
    @NSManaged public var placeID: String
    @NSManaged public var pluscode: String?
    @NSManaged public var rating: Double
    @NSManaged public var types: [String]
    @NSManaged public var website: URL?
    @NSManaged public var youtubeId: String
    @NSManaged public var youtubeTime: Int16
    @NSManaged public var chapter: ChapterEntity
    @NSManaged public var story: StoryEntity

}

extension PlaceEntity : Identifiable {

}
