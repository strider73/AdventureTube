//
//  StoryDTO.swift
//  AdventureTube
//
//  Created by chris Lee on 19/1/2026.
//  Data Transfer Objects for syncing stories and moments to backend
//

import Foundation

// MARK: - Data Transfer Objects (DTOs)

/// DTO for sending Place (Moment) data to backend
struct PlaceDTO: Codable {
    let id: String
    let placeID: String
    let name: String
    let latitude: Double
    let longitude: Double
    let rating: Double
    let types: [String]
    let placeCategory: [String]
    let pluscode: String?
    let website: String?
    let youtubeId: String
    let youtubeTime: Int
    let photoBase64: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case placeID = "placeId"
        case name
        case latitude
        case longitude
        case rating
        case types
        case placeCategory
        case pluscode
        case website
        case youtubeId
        case youtubeTime
        case photoBase64
    }
}

/// DTO for sending Chapter data to backend
struct ChapterDTO: Codable {
    let id: String?
    let title: String?
    let startTime: Int?
    let endTime: Int?
    let places: [PlaceDTO]
}

/// DTO for sending Story data to backend
struct StoryDTO: Codable {
    let id: String
    let youtubeId: String
    let youtubeTitle: String
    let youtubeDescription: String?
    let userContentType: String
    let userTripDuration: String
    let youtubePublishedAt: String?
    let isPublished: Bool
    let youtubeDefaultThumbnailURL: String?
    let youtubeMediumThumbnailURL: String?
    let youtubehighThumbnailURL: String?
    let youtubeStandardThumbnailURL: String?
    let youtubeMaxresThumbnailURL: String?
    let chapters: [ChapterDTO]
    
    enum CodingKeys: String, CodingKey {
        case id
        case youtubeId
        case youtubeTitle
        case youtubeDescription
        case userContentType
        case userTripDuration
        case youtubePublishedAt
        case isPublished
        case youtubeDefaultThumbnailURL = "thumbnails"
        case youtubeMediumThumbnailURL
        case youtubehighThumbnailURL
        case youtubeStandardThumbnailURL
        case youtubeMaxresThumbnailURL
        case chapters
    }
}

// MARK: - API Response Models

/// Response when creating or updating a story
struct StoryResponse: Codable {
    let storyId: String
    let message: String?
    let syncedAt: String?
    let conflictingPlaces: [String]?
}

/// Response when syncing moments
struct MomentSyncResponse: Codable {
    let syncedCount: Int
    let failedCount: Int
    let message: String?
    let failedMoments: [String]?
}

// MARK: - Extensions to convert CoreData entities to DTOs

extension PlaceEntity {
    func toDTO() -> PlaceDTO {
        return PlaceDTO(
            id: self.id,
            placeID: self.placeID,
            name: self.name,
            latitude: self.latitude,
            longitude: self.longitude,
            rating: self.rating,
            types: self.types,
            placeCategory: self.placeCategory,
            pluscode: self.pluscode,
            website: self.website?.absoluteString,
            youtubeId: self.youtubeId,
            youtubeTime: Int(self.youtubeTime),
            photoBase64: self.photo?.base64EncodedString()
        )
    }
}

extension ChapterEntity {
    func toDTO() -> ChapterDTO {
        // ChapterEntity has a to-one 'place' relationship
        let placeDTOs = [self.place.toDTO()]

        return ChapterDTO(
            id: self.id,
            title: self.category.first,
            startTime: Int(self.youtubeTime),
            endTime: nil,
            places: placeDTOs
        )
    }
}

extension StoryEntity {
    func toDTO() -> StoryDTO {
        // Convert chapters ordered set to array
        let chaptersArray = self.chapters.array as? [ChapterEntity] ?? []
        let chapterDTOs = chaptersArray.map { $0.toDTO() }
        
        return StoryDTO(
            id: self.id,
            youtubeId: self.youtubeId,
            youtubeTitle: self.youtubeTitle,
            youtubeDescription: self.youtubeDescription,
            userContentType: self.userContentType,
            userTripDuration: self.userTripDuration,
            youtubePublishedAt: self.youtubePublishedAt,
            isPublished: self.isPublished,
            youtubeDefaultThumbnailURL: self.youtubeDefaultThumbnailURL,
            youtubeMediumThumbnailURL: self.youtubeMediumThumbnailURL,
            youtubehighThumbnailURL: self.youtubehighThumbnailURL,
            youtubeStandardThumbnailURL: self.youtubeStandardThumbnailURL,
            youtubeMaxresThumbnailURL: self.youtubeMaxresThumbnailURL,
            chapters: chapterDTOs
        )
    }
}
