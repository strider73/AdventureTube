//
//  GoogleMapViewController.swift
//  AdventureTube
//
//  Created by chris Lee on 8/7/2022.
//
/*
 Google Map Service
 
 1) need to use API key for Place SDK
 https://developers.google.com/maps/documentation/places/ios-sdk/get-api-key
 */

import GoogleMaps
import SwiftUI
import UIKit
import CoreLocation

class GoogleMapViewForCreateStoryController:UIViewController{
    
    var mapView : GMSMapView = GMSMapView(frame: .zero)
    var isAnimating: Bool = true
    var locationManager = LocationManager()
    
    override func loadView() {
        super.loadView()
        
        mapView.mapType = .terrain
        mapView.isMyLocationEnabled = true
        
        if mapView.selectedMarker == nil{
            locationManager.requestLocation {[weak self] location in
                guard let self = self else{return}
                self.mapView.camera = GMSCameraPosition(latitude:location.latitude, longitude: location.longitude, zoom: 8)
            }
        }
        self.view = mapView
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
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
