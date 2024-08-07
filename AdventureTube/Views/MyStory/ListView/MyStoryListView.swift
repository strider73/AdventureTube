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
    
    @StateObject var nav = NavigationStateManager()
    
    
    @State private var showNewStoryView:Bool = false
    @State private var scrollPosition: CGFloat = 0
    @State private var currentIndex = 0
    @State private var dataLoaded: Bool = false // New state variable to track data loading completion
    @State private var isLoadingMore = false // New state variable to track loading state
    
    
    init(){
        print("Init MyStoryListView")
        let coloredAppearance = UINavigationBarAppearance()
        coloredAppearance.configureWithOpaqueBackground()
        coloredAppearance.backgroundColor = .systemBackground
        coloredAppearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        coloredAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        
        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().compactAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
        UINavigationBar.appearance().tintColor = .white
    }
    
    
    var body: some View {
        
        NavigationStack(path: $nav.selectionPath){
            ZStack {
                ColorConstant.background.color.edgesIgnoringSafeArea(.all)
                List{
                    ForEach(myStoryListVM.youtubeContentItems) { youtubeContentItem in
                        
                        Button {
                            nav.selectionPath.append(youtubeContentItem)
                        } label: {
                            MyStoryCellView(youtubeContentItem: youtubeContentItem, adventureTubeData: myStoryListVM.$adventureTubeData)
                                .background(Color.white)
                                .cornerRadius(5)
                                .shadow(radius: 5)
                                .padding(.horizontal,0)
                                .padding(.vertical,3)
                        }
                        .onAppear {
                            if myStoryListVM.youtubeContentItems.last == youtubeContentItem && !isLoadingMore {
                                print("need to load more ")
                            }
                        }
                        
                    }
                    .listRowInsets(EdgeInsets())
                }
                .onAppear{
                    if loginManager.hasYoutubeAccessScope &&
                        myStoryListVM.youtubeContentItems.count == 0{
                        //myStoryListVM.getTheAllMomentList()
                        myStoryListVM.downloadYotubeContentsAndMappedWithCoreData{
                            self.dataLoaded = true // Set dataLoaded to true after data is fetched
                        }
                    }
                }
                .foregroundColor(Color.black)
                .navigationDestination(for:YoutubeContentItem.self ) { selectedYoutubeContentItem in
                    StoryView(youtubeContentItem: selectedYoutubeContentItem, adventureTubeData: myStoryListVM.$adventureTubeData)
                        .navigationBarBackButtonHidden(true)
                    
                }
                .navigationTitle(getListTitle())
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    // TODO: add buttons in here
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            myStoryListVM.isShowRefreshAlert = true
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 22, weight: .bold)) // Adjust size and weight here
                                .foregroundColor(Color.black)
                        }
                    }
                }
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
        .environmentObject(nav)
    }
    
    
    
    private func getListTitle() -> String {
        guard let userName = loginManager.userData.givenName else{
            return "Adventure Story"
        }
        return userName + "'s Adventure Story"
    }
    
    
}

struct MyStoryListView_Previews: PreviewProvider {
    static var previews: some View {
        MyStoryListView()
            .environmentObject(dev.loginManager)
            .environmentObject(dev.myStoryVM)
            .environmentObject(CustomTabBarViewVM.shared)
    }
}


