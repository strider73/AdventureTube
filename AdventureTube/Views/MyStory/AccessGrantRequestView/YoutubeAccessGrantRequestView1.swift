//
//  YoutubeAccessGrantRequestView.swift
//  AdventureTube
//
//  Created by chris Lee on 18/2/22.
//

import SwiftUI



struct YoutubeAccessGrantRequestView1: View {
    
    @EnvironmentObject private var loginManager : LoginManager
    @State private var isShowingYoutubeGrantRequest = false

    var body: some View {
            ZStack{
                
                ColorConstant.background.color.ignoresSafeArea()
                
                VStack {
                    Image("appIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width:146)
                    //                .offset(y:-240)
                        .padding()
                    Text("Access Your Youtube Channel")
                        .foregroundColor(ColorConstant.foreground.color)
                        .font(.subheadline)
                        .fontWeight(.bold)
                    
                    Text("Do you have  youtube channel ?               you want to put your story on our map ?")
                        .foregroundColor(ColorConstant.foreground.color)
                        .frame(width: 317, height: 105)
                        .font(.body)
                        .multilineTextAlignment(.center)
                    
                    Image("youtubeAccessGrantRequestImage1")
                        .resizable()
                        .frame(width: 255, height: 168)
                    
                    Button(action: {
                        print("continune has been pushed")
                    }) {
                        NavigationLink(destination:
                                        YoutubeAccessGrantRequestView2()
                                        .navigationBarHidden(true)

                        ) {
                            Text("Continue")
                                .font(.headline)
                                .withDefaultButtonFormatting()

                        }

                    }
                    .withPressableStyle(scaledAmount: 0.9)
                    .padding(40)
                    
//                    Button(action: {
//                        isShowingYoutubeGrantRequest.toggle()
//                    }) {
//                        Text("Continue")
//                            .font(.headline)
//                            .withDefaultButtonFormatting()
//                    }
//                    .withPressableStyle(scaledAmount: 0.9)
//                    .padding(40)
//                    .fullScreenCover(isPresented: $isShowingYoutubeGrantRequest) {
//                        YoutubeAccessGrantRequestView2()
//                    }
                    
                }

        }
        
    }
    
}

struct YoutubeAccessGrantRequestView1_Previews: PreviewProvider {
    static var previews: some View {
        YoutubeAccessGrantRequestView1()
    }
}
