//
//  GoogleMapViewController.swift
//  AdventureTube
//
//  Created by chris Lee on 8/7/2022.
//


import GoogleMaps
import SwiftUI
import UIKit
import CoreLocation

class GoogleMapViewController:UIViewController{
    
    var mapView : GMSMapView = GMSMapView(frame: .zero)
    var isAnimating: Bool = true
    var locationManager = LocationManager()
    
    override func loadView() {
        super.loadView()
        
        mapView.mapType = .terrain
        mapView.isMyLocationEnabled = true
        self.mapView.camera = GMSCameraPosition(latitude: 40.82302903, longitude: -73.93414657 ,zoom: 8)
    
        var northWestCoordinate =  self.mapView.projection.coordinate(for: CGPoint(x: 0, y: 0))
        var southEastCoordinate =  self.mapView.projection.coordinate(for:  CGPoint(x:self.mapView.bounds.maxX, y: self.mapView.bounds.maxY))

        
        print("https://www.google.com/maps/@\(northWestCoordinate.latitude),\(northWestCoordinate.longitude)")
        print("https://www.google.com/maps/@\(southEastCoordinate.latitude),\(northWestCoordinate.longitude)")
    
//        if mapView.selectedMarker == nil{
//            locationManager.requestLocation {[weak self] location in
//                guard let self = self else{return}
////                self.mapView.camera = GMSCameraPosition(latitude:location.latitude, longitude: location.longitude, zoom: 8)
//                self.mapView.camera = GMSCameraPosition(latitude: 40.82302903, longitude: -73.93414657 ,zoom: 8)
//
//                var northWestCoordinate =  self.mapView.projection.coordinate(for: CGPoint(x: 0, y: 0))
//                var southEastCoordinate =  self.mapView.projection.coordinate(for:  CGPoint(x:self.mapView.bounds.maxX, y: self.mapView.bounds.maxY))
//
//
//                print("https://www.google.com/maps/@\(northWestCoordinate.latitude),\(northWestCoordinate.longitude)")
//                print("https://www.google.com/maps/@\(southEastCoordinate.latitude),\(northWestCoordinate.longitude)")
//
//
//            }
//        }
        
        
        //        if  let myLocation  = mapView.myLocation {
        //
        //            mapView.camera = GMSCameraPosition(latitude:myLocation.coordinate.latitude, longitude: myLocation.coordinate.longitude, zoom: 4)
        //
        //
        //        }
        
        
        
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
