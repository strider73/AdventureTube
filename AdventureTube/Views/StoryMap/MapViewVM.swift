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

class MapViewVM : ObservableObject {

    private let googleMapAPIService  = GoogleMapAndPlaceAPIService()

    private var apiService = AdventureTubeAPIService.shared
    private var cancellables = Set<AnyCancellable>()

    @Published var errorMessage: String?
    @Published var selectedVideoID: String? = nil
    @Published var markers: [GMSMarker] = []

    /// Track which stories are already on the map to avoid duplicates
    private var loadedStoryIDs = Set<String>()

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

    /// Clear all markers and reset tracking
    func clearMarkers() {
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

            // Track new story IDs
            for story in newStories {
                self.loadedStoryIDs.insert(story.youtubeContentID)
            }

            // Append new markers with staggered pop-in animation
            for (index, marker) in newMarkers.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                    self.markers.append(marker)
                }
            }
        })
        .store(in: &cancellables)
    }

    /// Create GMSMarker array from story data
    private func createMarkers(from adventureDataList: [AdventureTubeData]) -> [GMSMarker] {
        return adventureDataList.compactMap { story -> GMSMarker? in
            guard let firstPlace = story.places.first(where: { place in
                guard let geoJson = place.location else { return false }
                return geoJson.coordinates.count >= 2
            }), let geoJson = firstPlace.location else {
                return nil
            }

            let marker = GMSMarker(position: CLLocationCoordinate2D(
                latitude: geoJson.coordinates[1],
                longitude: geoJson.coordinates[0]
            ))
            marker.title = story.youtubeTitle
            marker.snippet = firstPlace.name
            marker.appearAnimation = GMSMarkerAnimation.fadeIn

            marker.userData = story.youtubeContentID

            let borderColor = MarkerIconGenerator.color(for: story.userContentCategory)

            marker.icon = MarkerIconGenerator.placeholderMarkerIcon(borderColor: borderColor)
            marker.groundAnchor = CGPoint(x: 0.5, y: 1.0)

            let thumbnailURLString = "https://img.youtube.com/vi/\(story.youtubeContentID)/default.jpg"
            if let thumbnailURL = URL(string: thumbnailURLString) {
                MarkerIconGenerator.generateMarkerIcon(
                    thumbnailURL: thumbnailURL,
                    borderColor: borderColor
                ) { icon in
                    guard let icon = icon else { return }
                    marker.icon = icon
                    marker.groundAnchor = CGPoint(x: 0.5, y: 1.0)
                }
            }

            return marker
        }
    }
}
