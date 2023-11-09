//
//  CustomTabBarContainerView.swift
//  AdventureTube
//
//  Created by chris Lee on 11/2/22.
//

import SwiftUI


struct CustomTabBarContainerView<Content:View> : View {
    // This TabarItem will be set from child view when we call .tabItem() using a preferenceKey !!!!!
    
    /*    @Binding var isCustomTabVarViewShow : Bool
     this is final destination that has to be update dynametically when  new tabBarItem has been added
     by wathcing that using a onPreferenceChange
     
     */
    
    @EnvironmentObject var customTabVM : CustomTabBarViewVM
    @Binding var selection : TabBarItemInfoEnum
    let content : Content
    @State private var tabs : [TabBarItemInfoEnum] = []
    
    public init(selection: Binding<TabBarItemInfoEnum>, @ViewBuilder content: () -> Content){
        self._selection = selection//store selected tab case info
        self.content = content()//stack all views on display  in  content
    }
    var body: some View {
        ZStack(alignment: .bottom) {
            //main content area
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            //Tab Bar
            //we drawing customTabBar using a tabs info
            if(customTabVM.isTabBarViewShow){
                CustomTabBarView(tabs: tabs, selection: $selection , localSelection:  selection)
                    .transition(AnyTransition.opacity.animation(.easeInOut))
            }
            
        }
        //This will watch PreferenceKye value and will be called when it is get updated
        .onPreferenceChange(TabBarItemsPreferenceKey.self) { value in
            self.tabs = value
        }
    }
}

struct CustomTabBarContainerView_Previews: PreviewProvider {
    //change this value
    static let selectedTab : TabBarItemInfoEnum  = .setting
    
    static let tabs : [TabBarItemInfoEnum] = [
        .storymap,
        .mystory,
        .savedstory,
        .setting
        
    ]
        
    static var previews: some View {
                 
        CustomTabBarContainerView(selection: .constant(selectedTab)) {
            Color.red
                .tabBarItem(tab: .mystory, selection: selectedTab)
            Color.blue
                .tabBarItem(tab: .setting, selection: selectedTab)
        }
        .environmentObject(dev.customTabBarVM)
    }
}
