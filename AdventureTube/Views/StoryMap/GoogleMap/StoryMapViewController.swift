//
//  StoryMapViewController.swift
//  AdventureTube
//
//  Created by chris Lee on 31/8/2022.
//
//How to set up marker cluster https://developers.google.com/maps/documentation/ios-sdk/utility/marker-clustering
// 1) Create the cluster  manager on StoryMapViewController
//        using  GMUClusterIconGenerator,GMUClusterAlgorithm,GMUClusterRenderer
//
//        setting a map delegate process is not require here since 
//        mapView delegation has been set in StoryMApViewControllerBridge
//        =>   uiViewController.mapView.delegate = context.coordinator
// 2) Addin  Marker in StoryMApVeiwContorllerBridge
// 3) call the maker cluster clusterManager.cluster()



import GoogleMaps
import SwiftUI
import UIKit
import CoreLocation
import GoogleMapsUtils

class StoryMapViewController:UIViewController{
    
    var mapView : GMSMapView = GMSMapView(frame: .zero)
    var isAnimating: Bool = true
    var locationManager = LocationManager()
    var clusterManager:GMUClusterManager!//explicitly unwrraped optional

    override func loadView() {
        super.loadView()
        
        mapView.setMinZoom(8.0, maxZoom: 20)
        mapView.mapType = .terrain
        mapView.isMyLocationEnabled = true
        // Set up the cluster manager with the supplied icon generator and
        // renderer.
        let iconGenerator = GMUDefaultClusterIconGenerator()
        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
        let renderer = GMUDefaultClusterRenderer(mapView: mapView,
                                                 clusterIconGenerator: iconGenerator)
        clusterManager = GMUClusterManager(map:mapView, algorithm: algorithm,
                                                            renderer: renderer)
    
        if mapView.selectedMarker == nil{
            locationManager.requestLocation {[weak self] location in
                guard let self = self else{return}
                self.mapView.camera = GMSCameraPosition(latitude:40.82302903, longitude: -73.93414657, zoom: 16)
            }
        }
        //        if  let myLocation  = mapView.myLocation {
        //            mapView.camera = GMSCameraPosition(latitude:myLocation.coordinate.latitude, longitude: myLocation.coordinate.longitude, zoom: 4)
        //        }
        self.view = mapView
    }
}
