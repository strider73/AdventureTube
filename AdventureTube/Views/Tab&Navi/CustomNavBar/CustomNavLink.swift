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
        
        NavigationLink(isActive: _isActive,
                       destination: {
            //instead of normal destination we wrap with
            //CustomNavBarContainerView{destination}
            //This is the part to give us custom navigation bar on destination
            CustomNavBarContainerView {
                destination

            }
            .navigationBarHidden(true)// will remove navigation View on StoryView which is targetView
        },
        label: {label}
        )
        
        
       
    }
}

struct CustomNavLink_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView{
            CustomNavLink(destination:Text("Destination")){
                Text("Click me")
            }
        }
    }
}


