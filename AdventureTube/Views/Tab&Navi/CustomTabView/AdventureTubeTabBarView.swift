 //
//  AppTabBarView.swift
//  AdventureTube
//
//  Created by chris Lee on 10/2/22.
//
//Generics
//ViewBuilder
//PreferenceKey
//MAtchedGeometryEffect

import SwiftUI

struct AdventureTubeTabBarView: View {
    init(){
        print("init AdventureTubeTabBarView")
    }
    
    @EnvironmentObject private var loginManager : LoginManager
    @State private var tabSelection: TabBarItemInfoEnum  = .setting
    var body: some View {
         //defaultTabView()
        CustomTabBarContainerView(selection: $tabSelection) {
            MapView()
                //this will call the tabBarItem in View extension
                //and provide info to create tab bar
                //all this tabBarItem info will be store tabs valiable
                //inside CustomTabBarContainerView
                .tabBarItem(tab: .storymap ,selection: tabSelection)
            MainStoryView()
                .tabBarItem(tab: .mystory,selection: tabSelection)
            MainSavedStoryView()
                .tabBarItem(tab: .savedstory,selection: tabSelection)
            SettingView()
                .tabBarItem(tab: .setting,selection: tabSelection)
        }
    }
}

struct AdventureTubeTabBarView_Previews: PreviewProvider {
    static var previews: some View {
        AdventureTubeTabBarView()
            .environmentObject(dev.loginManager)
            .environmentObject(CustomTabBarViewVM.shared)
    }
}

//and this will call the view modifier with additional tab info and selected info
//So there is question  how modifier inside of tabBarItem able to refer the view that tabBarItem calling on ???
// it is all about modifer method!!!!!
//modifier method able to access view that tabBarItem called
extension View {
    func tabBarItem(tab: TabBarItemInfoEnum , selection: TabBarItemInfoEnum) -> some View {
        modifier(TabBarItemViewModifer(tab: tab, selection: selection))
    }
}


//extension AdventureTubeTabBarView{
//
//    func defaultTabView() -> some View {
//        TabView(selection: $selection) {
//            Color.red
//                .tabItem {
//                    Image(systemName: "house")
//                    Text("Home")
//                }
//            Color.blue
//                .tabItem {
//                    Image(systemName: "heart")
//                    Text("Favorites")
//                }
//            Color.orange
//                .tabItem {
//                    Image(systemName: "person")
//                    Text("Profile")
//                }
//        }
//    }
//}
