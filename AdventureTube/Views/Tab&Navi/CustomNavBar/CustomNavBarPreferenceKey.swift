
import Foundation
import SwiftUI

struct CustomNavBarHiddenPreferenceKey : PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}



struct CustomNavBarTitlePreferenceKey: PreferenceKey {
    
    static var defaultValue: String = ""
    static func reduce(value: inout String, nextValue: () -> String) {
        value = nextValue()
    }
    
}
struct CustomNavBarButtonPreferenceKey: PreferenceKey{
    static var defaultValue: [CustomNavBarButtonInfo] = []
    static func reduce(value: inout [CustomNavBarButtonInfo], nextValue: () -> [CustomNavBarButtonInfo]) {
        value += nextValue()
    }
}





extension View {
        
    func customNavigationTitle(_ title: String) -> some View {
        preference(key: CustomNavBarTitlePreferenceKey.self, value: title)
    }
    
    func customNavigationBarButtons( buttons : [CustomNavBarButtonInfo]) -> some View{
        preference(key: CustomNavBarButtonPreferenceKey.self, value: buttons)
    }
    
    
    func customNavigationBarHidden(_  isHidden:Bool) -> some View {
        preference(key: CustomNavBarHiddenPreferenceKey.self, value: isHidden)
    }


    
    func customNavBarItems(title: String = "",
        buttons:[CustomNavBarButtonInfo] = []) -> some View {
        self
            .customNavigationTitle(title)
            .customNavigationBarButtons(buttons: buttons)

    }
    
    


}
