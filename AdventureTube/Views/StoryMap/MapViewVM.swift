//
//  MapViewViewModel.swift
//  AdventureTube
//
//  Created by chris Lee on 4/4/22.
//

import Foundation
import GoogleMaps
import GooglePlaces
import Combine
import UIKit
import CoreLocation

/// Data carried by each chapter marker via GMSMarker.userData
struct ChapterMarkerData {
    let videoID: String
    let videoTitle: String
    let startTime: Int
    let chapterIndex: Int
    let storyID: String
    let categories: [Category]
}

class MapViewVM : ObservableObject {

    private let googleMapAPIService  = GoogleMapAndPlaceAPIService()

    private var apiService = AdventureTubeAPIService.shared
    private var cancellables = Set<AnyCancellable>()

    @Published var errorMessage: String?
    @Published var selectedChapter: ChapterMarkerData? = nil
    @Published var markers: [GMSMarker] = []
    @Published var polylines: [GMSPolyline] = []

    /// Track which stories are already on the map to avoid duplicates
    private var loadedStoryIDs = Set<String>()

    /// Cache downloaded thumbnail images by videoID to avoid duplicate downloads
    private var thumbnailCache = NSCache<NSString, UIImage>()

    /// Debounce subject for bounding box updates — prevents API spam during scroll
    private let boundsSubject = PassthroughSubject<(sw: CLLocationCoordinate2D, ne: CLLocationCoordinate2D), Never>()

    /// Track previous bounds center to detect large jumps
    private var previousCenter: CLLocationCoordinate2D?

