//
//  CustomSheet.swift
//  AdventureTube
//
//  Created by chris Lee on 11/7/2022.
//

import Foundation
import SwiftUI

// MainContent type parameter name has been use to avoid conflict with "name of Content"
// has been used in ViewModifier protocol as typealias
struct CustomSheetModifier<Item: Identifiable, MainContent:View>: ViewModifier{
    

    public let mainContent :(Item?) -> MainContent
    @Binding public var isShowing:Bool
    @Binding public var item : Item?
    @State private var isDragging = false
    @State private var curHeight:CurHeightType
    
    init(isShowing:Binding<Bool>, item :Binding<Item?> ,size : CurHeightType,@ViewBuilder mainContent:@escaping (Item?) -> MainContent){
        self._isShowing = isShowing
        self._item = item
        self.mainContent = mainContent
        _curHeight = State(initialValue: size)
    }
    
    func body(content: Content)  -> some View {
        content
        ModalView(isShowing: $isShowing,
                  item:$item,
                  size: curHeight,
                  content: mainContent)
    }
}


extension View{
    func customSheet<Item : Identifiable, Content:View >(isShowing:Binding<Bool>,
                                                         item :Binding<Item?> ,
                                                         size : CurHeightType,
                                                         @ViewBuilder mainContent :@escaping (Item?) -> Content) -> some View{
        modifier(CustomSheetModifier(isShowing: isShowing,
                                     item: item,
                                     size: size,
                                     mainContent: mainContent))

    }
}
