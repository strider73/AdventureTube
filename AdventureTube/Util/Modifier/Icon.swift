//
//  Icon.swift
//  AdventureTube
//
//  Created by chris Lee on 29/3/22.
//

import Foundation
import SwiftUI

struct CategoryIconViewModifier : ViewModifier {
    
    var isSelected : Bool
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.black)
            .font(Font.custom("momentale-categories", size: 44))
            .background(
                Color.gray
                    .cornerRadius(4)
                    .opacity(isSelected == true ? 0.5  : 0.1))
    }
}


struct SmallCategoryIconViewModifier : ViewModifier {
    
    var isSelected : Bool
    var withColor : Color
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.black)
            .font(Font.custom("momentale-categories", size: 18))
            .background(
                withColor
                    .cornerRadius(8)
                    .opacity(isSelected == true ? 0.5  : 0.1))
    }
}

extension View {
    
    func smallCategoryIcon(isSelected:Bool = false , withColor : Color ) -> some View {
        modifier(SmallCategoryIconViewModifier(isSelected: isSelected  , withColor: withColor))
    }

    
    func categoryIcon(isSelected:Bool = false) -> some View {
        modifier(CategoryIconViewModifier(isSelected: isSelected))
    }

    
    /**
     for custom Environmnet Value
    
     by this method  any struct confirm view Protocol
     will be able to use XXX.myTubeBackgoundColor(.yellow)
     
     
     ex)
     1. create Custom ViewModifer
     
     struct Caption: ViewModifier {
       let font: Font
       @Environment(\.captionBackgroundColor) var backgroundColor

       func body(content: Content) -> some View {
         content
           .font(font)
           .padding([.leading, .trailing], 5.0)
           .background(backgroundColor)
           .cornerRadius(5.0)
       }
     }

     2. extenton on view
     extension View {
       func caption(font: Font = .caption) -> some View {
         modifier(Caption(font: font))
       }
     }
     
     3 using custom ViewModifier with custom  Environment Value
     
     Text("Hello , World")
         .caption(font : .largeTitle)     //custom ViewModifier
         .captionbBackgroudColor(.yellow) //custom Environment Value
     
     */
    func myTubeBackgroudColor(_ color :Color ) -> some View {
        /**
         This is enviroment modifier
         
         use this modifier to set the one of writable propery value
         of the "EnvironmentValue"  structure include custome value you create
          
         */
        environment(\.myTubeBackgroundColor, color)
    }
   

}