    init() {
        boundsSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] bounds in
                self?.fetchGeoDataInBounds(sw: bounds.sw, ne: bounds.ne)
            }
            .store(in: &cancellables)
    }

    /// Called by the map delegate during scroll and on idle
    func onMapBoundsChanged(sw: CLLocationCoordinate2D, ne: CLLocationCoordinate2D) {
        let newCenter = CLLocationCoordinate2D(
            latitude: (sw.latitude + ne.latitude) / 2,
            longitude: (sw.longitude + ne.longitude) / 2
        )

        // Detect large jump (e.g., user searched a new location) — clear and reload
        if let prev = previousCenter {
            let distance = CLLocation(latitude: prev.latitude, longitude: prev.longitude)
                .distance(from: CLLocation(latitude: newCenter.latitude, longitude: newCenter.longitude))
            // If moved more than 500km, treat as a jump — clear everything
            if distance > 500_000 {
                clearMarkers()
            }
        }
        previousCenter = newCenter

        boundsSubject.send((sw: sw, ne: ne))
    }

    /// Clear all markers, polylines, and reset tracking
    func clearMarkers() {
        for polyline in polylines { polyline.map = nil }
        polylines.removeAll()
        markers.removeAll()
        loadedStoryIDs.removeAll()
    }

    /// Fetch geo data within visible map bounds — appends new markers only
    private func fetchGeoDataInBounds(sw: CLLocationCoordinate2D, ne: CLLocationCoordinate2D) {
        apiService.fetchStoryInBounds(
            swLat: sw.latitude, swLng: sw.longitude,
            neLat: ne.latitude, neLng: ne.longitude
        )
        .sink(receiveCompletion: { [weak self] completion in
            guard let self = self else { return }
            if case .failure(let error) = completion {
                self.errorMessage = error.localizedDescription
                print("Failed to fetch geo data: \(error.localizedDescription)")
            }
        }, receiveValue: { [weak self] adventureDataList in
            guard let self = self else { return }

            // Filter out stories already on the map
            let newStories = adventureDataList.filter { !self.loadedStoryIDs.contains($0.youtubeContentID) }

            guard !newStories.isEmpty else { return }

            print("Received \(adventureDataList.count) stories, \(newStories.count) new")

            let newMarkers = self.createMarkers(from: newStories)
            let newPolylines = self.createPolylines(from: newStories)

            // Track new story IDs
            for story in newStories {
                self.loadedStoryIDs.insert(story.youtubeContentID)
            }

            // Append polylines immediately
            self.polylines.append(contentsOf: newPolylines)

            // Append new markers with staggered pop-in animation
            for (index, marker) in newMarkers.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                    self.markers.append(marker)
                }
            }
        })
        .store(in: &cancellables)
    }

    /// Create one GMSMarker per chapter, each at its own place's coordinates
    private func createMarkers(from adventureDataList: [AdventureTubeData]) -> [GMSMarker] {
        var allMarkers: [GMSMarker] = []

        for story in adventureDataList {
            let chapters = story.chapters
            guard !chapters.isEmpty else { continue }

            for (index, chapter) in chapters.enumerated() {
                guard let geoJson = chapter.place.location,
                      geoJson.coordinates.count >= 2 else { continue }

                let marker = GMSMarker(position: CLLocationCoordinate2D(
                    latitude: geoJson.coordinates[1],
                    longitude: geoJson.coordinates[0]
                ))
                marker.title = story.youtubeTitle
                marker.snippet = chapter.place.name
                marker.appearAnimation = GMSMarkerAnimation.fadeIn

                marker.userData = ChapterMarkerData(
                    videoID: story.youtubeContentID,
                    videoTitle: story.youtubeTitle,
                    startTime: chapter.youtubeTime,
                    chapterIndex: index,
                    storyID: story.youtubeContentID,
                    categories: chapter.categories
                )

                let borderColor = MarkerIconGenerator.color(for: chapter.categories)
                marker.icon = MarkerIconGenerator.placeholderMarkerIcon(borderColor: borderColor)
                marker.groundAnchor = CGPoint(x: 0.5, y: 1.0)

                // Load YouTube video thumbnail with chapter number overlay
                let chapterNumber = index + 1
                let cacheKey = story.youtubeContentID as NSString
                if let cachedImage = thumbnailCache.object(forKey: cacheKey) {
                    marker.icon = MarkerIconGenerator.compositeMarkerIcon(
                        thumbnail: cachedImage, borderColor: borderColor,
                        chapterNumber: chapterNumber)
                    marker.groundAnchor = CGPoint(x: 0.5, y: 1.0)
                } else {
                    let thumbnailURLString = "https://img.youtube.com/vi/\(story.youtubeContentID)/default.jpg"
                    if let thumbnailURL = URL(string: thumbnailURLString) {
                        MarkerIconGenerator.generateMarkerIcon(
                            thumbnailURL: thumbnailURL,
                            borderColor: borderColor,
                            chapterNumber: chapterNumber
                        ) { [weak self] icon in
                            guard let icon = icon else { return }
                            marker.icon = icon
                            marker.groundAnchor = CGPoint(x: 0.5, y: 1.0)
                            if let self = self {
                                self.cacheThumbnail(videoID: story.youtubeContentID, url: thumbnailURL)
                            }
                        }
                    }
                }

                allMarkers.append(marker)
            }
        }

        return allMarkers
    }

    /// Cache a downloaded thumbnail image by videoID
    private func cacheThumbnail(videoID: String, url: URL) {
        let cacheKey = videoID as NSString
        guard thumbnailCache.object(forKey: cacheKey) == nil else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            self?.thumbnailCache.setObject(image, forKey: cacheKey)
        }.resume()
    }

    /// Create polylines connecting chapter markers of the same story in order
    private func createPolylines(from adventureDataList: [AdventureTubeData]) -> [GMSPolyline] {
        return adventureDataList.compactMap { story -> GMSPolyline? in
            let validChapters = story.chapters.filter { chapter in
                guard let geo = chapter.place.location else { return false }
                return geo.coordinates.count >= 2
            }
            guard validChapters.count >= 2 else { return nil }

            let path = GMSMutablePath()
            for chapter in validChapters {
                let geo = chapter.place.location!
                path.add(CLLocationCoordinate2D(
                    latitude: geo.coordinates[1],
                    longitude: geo.coordinates[0]
                ))
            }

            let polyline = GMSPolyline(path: path)
            polyline.strokeWidth = 3.0
            polyline.strokeColor = MarkerIconGenerator.color(for: story.userContentCategory)
                .withAlphaComponent(0.7)
            polyline.geodesic = true

            return polyline
        }
    }
}
