//
//  Overlay.swift
//  AdventureTube
//
//  Created by chris Lee on 28/5/22.
//

import SwiftUI

struct Overlay: View {
    var body: some View {
           Text("Swift by Sundell")
               .foregroundColor(.white)
               .font(.title)
               .padding(35)
               .background(
                   LinearGradient(
                       colors: [.orange, .red],
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing
                   )
               )
               .overlay(starOverlay, alignment: .topLeading)
               .cornerRadius(20)
       }

       private var starOverlay: some View {
           Image(systemName: "star")
       .foregroundColor(.white)
       .padding([.top, .trailing], 5)
       }
}

struct Overlay_Previews: PreviewProvider {
    static var previews: some View {
        Overlay()
    }
}
