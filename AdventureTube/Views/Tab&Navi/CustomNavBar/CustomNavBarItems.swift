
import Foundation
import SwiftUI

struct CustomNavBarTitlePreferenceKey: PreferenceKey {
    
    static var defaultValue: String = ""
    static func reduce(value: inout String, nextValue: () -> String) {
        value = nextValue()
    }
    
}
struct CustomNavBarButtonPreferenceKey: PreferenceKey{
    static var defaultValue: [CustomNavBarButtonItem] = []
    static func reduce(value: inout [CustomNavBarButtonItem], nextValue: () -> [CustomNavBarButtonItem]) {
        value += nextValue()
    }
}





extension View {
        
    func customNavigationTitle(_ title: String) -> some View {
        preference(key: CustomNavBarTitlePreferenceKey.self, value: title)
    }
    
    func customNavigationBarButtons( buttons : [CustomNavBarButtonItem]) -> some View{
        preference(key: CustomNavBarButtonPreferenceKey.self, value: buttons)
    }


    
    func customNavBarItems(title: String = "",
        buttons:[CustomNavBarButtonItem] = []) -> some View {
        self
            .customNavigationTitle(title)
            .customNavigationBarButtons(buttons: buttons)

    }
    
    


}
