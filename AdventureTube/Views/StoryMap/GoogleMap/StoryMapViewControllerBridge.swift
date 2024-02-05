//
//  StoryMapViewControllerBridge.swift
//  AdventureTube
//
//  Created by chris Lee on 31/8/2022.
//
// https://developers.google.com/codelabs/maps-platform/maps-platform-ios-swiftui#5
// in here set the delegation of   "var mapView : GMSMapView = GMSMapView(frame: .zero)"
// by  return StoryMapViewControllerBridgeCoordinator(self)
// without implement GMSMapViewDelegate  inside  "StoryMapViewController"

import Foundation
import SwiftUI
import GoogleMaps
import GoogleMapsUtils


/*
 
 in this struct all the member valueable is immutable and why ?
 
 
 
 
 */

struct StoryMapViewControllerBridge : UIViewControllerRepresentable{
    
    @Binding  var markers:[GMSMarker]
    var getBoxPointOnMap : (CLLocationCoordinate2D,CLLocationCoordinate2D) -> Void
    var markerCountLimitforClsuter = 200
    var markkerZoomLimitForCluster : Float = 14.0
    
    func makeUIViewController(context: Context) ->  StoryMapViewController {
        let uiViewController = StoryMapViewController()
        uiViewController.mapView.delegate = context.coordinator
        uiViewController.mapView.clear()
        
        return uiViewController
    }
    
    
    func updateUIViewController(_ uiViewController: StoryMapViewController, context: Context) {
        //in here need to delete the mark outside screeb
        uiViewController.mapView.clear()
        uiViewController.clusterManager.clearItems()
        
        print("Zoom is \(uiViewController.mapView.camera.zoom)")
        
        if  markers.count  < markerCountLimitforClsuter  {
            print("No Cluster markers.count  \(markers.count)")
            markers.forEach { marker in
                marker.map = uiViewController.mapView
            }
        }else{
            print("With Cluster markers.count  \(markers.count)")

            uiViewController.clusterManager.add(markers)
            uiViewController.clusterManager.cluster()
        }
        
        
    }
    
    
    //    private func animateToSelectedMarker(viewController:StoryMapViewController){
    //        guard let selectedMarker = selectedMarker else {
    //            return
    //        }
    //        let map = viewController.mapView
    //        map.selectedMarker = selectedMarker
    //        DispatchQueue.main.asyncAfter(deadline: .now()){
    //            map.animate(toZoom: 14)
    //            DispatchQueue.main.asyncAfter(deadline: .now() + 1){
    //                map.animate(with: GMSCameraUpdate.setTarget(selectedMarker.position))
    //                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
    //                    map.animate(toZoom: 16)
    //                }
    //            }
    //        }
    //    }
    
    //This is where delegation has been set which is self ATM
    func makeCoordinator() -> StoryMapViewControllerBridgeCoordinator {
        return StoryMapViewControllerBridgeCoordinator(self)
    }
    
    final class StoryMapViewControllerBridgeCoordinator: NSObject,GMSMapViewDelegate{
        var storyMapViewControllerBridge : StoryMapViewControllerBridge
        init(_ storyMapViewControllerBridge: StoryMapViewControllerBridge) {
            self.storyMapViewControllerBridge = storyMapViewControllerBridge
        }
        
        
        //https://developers.google.com/maps/documentation/ios-sdk/reference/protocol_g_m_s_map_view_delegate-p
        //GMSMapViewDelegate
        func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
            //clear the mapView
            //mapView.clear()
        }
        
        func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
            let centerCoordinate = mapView.projection.coordinate(for: mapView.center)
            let southWestCoordinate =  mapView.projection.coordinate(for:  CGPoint(x:0, y: mapView.bounds.maxY))
            let northEastCoordinate =  mapView.projection.coordinate(for: CGPoint(x: mapView.bounds.maxX, y: 0))
            
            storyMapViewControllerBridge.getBoxPointOnMap(southWestCoordinate,northEastCoordinate)
        }
        
        
        
        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            
            // center the map on tapped marker
            mapView.animate(toLocation: marker.position)
            // check if a cluster icon was tapped
            if marker.userData is GMUCluster {
                // zoom in on tapped cluster                
                mapView.animate(toZoom: 17)
                NSLog("Did tap cluster")
                return true
            }
            
            NSLog("Did tap a normal marker")
            return false
        }
    }
}
