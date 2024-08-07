//
//  MyStoryListView.swift
//  AdventureTube
//
//  Created by chris Lee on 6/3/22.
//

import SwiftUI


struct MyStoryListView: View {
    @EnvironmentObject private var loginManager : LoginManager
    @EnvironmentObject private var myStoryListVM : MyStoryListViewVM
    @EnvironmentObject var customTabVM : CustomTabBarViewVM
    
    @State private var showNewStoryView:Bool = false
    @State private var selectedYoutubeContentItem : YoutubeContentItem?
    @State private var buttons : [CustomNavBarButtonInfo] = []
    @State private var scrollPosition: CGFloat = 0
    @State private var currentIndex = 0
    @State private var dataLoaded: Bool = false // New state variable to track data loading completion
    @State private var isLoadingMore = false // New state variable to track loading state
    
    init(){
        print("Init MyStoryListView")
    }
    
    
    var body: some View {
        
        CustomNavView{
            ZStack {
                ColorConstant.background.color.edgesIgnoringSafeArea(.all)
                List{
                    ForEach(myStoryListVM.youtubeContentItems) { youtubeContentItem in
                        
                        
                        CustomNavLink(destination: StoryView(youtubeContentItem: youtubeContentItem, adventureTubeData: myStoryListVM.$adventureTubeData)) {
                            MyStoryCellView(youtubeContentItem: youtubeContentItem, adventureTubeData: myStoryListVM.$adventureTubeData)
                                .background(Color.white)
                                .cornerRadius(5)
                                .shadow(radius: 5)
                            
                        }
                        .listRowInsets(EdgeInsets())
                        .buttonStyle(PlainButtonStyle())
                        .onAppear {
                            if myStoryListVM.youtubeContentItems.last == youtubeContentItem && !isLoadingMore {
                                print("need to load more ")
                            }
                        }
                        
                    }
                }
                .onAppear{
                    buttons = [.empty , .refreshMyStoryList(myStoryListVM: myStoryListVM)]
                    if loginManager.hasYoutubeAccessScope &&
                        myStoryListVM.youtubeContentItems.count == 0{
                        //myStoryListVM.getTheAllMomentList()
                        myStoryListVM.downloadYotubeContentsAndMappedWithCoreData{
                            self.dataLoaded = true // Set dataLoaded to true after data is fetched
                        }
                    }
                }
                .foregroundColor(Color.black)
                .customNavBarItems(title:getListTitle(),buttons: buttons)
            }
        }
        .confirmationDialog("Your Story will be reload from Youtube again ",
                            isPresented: $myStoryListVM.isShowRefreshAlert ,
                            titleVisibility: .visible) {
            
            Button ("Reload"){
                myStoryListVM.deleteExistingYoutubeContent()
                myStoryListVM.downloadYotubeContentsAndMappedWithCoreData{}
            }
            
        }
        
        
    }
    
    
    
    private func getListTitle() -> String {
        guard let userName = loginManager.userData.givenName else{
            return "Adventure Story"
        }
        return userName + "'s Adventure Story"
    }
    
    
    //    private func seque(youtubeContentItem : YoutubeContentItem){
    //        selectedYoutubeContentItem = youtubeContentItem
    //        showNewStoryView.toggle()
    //    }
}

struct MyStoryListView_Previews: PreviewProvider {
    static var previews: some View {
        MyStoryListView()
            .environmentObject(dev.loginManager)
            .environmentObject(dev.myStoryVM)
            .environmentObject(CustomTabBarViewVM.shared)
    }
}
