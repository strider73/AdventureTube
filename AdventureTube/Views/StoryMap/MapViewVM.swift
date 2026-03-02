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

//Tonight I will bring the  data here

class MapViewVM : ObservableObject {

    //here is the the very first place that initialize googleMap and Place API Service using a API_KEY !!!!
    private let googleMapAPIService  = GoogleMapAndPlaceAPIService()

    private var apiService = AdventureTubeAPIService.shared
    private var cancellables = Set<AnyCancellable>()

    @Published var errorMessage: String?
    @Published var selectedVideoID: String? = nil

    /*   Power of Published
     1) Data for markers will be received from apiService and packed as an array of AdventureTubeData.
     2) Marker data will be passed to StoryMapViewControllerBridge.
     Not in makeUIViewController, but in updateUIViewController.

     Since the response is not immediate, the markers won't be able to set when makeUIViewController is called!
     However, it will be updated by updateUIViewController because
     the markers here are @Published, which will notify markers in StoryMapViewControllerBridge,
     and that will be the reason to call updateUIViewController.
     */
    @Published var markers :[GMSMarker] = []

    /// Fetch geo data from backend and create one marker per story with YouTube thumbnail icons
    func fetchGeoData() {
        apiService.fetchGeoData()
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                    print("Failed to fetch geo data: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] adventureDataList in
                guard let self = self else { return }
                print("Received \(adventureDataList.count) adventure stories")

                // Create one marker per story using the first place's coordinates
                self.markers = adventureDataList.compactMap { story -> GMSMarker? in
                    // Find the first place with valid GeoJSON coordinates
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

                    // Store youtubeContentID for marker tap handling
                    marker.userData = story.youtubeContentID

                    // Set category-based border color
                    let borderColor = MarkerIconGenerator.color(for: story.userContentCategory)

                    // Set placeholder icon immediately
                    marker.icon = MarkerIconGenerator.placeholderMarkerIcon(borderColor: borderColor)
                    // Anchor at the bottom center of the pin pointer
                    marker.groundAnchor = CGPoint(x: 0.5, y: 1.0)

                    // Asynchronously load YouTube thumbnail and update marker icon
                    let thumbnailURLString = "https://img.youtube.com/vi/\(story.youtubeContentID)/default.jpg"
                    if let thumbnailURL = URL(string: thumbnailURLString) {
                        MarkerIconGenerator.generateMarkerIcon(
                            thumbnailURL: thumbnailURL,
                            borderColor: borderColor
                        ) { [weak self] icon in
                            guard self != nil, let icon = icon else { return }
                            marker.icon = icon
                            marker.groundAnchor = CGPoint(x: 0.5, y: 1.0)
                        }
                    }

                    return marker
                }
                print("Created \(self.markers.count) markers")
            })
            .store(in: &cancellables)
    }
}
