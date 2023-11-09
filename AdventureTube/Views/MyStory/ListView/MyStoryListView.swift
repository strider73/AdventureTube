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
    @State private var buttons : [CustomNavBarButtonItem] = []

    var body: some View {
        CustomNavView{
            ZStack {
                ColorConstant.background.color.edgesIgnoringSafeArea(.all)
                // NavigationLink Should not in the Foreach cycle
                
                
                ScrollView(showsIndicators:false){
                    LazyVStack{
                        //                    ScrollViewReader { proxy in
//                        ForEach(myStoryListVM.youtubeContentItems ,id : \.id){ youtubeContentItem in
                        ForEach(myStoryListVM.youtubeContentItems){ youtubeContentItem in
//                            let story = myStoryListVM.findStoryEntityForYoutubeId(atId:youtubeContentItem.id)
                            MyStoryCellView(youtubeContentItem: youtubeContentItem , adventureTubeData: myStoryListVM.$adventureTubeData)
                                .background(Color.white)
                                .cornerRadius(5)
                                .shadow(radius: 5)
                                .padding(3)
                                .onTapGesture {
                                    seque(youtubeContentItem: youtubeContentItem)
                                }
                            //                        }
                        }
                    }
                }
                .onAppear {
                    //init Navigastion Buttos function
                    buttons = [.empty , .refreshMyStoryList(myStoryListVM: myStoryListVM)]
                    
                    // it need to be load after view fully loaded not on appear
                    customTabVM.showTabBar()
                    /// downloadYotubeContents method will get called only
                    ///  when app already have  youtube access permission
                    ///  but there is no youtube content to display
                    if loginManager.hasYoutubeAccessScope &&
                        myStoryListVM.youtubeContentItems.count == 0{
                        myStoryListVM.downloadYotubeContentsAndMappedWithCoreData()
                    }
  
                }
                .onDisappear {
                    customTabVM.hideTabBar()
                }
                
            }
            .foregroundColor(Color.black)
            .customNavBarItems(title:getListTitle(),buttons: buttons)
            .background(
                    CustomNavLink(
                    destination: StoryLoadingView(youtubeContentItem: selectedYoutubeContentItem ,adventureTubeData: myStoryListVM.$adventureTubeData),
                    isActive: $showNewStoryView,
                    label: {EmptyView()}
                    )
    
            )
        }
        /// action sheet  before reload Data from youtube
        /// myStoryListVM.isShowRefreshAlert  which is just Bool data need to be' Bool>
        /// => :$myStoryListVM.isShowRefreshAlert
        ///
        /// and action data of isShowRefreshAlert  will be toggled from CustomNavBarView
        /// and Published so it  swiftUI will reload UI again if isShowRefreshAlert  has been updated and
        /// 
//        .actionSheet(isPresented:$myStoryListVM.isShowRefreshAlert) {
//            ActionSheet(title: Text( "Content Reload"),
//                        message:Text( "Your Story Data will be reload from youtube Again"),
//                        buttons: [
//                            .cancel(),
//                            .default(Text("reload"), action: {
//                                myStoryListVM.downloadYotubeContents()
//                            })
//                        ])
//        }
        .confirmationDialog("Your Story will be reload from Youtube again ",
                            isPresented: $myStoryListVM.isShowRefreshAlert ,
                            titleVisibility: .visible) {
         
            Button ("Reload"){
                myStoryListVM.downloadYotubeContentsAndMappedWithCoreData()
            }
            
        }
    }
    
    private func getListTitle() -> String {
        guard let userName = loginManager.userData.givenName else{
            return "Adventure Story"
        }
        return userName + "'s Adventure Story"
    }
    
    
    private func seque(youtubeContentItem : YoutubeContentItem){
        selectedYoutubeContentItem = youtubeContentItem
        showNewStoryView.toggle()
    }
}

struct MyStoryListView_Previews: PreviewProvider {
    static var previews: some View {
        MyStoryListView()
            .environmentObject(dev.loginManager)
            .environmentObject(dev.myStoryVM)
            .environmentObject(CustomTabBarViewVM())
    }
}
