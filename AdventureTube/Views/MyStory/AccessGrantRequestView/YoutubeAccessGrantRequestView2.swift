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
    @State private var isPresentingMyStoryListView = false
    @State private var isShowingError = false
    @State private var errorMessage: String? = nil
    
    init(){
        print("init YoutubeAccessGrantRequestView2")
        
    }
    
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
                
                Button(action: {
                    // Request additional permissions and handle navigation
                    loginManager.requestMoreAccess { error in
                        if let error = error {
                            errorMessage = error.localizedDescription
                            isShowingError = true
                        } else {
                            myStoryListVM.deleteExistingYoutubeContent()
                            myStoryListVM.downloadYotubeContentsAndMappedWithCoreData {
                                // Navigate to MyStoryListView after data is loaded
                                isPresentingMyStoryListView = true
                            }
                        }
                    }
                }) {
                    Text("Youtube Channel Grant Request")
                        .font(.headline)
                        .withDefaultButtonFormatting()
                }
                .withPressableStyle(scaledAmount: 0.9)
                .padding(40)
                
                
            }
            .sheet(isPresented: $isShowingError) {
                // Present an error message if there is an error
                ErrorView(message: errorMessage ?? "An error occurred")
            }
            .background(
                NavigationLink(
                    destination: MyStoryListView(),
                    isActive: $isPresentingMyStoryListView
                ) {
                    EmptyView()
                }
                
                
            )
        }
        .navigationBarHidden(/*@START_MENU_TOKEN@*/false/*@END_MENU_TOKEN@*/)
    }
}

struct YoutubeAccessGrantRequestView2_Previews: PreviewProvider {
    static var previews: some View {
        YoutubeAccessGrantRequestView2()
    }
}
