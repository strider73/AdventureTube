//
//  Watermark.swift
//  AdventureTube
//
//  Created by chris Lee on 21/3/22.
//

import Foundation
import SwiftUI

struct CategoryWatermark : ViewModifier {
    
    //This stored propery is option 
    //This stored property is real different
    //which is normal extention of view can't have
    var categories : [String]
    func body(content: Content) -> some View {
        ZStack(alignment: .bottomLeading) {
            content
            HStack(alignment: .bottom, spacing: 2){
                ForEach(categories, id:\.self){ category in
                    
                    Image(category)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15, height: 15)
                        .cornerRadius(5)
                }
                .padding(2)
            }
            .frame( height: 28)
            .padding(5)

        }
        
    }
}

  
extension View {
    func categoryWatermark(with categories : [String]) -> some View {
        modifier(CategoryWatermark(categories: categories))
    }
}
