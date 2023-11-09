//
//  TabBarItemPreferenceKey.swift
//  AdventureTube
//
//  Created by chris Lee on 11/2/22.
//

import Foundation
import SwiftUI


//this PrefereceKey will deliver new tab info  to the destination 
struct TabBarItemsPreferenceKey : PreferenceKey {
    static var defaultValue: [TabBarItemInfoEnum] = []
    
    static func reduce(value: inout [TabBarItemInfoEnum], nextValue: () -> [TabBarItemInfoEnum]) {
        // append to the current value
        value += nextValue()
    }
}

/*
 This is the most important method in CustomTabBar !!!!
 
1)control opacity among the all views by selection
2)call TabBarItemsPreferenceKey and will add tab info
3)the value of TabBarItemsPreferenceKey will be monitier by
  onPreferenceChange(TabBarItemsPreferenceKey.self) and copy
  to local value in CustomTabBarContainerView and used to create tab
  in customTabBarView
 
  */
struct TabBarItemViewModifer : ViewModifier{
    
    // This is the value we passed in
    let tab:TabBarItemInfoEnum
    var selection : TabBarItemInfoEnum
    func body(content : Content) -> some View {
        //This is secret How content was able to access ???!!! How ???
        //This is what modifier function (modifier in the view)make this possible 
        content
            //This opacity change make screen swap
            .opacity(selection == tab ? 1.0 : 0.0)
        //This will call the PreferenceKey
        //and the value of TabBarItemsPreferenceKey will be added
        // and that change will be detected by onPreferenceChange(TabBarItemsPreferenceKey.self) 
            .preference(key: TabBarItemsPreferenceKey.self, value: [tab])
    }
}



 
////and this will call the view modifier with additional tab info and selected info
//extension View {
//    func tabBarItem(tab: TabBarItem , selection: Binding<TabBarItem>) -> some View {
//        modifier(TabBarItemViewModifer(tab: tab, selection: selection))
//    }
//}
