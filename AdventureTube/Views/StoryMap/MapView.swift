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
        }
        .onAppear{
            mapViewVM.fetchGeoData()
        }
        .sheet(isPresented: Binding<Bool>(
            get: { mapViewVM.selectedVideoID != nil },
            set: { if !$0 { mapViewVM.selectedVideoID = nil } }
        )) {
            if let videoID = mapViewVM.selectedVideoID {
                YoutubePopupView(videoID: videoID) {
                    mapViewVM.selectedVideoID = nil
                }
            }
        }
    }

    var storyMap: some View {
        StoryMapViewControllerBridge(
            markers: $mapViewVM.markers,
            getBoxPointOnMap: { _, _ in },
            onMarkerTap: { videoID in
                mapViewVM.selectedVideoID = videoID
            }
        )
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - YouTube Popup View
private struct YoutubePopupView: View {
    let videoID: String
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.edgesIgnoringSafeArea(.all)

            YoutubeView(youtubeViewVM: YoutubeViewVM(videoId: videoID))
                .padding(.top, 60)
                .padding(.bottom, 40)

            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
            }
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
