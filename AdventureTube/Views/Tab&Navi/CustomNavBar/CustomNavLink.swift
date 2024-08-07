//
//  CustomNavLink.swift
//  AdventureTube
//
//  Created by chris Lee on 17/2/22.
//

import SwiftUI

struct CustomNavLink<Label:View, Destination:View>: View {
    let destination : Destination
    let label : Label
    @Binding var isActive : Bool
    
    
    init(destination: Destination,
         isActive: Binding<Bool> = .constant(true),
         @ViewBuilder label: () -> Label) {
        self.destination = destination
        self.label = label()
        self._isActive = isActive
    }
    var body: some View {
            NavigationLink(destination: CustomNavBarContainerView {
                destination
            }
            .navigationBarHidden(true)) {
                label
            }
            .buttonStyle(PlainButtonStyle()) // Removes the default ">" indicator
        }
}

struct CustomNavLink_Previews: PreviewProvider {
    @State static var path : [String]  = []
    static var previews: some View {
        CustomNavView{
            CustomNavLink(destination:Text("Destination")){
                Text("Click me")
            }
        }
    }
    
}


