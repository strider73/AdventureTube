//
//  StoryEntity+CoreDataProperties.swift
//  AdventureTube
//
//  Created by chris Lee on 31/8/2022.
//
//

import Foundation
import CoreData


extension StoryEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoryEntity> {
        return NSFetchRequest<StoryEntity>(entityName: "StoryEntity")
    }

    @NSManaged public var gpsData: Date?
    @NSManaged public var id: String
    @NSManaged public var userContentType: String
    @NSManaged public var userTripDuration: String
    @NSManaged public var youtubeDefaultThumbnailURL: String?
    @NSManaged public var youtubeDescription: String?
    @NSManaged public var youtubehighThumbnailURL: String?
    @NSManaged public var youtubeId: String
    @NSManaged public var youtubeMaxresThumbnailURL: String?
    @NSManaged public var youtubeMediumThumbnailURL: String?
    @NSManaged public var youtubePublishedAt: String?
    @NSManaged public var youtubeStandardThumbnailURL: String?
    @NSManaged public var youtubeTitle: String
    @NSManaged public var isPublished: Bool
    @NSManaged public var chapters: NSOrderedSet
    @NSManaged public var places: NSSet

}

// MARK: Generated accessors for chapters
extension StoryEntity {

    @objc(insertObject:inChaptersAtIndex:)
    @NSManaged public func insertIntoChapters(_ value: ChapterEntity, at idx: Int)

    @objc(removeObjectFromChaptersAtIndex:)
    @NSManaged public func removeFromChapters(at idx: Int)

    @objc(insertChapters:atIndexes:)
    @NSManaged public func insertIntoChapters(_ values: [ChapterEntity], at indexes: NSIndexSet)

    @objc(removeChaptersAtIndexes:)
    @NSManaged public func removeFromChapters(at indexes: NSIndexSet)

    @objc(replaceObjectInChaptersAtIndex:withObject:)
    @NSManaged public func replaceChapters(at idx: Int, with value: ChapterEntity)

    @objc(replaceChaptersAtIndexes:withChapters:)
    @NSManaged public func replaceChapters(at indexes: NSIndexSet, with values: [ChapterEntity])

    @objc(addChaptersObject:)
    @NSManaged public func addToChapters(_ value: ChapterEntity)

    @objc(removeChaptersObject:)
    @NSManaged public func removeFromChapters(_ value: ChapterEntity)

    @objc(addChapters:)
    @NSManaged public func addToChapters(_ values: NSOrderedSet)

    @objc(removeChapters:)
    @NSManaged public func removeFromChapters(_ values: NSOrderedSet)

}

// MARK: Generated accessors for places
extension StoryEntity {

    @objc(addPlacesObject:)
    @NSManaged public func addToPlaces(_ value: PlaceEntity)

    @objc(removePlacesObject:)
    @NSManaged public func removeFromPlaces(_ value: PlaceEntity)

    @objc(addPlaces:)
    @NSManaged public func addToPlaces(_ values: NSSet)

    @objc(removePlaces:)
    @NSManaged public func removeFromPlaces(_ values: NSSet)

}

extension StoryEntity : Identifiable {

}
