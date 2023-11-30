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

//Tonight I will bring the  data here

class MapViewVM : ObservableObject {
    
    private var apiService = AdventureTubeAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var restaurants: [Restaurants] = []
    @Published var errorMessage: String?
    
    func fetchRestaurants() {
        // Replace the endpoint with your actual API endpoint
        let endpoint = "https://localhost:8888/api/v1/restaurants"
        
        apiService.getRestaurantsData(endpoint: endpoint, type: [Restaurants].self)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                switch completion {
                    case .finished:
                        break // Do nothing on success, as you'll handle the values in the receiveValue closure
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] (receivedRestaurants: [Restaurants]) in
                guard let self = self else { return }
                
                // Update the @Published property
                self.restaurants = receivedRestaurants
            })
            .store(in: &cancellables)
    }
}
