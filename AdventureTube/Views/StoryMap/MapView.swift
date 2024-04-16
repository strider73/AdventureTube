//
//  MapView.swift
//  AdventureTube
//
//  Created by chris Lee on 14/2/22.
//

import SwiftUI

struct MapView: View {
    
    @StateObject var mapViewVM : MapViewVM = MapViewVM()
    
    init(){
        print("Init MapView ")
    }
    var body: some View {
        NavigationView{
            ZStack {
                storyMap
                VStack{
                    Text("MapView")
                        .foregroundColor(Color.black)
                    //from here will be the mark on top of map
                }
            }
            .preferredColorScheme(.light)
            .navigationBarHidden(true)
        }.onAppear{
            mapViewVM.fetchRestaurants()
        }
    }
        
    
    
    
    var storyMap:some View{
            StoryMapViewControllerBridge(markers: mapViewVM.markers){southWestCoordinate,northEastCoordinate in
                mapViewVM.southWestCoordinate = southWestCoordinate
                mapViewVM.northEastCoordinate = northEastCoordinate
            }
//        StoryMapViewControllerBridge(markers: $mapViewVM.markers){centerPoint in
//            mapViewVM.centerPoint = centerPoint
//        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
