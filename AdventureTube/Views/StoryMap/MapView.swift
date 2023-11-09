//
//  MapView.swift
//  AdventureTube
//
//  Created by chris Lee on 14/2/22.
//

import SwiftUI
import GoogleMaps

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
                }
            }
            .preferredColorScheme(.light)
            .navigationBarHidden(true)
        }
    }
    
    var storyMap:some View{
        StoryMapViewControllerBridge().edgesIgnoringSafeArea(.all)
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
