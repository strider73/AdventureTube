//
//  PublishWatermark.swift
//  AdventureTube
//
//  Created by chris Lee on 31/8/2022.
//

import Foundation
import SwiftUI
struct PublishWatermark:ViewModifier {
    var isPublished = false
    func body(content:Content) -> some View {
        ZStack(alignment : .topTrailing) {
            content
            if isPublished{
                HStack(alignment: .top, spacing: 2){
                    Image("published")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .cornerRadius(5)
                     
                }
                .padding(EdgeInsets(top: 3, leading: 3, bottom: 3, trailing: 5))
            }
        }
    }
}


extension View{
    func publishWatermark(isPublished:Bool) -> some View {
        modifier(PublishWatermark(isPublished: isPublished))
    }
}
