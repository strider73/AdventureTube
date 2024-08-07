//
//  ObservableScrollView.swift
//  AdventureTube
//
//  Created by chris Lee on 5/8/2024.
//

import Foundation
import SwiftUI

struct ObservableScrollView<Content: View>: View {
    let content: Content
    // @Binding var contentOffset: CGFloat
    
    init( @ViewBuilder content: () -> Content) {
        //self._contentOffset = contentOffset
//        self.action = action
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            content
                .background {
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: ContentOffsetKey.self, value: geometry.frame(in: .named("scrollView")).maxY)
                    }
                }
        }
        .coordinateSpace(name: "scrollView")
        .onPreferenceChange(ContentOffsetKey.self) { maxY in
            let screenHeight = UIScreen.main.bounds.height
            if maxY < screenHeight * 1.1 {
                print("maxY is : \(maxY)")
                print("hit the bottom")
            }else{
                print("it's not the bottom")

            }
        }
    }
}


struct ContentOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}
