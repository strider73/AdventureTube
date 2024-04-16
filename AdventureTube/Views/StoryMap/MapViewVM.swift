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
    
    //here is the the very first place that initialize googleMap and Place API Service using a API_KEY !!!!
    private let googleMapAPIService  = GoogleMapAndPlaceAPIService()
    
    private var adventureTubeApiService = AdventureTubeAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    //    @Published var restaurants: [Restaurants] = []{
    //        didSet{
    //            markers = restaurants.map{ restaurant -> GMSMarker in
    //                let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: restaurant.location.coordinates[1], longitude: restaurant.location.coordinates[0]))
    //                marker.title = restaurant.name
    //                return marker
    //            }
    //        }
    //    }
    @Published var errorMessage: String?
    
    /*   Power of Published
     1) Data for markers will be received from apiService.getData and packed as an array of Restaurant.
     2) Marker data will be passed to StoryMapViewControllerBridge.
     Not in makeUIViewController, but in updateUIViewController.
     
     Since the response is not immediate, the markers won't be able to set when makeUIViewController is called!
     However, it will be updated by updateUIViewController because
     the markers here are @Published, which will notify markers in StoryMapViewControllerBridge,
     and that will be the reason to call updateUIViewController.
     */
    @Published var markers :[GMSMarker] = []
    
    var centerPoint : CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 40.82302903, longitude: -73.93414657){
        didSet{
            print("center point has been updated")
            fetchRestaurants()
        }
    }
    
    var southWestCoordinate : CLLocationCoordinate2D = CLLocationCoordinate2D()
    var northEastCoordinate : CLLocationCoordinate2D = CLLocationCoordinate2D(){
        didSet{
            fetchRestaurants()
        }
    }
    
    var locationManager = LocationManager2()
    init(){
        locationManager.requestLocation{[weak self] location in
            guard let self = self else{return}
            self.centerPoint = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        }
    }
    
    //Search area is circle base on center point
//    func generateEndpoint( maxDistance: Double = 2) -> String {
//        return "http://192.168.1.106:8888/api/v1/restaurants/near?longitude=\(centerPoint.latitude)&latitude=\(centerPoint.latitude)&maxDistance=\(maxDistance)"    }
    
    //Search area is square base on two edge position 
    func generateEndpoint2( maxDistance: Double = 0.2) -> String {
        return "\(APIService.rasberryTestServer.address)/restaurants/locations-in-bounding-box?swLon=\(southWestCoordinate.longitude)&swLat=\(southWestCoordinate.latitude)&neLon=\(northEastCoordinate.longitude)&neLat=\(northEastCoordinate.latitude)"
    }
    
    
    func fetchRestaurants() {
        // Replace the endpoint with your actual API endpoint
        let endpoint = generateEndpoint2()
  
        
        //validate end point and return here if fail
        
        
        adventureTubeApiService.getData(endpoint: endpoint, type: [Restaurant].self)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                switch completion {
                    case .finished:
                        break // Do nothing on success, as you'll handle the values in the receiveValue closure
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] (receivedRestaurants: [Restaurant]) in
                guard let self = self else { return }
                
                print("getting data now ===========>")
                // Update the @Published property
                //self.restaurants = receivedRestaurants
                markers = receivedRestaurants.map{ restaurant -> GMSMarker in
                    let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: restaurant.location.coordinates[1], longitude: restaurant.location.coordinates[0]))
                    marker.title = restaurant.name
                    marker.appearAnimation = GMSMarkerAnimation.fadeIn
                    return marker
                }
            })
            .store(in: &cancellables)
    }
}


class LocationManager2: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    var completion  : ((CLLocationCoordinate2D) -> Void)?
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func requestLocation(completion:@escaping (CLLocationCoordinate2D) -> Void) {
        manager.requestLocation()
        self.completion = completion
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error:: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first ,
              let completion = completion else {return}
        completion(location.coordinate)
    }
}
