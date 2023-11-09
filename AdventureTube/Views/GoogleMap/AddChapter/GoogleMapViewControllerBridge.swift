//https://developers.google.com/codelabs/maps-platform/maps-platform-ios-swiftui#5
//  YoutubePopUpMapViewControllerBridge.swift
//  AdventureTube
//
//  Created by chris Lee on 31/5/22.
//

import Foundation
import GoogleMaps
import SwiftUI

struct GoogleMapViewControllerBridge: UIViewControllerRepresentable {
    
    //These values are updated by user's action in google mapView 
    //and apply back to createChapterViewVM since it's bined and
    //specially confirmedMarker will be subscribe by AddStoryViewVM will also update addStoryView
    @Binding  var confirmedMarker:[GMSMarker]
    @Binding  var selectedMarker: GMSMarker?
    @Binding  var isMarkerWillRedrawing : Bool
    @Binding  var isGoogleMapSheetMode : Bool
    
    var getPlaceFromTapOnMap :(GMSMarker,String)  ->()
    
    // this mathod is called by switfui to create underying UViewController.
    // This is where you would instantiate your UIVeiwController and pass it its initiate state.
    func makeUIViewController(context: Context) -> GoogleMapViewController {
        print("GoogleMapViewControllerBridge.makeUIViewController has been called")
        
        // initiate UIViewController
        let uiViewController = GoogleMapViewController()
        
        //Set the YoutubePopUpMapViewCoordinator as the map view's delegate
        uiViewController.mapView.delegate = context.coordinator
        uiViewController.mapView.clear()
        
        //update the map for each marker
        confirmedMarker.forEach{  marker in
            marker.map = uiViewController.mapView
            print("marker name : \(marker.title)")
        }
        selectedMarker?.map = uiViewController.mapView
        animateToSelectedMarker(viewController: uiViewController)
        return uiViewController
        
    }
    /*
     this method is called by SwiftUI whenever state of  changes.
     This is where you would make any modifications to the underlying UIViewController to react
     in response to the state change.
     */
    func updateUIViewController(_ uiViewController: GoogleMapViewController, context: Context) {
        print("GoogleMapViewControllerBridge.updateUIViewController has been called")
        //without this all method below will be excuted every time
        //when  youtubePopView receive update ex) current time in every sec from YoutubePopVM
        //        if uiViewController.mapView.selectedMarker != selectedMarker{
        if isMarkerWillRedrawing || isGoogleMapSheetMode {
            uiViewController.mapView.clear()
            //update the map for each marker
            confirmedMarker.forEach{  marker in
                marker.map = uiViewController.mapView
                print("GoogleMapViewControllerBridge.updateUIViewController marker name : \(marker.title)")
            }
            selectedMarker?.map = uiViewController.mapView
            animateToSelectedMarker(viewController: uiViewController)
            isMarkerWillRedrawing = false
            
        }
    }
    
    
    private func animateToSelectedMarker(viewController:GoogleMapViewController){
        guard let selectedMarker = selectedMarker else {
            return
        }
        let map = viewController.mapView
        map.selectedMarker = selectedMarker
        DispatchQueue.main.asyncAfter(deadline: .now()){
            map.animate(toZoom: 14)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                map.animate(with: GMSCameraUpdate.setTarget(selectedMarker.position))
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    map.animate(toZoom: 16)
                }
            }
        }
    }
    
    
    func makeCoordinator() -> YoutubePopUpMapViewCoordinator {
        return YoutubePopUpMapViewCoordinator(self)
    }
    
    ///This coordinatior allow ControllerBridge class response to Delegate method
    ///https://developers.google.com/maps/documentation/ios-sdk/reference/protocol_g_m_s_map_view_delegate-p
    final class YoutubePopUpMapViewCoordinator : NSObject, GMSMapViewDelegate{
        var googleMapViewControllerBridge : GoogleMapViewControllerBridge
        init(_ atMapViewControllerBridge: GoogleMapViewControllerBridge){
            self.googleMapViewControllerBridge = atMapViewControllerBridge
        }
        
        
        //https://developers.google.com/maps/documentation/ios-sdk/reference/protocol_g_m_s_map_view_delegate-p
        //GMSMapViewDelegate will be here !!! and
        func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
            print("mapView(_ mapView: GMSMapView, willMove gesture: Bool) ")
            //self.youtubePopUpMapViewControllerBridge.mapViewWillMove(gesture)
            
            
            let centerCoordinate = mapView.projection.coordinate(for: mapView.center)
            let northWestCoordinate =  mapView.projection.coordinate(for: CGPoint(x: 0, y: 0))
            let southEastCoordinate =  mapView.projection.coordinate(for:  CGPoint(x:mapView.bounds.maxX, y: mapView.bounds.maxY))

            print(" centerPoint         \(centerCoordinate.latitude),\(centerCoordinate.longitude)")
            print(" northWestCoordinate \(northWestCoordinate.latitude),\(northWestCoordinate.longitude)")
            print(" southEastCoordinate \(southEastCoordinate.latitude),\(northWestCoordinate.longitude)")

        }
        
        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            print("You tapped marker of  \(marker.description)")
            return true
        }
        
        func mapView(_ mapView: GMSMapView,
                     didTapPOIWithPlaceID placeID: String,
                     name: String,
                     location: CLLocationCoordinate2D) {
            print("You tapped at \(name ) of place Id ")
            
            //setCandidateLocationByTap
            let  newMaker = GMSMarker(position: location)
            newMaker.title = name
            //This will  create big Cicle of method call
            //Step 1 create new mark and call the selectLocation closure  from AddStoryMapViewContollerBridge
            //Step 2 newMaker will be retured to AddStoryMapView
            //Step 3 addStoryMapViewVM.selectLocationByTappin will be called and set the selectedMarker
            //Step 4 that selectedMaker has been link to selectedMarker in AddStoryMapViewContollerBridge
            //        which will casue to call updateUIViewController again
            googleMapViewControllerBridge.getPlaceFromTapOnMap(newMaker,placeID)
        }
        
    }
}
