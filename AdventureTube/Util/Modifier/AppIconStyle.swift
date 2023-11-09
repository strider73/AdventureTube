//
//  AppIconStyle.swift
//  AdventureVictoria
//
//  Created by chris Lee on 22/9/21.
//

import Foundation
import SwiftUI


// TODO: This ImageModfifier protocol and Image.modifier function need to understand later    23/09/2021
protocol ImageModifier {
    /// `Body` is derived from `View`
      associatedtype Body : View
    /// Modify an image by applying any modifications into `some View`
    func body(image: Image) -> Self.Body
}

extension Image{
    
    func modifier<M>(_ modifier: M) -> some View where M: ImageModifier {
        modifier.body(image: self)
    }

// extendtion itself can't have property
//
//    func appSymbolicStyle() -> some View {
//             self
//            .resizable()
//            .aspectRatio(contentMode: .fit)
//            .frame(width: 146)
//    }
//
  
}


/*
 This structure wont be able to use with View's modifier protocol since
 it doesn't conform ViewModifier protocol
 */
struct AppSymbolicStyle:ImageModifier {
    var width : CGFloat
    func body(image: Image) -> some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: width)
    }
    init(){
       width = 146
    }
    
    init(_ width : CGFloat){
        self.width = width
    }
}
