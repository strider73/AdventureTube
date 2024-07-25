//
//  YoutubeAccessGrantRequestView.swift
//  AdventureTube
//
//  Created by chris Lee on 17/2/22.
//

import SwiftUI


struct YoutubeAccessGrantRequestView2: View {
    
    @EnvironmentObject private var loginManager : LoginManager
    @EnvironmentObject var myStoryListVM : MyStoryListViewVM
    
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
                
                Text("We will bring your story down here       then you can publish your adventure on the map ")
                    .foregroundColor(ColorConstant.foreground.color)
                    .frame(width: 317, height: 105)
                    .font(.body)
                    .multilineTextAlignment(.center)
                
                Image("youtubeAccessGrantRequestImage2")
                    .resizable()
                    .frame(width: 320, height: 168)
                
                
                CustomNavLink(destination: MyStoryListView().onAppear{
                    //delete exsiting data in myStoryListVM
                    myStoryListVM.deleteExistingYoutubeContent()
                    //request additional permission using a loginManager
                    loginManager.requestMoreAccess {
                        //get the content
                        myStoryListVM.downloadYotubeContentsAndMappedWithCoreData()
                    }
                }
                .navigationBarHidden(true)
                )
                {
                    Text("Youtube Channel Grant Reqeust")
                        .font(.headline)
                        .withDefaultButtonFormatting()
                }
                .withPressableStyle(scaledAmount: 0.9)
                .padding(40)
                
                
            }
            
        }
    }
}

struct YoutubeAccessGrantRequestView2_Previews: PreviewProvider {
    static var previews: some View {
        YoutubeAccessGrantRequestView2()
    }
}
