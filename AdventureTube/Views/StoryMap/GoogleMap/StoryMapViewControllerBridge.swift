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
    @Binding  var polylines:[GMSPolyline]
    var getBoxPointOnMap : (CLLocationCoordinate2D,CLLocationCoordinate2D) -> Void
    var onMarkerTap: (ChapterMarkerData) -> Void
    var markerCountLimitforClsuter = 200
    var markkerZoomLimitForCluster : Float = 14.0
    
    func makeUIViewController(context: Context) ->  StoryMapViewController {
        let uiViewController = StoryMapViewController()
        uiViewController.mapView.delegate = context.coordinator
        uiViewController.mapView.clear()
        
        return uiViewController
    }
    
    
    func updateUIViewController(_ uiViewController: StoryMapViewController, context: Context) {
        // Only assign map to markers that don't have one yet (new markers)
        let mapView = uiViewController.mapView

        if markers.count < markerCountLimitforClsuter {
            for marker in markers where marker.map == nil {
                marker.map = mapView
            }
        } else {
            // For large counts, use clustering
            uiViewController.clusterManager.clearItems()
            uiViewController.clusterManager.add(markers)
            uiViewController.clusterManager.cluster()
        }

        // Render new polylines
        for polyline in polylines where polyline.map == nil {
            polyline.map = mapView
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
        }

        /// Fires continuously during camera movement — enables reactive loading while scrolling
        func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
            let sw = mapView.projection.coordinate(for: CGPoint(x: 0, y: mapView.bounds.maxY))
            let ne = mapView.projection.coordinate(for: CGPoint(x: mapView.bounds.maxX, y: 0))
            storyMapViewControllerBridge.getBoxPointOnMap(sw, ne)
        }

        /// Fires when camera stops — final fetch for settled area
        func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
            let sw = mapView.projection.coordinate(for: CGPoint(x: 0, y: mapView.bounds.maxY))
            let ne = mapView.projection.coordinate(for: CGPoint(x: mapView.bounds.maxX, y: 0))
            storyMapViewControllerBridge.getBoxPointOnMap(sw, ne)
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

            // Extract chapter data from marker and notify SwiftUI
            if let chapterData = marker.userData as? ChapterMarkerData {
                NSLog("Did tap chapter marker: videoID=\(chapterData.videoID), startTime=\(chapterData.startTime)")
                storyMapViewControllerBridge.onMarkerTap(chapterData)
                return true
            }

            NSLog("Did tap a normal marker")
            return false
        }
    }
}
