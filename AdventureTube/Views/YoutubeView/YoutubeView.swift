//
//  YoutubeView.swift
//  AdventureTube
//
//  Created by chris Lee on 16/5/22.
//


import SwiftUI
import YouTubePlayerKit

struct YoutubeView: View {
    
    
    @ObservedObject var youtubeViewVM : YoutubeViewVM
    
    var body: some View {
        ZStack {
            VStack{
                
//                YouTubePlayerView(
//                    youtubeViewVM.youTubePlayer,
//                    placeholderOverlay: {
//                        ProgressView()
//                    }
//                )
                
                YouTubePlayerView(youtubeViewVM.youTubePlayer) { state in
                    // Overlay ViewBuilder closure to place an overlay View
                    // for the current `YouTubePlayer.State`
                    switch state {
                    case .idle:
                        ProgressView()
                    case .ready:
                        EmptyView()
                            .background(Color.black)
                    case .error(let error):
                        Text(verbatim: "YouTube player couldn't be loaded")
                    }
                }
                .background(Color.black)
                
            }
      

            
        }
    }
    
}

struct YoutubeView_Previews: PreviewProvider {
    static var previews: some View {
        YoutubeView(youtubeViewVM: YoutubeViewVM(videoId: "CCIS3-ohsJE"))
    }
}
