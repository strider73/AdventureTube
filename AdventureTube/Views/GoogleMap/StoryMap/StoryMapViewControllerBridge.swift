//
//  StoryMapViewControllerBridge.swift
//  AdventureTube
//
//  Created by chris Lee on 31/8/2022.
//
//https://developers.google.com/codelabs/maps-platform/maps-platform-ios-swiftui#5

import Foundation
import SwiftUI
import GoogleMaps

struct StoryMapViewControllerBridge : UIViewControllerRepresentable{
    //    @Binding  var confirmedMarker:[GMSMarker]
    //    @Binding  var selectedMarker: GMSMarker?
    @Binding  var markers:[GMSMarker]
    //   @Binding  var centerPoint: CLLocationCoordinate2D
    //    var getCenterPointOnMap : (CLLocationCoordinate2D) -> Void
    var getBoxPointOnMap : (CLLocationCoordinate2D,CLLocationCoordinate2D) -> Void
    //var getBoxPointOnMap : (CLLocationCoordinate2D) -> Void
    func makeUIViewController(context: Context) ->  StoryMapViewController {
        let uiViewController = StoryMapViewController()
        uiViewController.mapView.delegate = context.coordinator
        uiViewController.mapView.clear()
        
        return uiViewController
    }
    
    
    func updateUIViewController(_ uiViewController: StoryMapViewController, context: Context) {
        //in here need to delete the mark outside screeb
        uiViewController.mapView.clear()
        
        markers.forEach { marker in
            print("markers.forEach  in update method ==========>")
            marker.map = uiViewController.mapView
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
            
            print(" centerPoint         \(centerCoordinate.longitude),\(centerCoordinate.latitude)")
            print("  [\(southWestCoordinate.longitude),\(southWestCoordinate.latitude)],")
            print("  [\(northEastCoordinate.longitude),\(northEastCoordinate.latitude)]")
            
            //storyMapViewControllerBridge.getCenterPointOnMap(centerCoordinate)
            storyMapViewControllerBridge.getBoxPointOnMap(southWestCoordinate,northEastCoordinate)
            //storyMapViewControllerBridge.getBoxPointOnMap(centerCoordinate)
            
            
            
        }
        
    }
}
