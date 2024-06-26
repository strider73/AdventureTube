//
//  CustomNavView.swift
//  AdventureTube
//
//  Created by chris Lee on 16/2/22.
//
// This is where origional NavigationView has been customize


import SwiftUI

struct CustomNavView<Content:View>: View {
    
    let content : Content
    
    init(@ViewBuilder content : () -> Content){
        self.content = content()
    }
    
    var body: some View {
        
        NavigationView {
            VStack(spacing:0) {
                CustomNavBarContainerView{
                    content
                }
                .navigationBarHidden(true)// will remove navigationView on List 
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        
    }
}

struct CustomNavView_Previews: PreviewProvider {
    static var previews: some View {
        CustomNavView {
            Color.yellow.ignoresSafeArea()
        }
    }
}


//in order to  using a finger swap
extension UINavigationController {
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = nil
    }
}
