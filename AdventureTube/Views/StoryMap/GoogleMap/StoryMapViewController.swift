//
//  StoryMapViewController.swift
//  AdventureTube
//
//  Created by chris Lee on 31/8/2022.
//

import GoogleMaps
import SwiftUI
import UIKit
import CoreLocation


class StoryMapViewController:UIViewController{
    
    var mapView : GMSMapView = GMSMapView(frame: .zero)
    var isAnimating: Bool = true
    var locationManager = LocationManager()
    
    override func loadView() {
        super.loadView()
        
        mapView.setMinZoom(8.0, maxZoom: 20)
        mapView.mapType = .terrain
        mapView.isMyLocationEnabled = true
    
        if mapView.selectedMarker == nil{
            locationManager.requestLocation {[weak self] location in
                guard let self = self else{return}
                self.mapView.camera = GMSCameraPosition(latitude:40.82302903, longitude: -73.93414657, zoom: 16)
               
            
                var northWestCoordinate =  self.mapView.projection.coordinate(for: CGPoint(x: 0, y: 0))
                var southEastCoordinate =  self.mapView.projection.coordinate(for:  CGPoint(x:self.mapView.bounds.maxX, y: self.mapView.bounds.maxY))
  
                
//                print("https://www.google.com/maps/@\(northWestCoordinate.latitude),\(northWestCoordinate.longitude)")
//                print("https://www.google.com/maps/@\(southEastCoordinate.latitude),\(northWestCoordinate.longitude)")

          
            }
        }
        
        
        //        if  let myLocation  = mapView.myLocation {
        //
        //            mapView.camera = GMSCameraPosition(latitude:myLocation.coordinate.latitude, longitude: myLocation.coordinate.longitude, zoom: 4)
        //
        //
        //        }
        
        
        
        self.view = mapView
    }
}
