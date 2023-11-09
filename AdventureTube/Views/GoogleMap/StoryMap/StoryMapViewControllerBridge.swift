//
//  StoryMapViewControllerBridge.swift
//  AdventureTube
//
//  Created by chris Lee on 31/8/2022.
//

import Foundation
import GoogleMaps
import SwiftUI

struct StoryMapViewControllerBridge : UIViewControllerRepresentable{
//    @Binding  var confirmedMarker:[GMSMarker]
//    @Binding  var selectedMarker: GMSMarker?
    func makeUIViewController(context: Context) -> some UIViewController {
        let uiViewController = StoryMapViewController()
        //uiViewController.mapView.delegate = context.coordinator
        uiViewController.mapView.clear()
        
//        confirmedMarker.forEach { marker in
//            marker.map = uiViewController.mapView
//        }
        
//        selectedMarker?.map = uiViewController.mapView
//        animateToSelectedMarker(viewController: uiViewController)
        return uiViewController
    }
    
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        //do your update here 
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
    
//    func makeCoordinator() -> YoutubePopUpMapViewCoordinator {
//        return YoutubePopUpMapViewCoordinator(self)
//    }
}
