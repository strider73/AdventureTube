//
//  CustomNavBarContainerView.swift
//  AdventureTube
//
//  Created by chris Lee on 17/2/22.
//
//This is entire section of screen of custom navbarview include content area

import SwiftUI

struct CustomNavBarContainerView<Content : View>: View {
    let content: Content
    @State private var showBackButton : Bool = false
    @State private var title: String = ""
    @State private var buttons : [CustomNavBarButtonInfo] = []
    @State private var isNavBarHidden : Bool = false
    
    init(@ViewBuilder content: () -> Content){
        self.content = content()
    }

    
    var body: some View {
        VStack(spacing:0) {
            //need CustomNavBarView here
            if !isNavBarHidden {
                CustomNavBarView(title:title , buttons: $buttons)
                Divider()
            }
            content.frame(maxWidth : .infinity , maxHeight:  .infinity)
            
        }
        ///This whole sextion will watch any update for the preferenceky we create
        ///anywhere inside CustomNavBarContainerView
        ///ex) on Preview
        .onPreferenceChange(CustomNavBarTitlePreferenceKey.self, perform: { value in
            self.title = value
        })
        .onPreferenceChange(CustomNavBarButtonPreferenceKey.self, perform: { value in
            self.buttons = value
        })
        .onPreferenceChange(CustomNavBarHiddenPreferenceKey.self, perform: { value in
            self.isNavBarHidden = value
        })
       
    }
}

struct CustomNavBarContainerView_Previews: PreviewProvider {
    static let buttons : [CustomNavBarButtonInfo ] = [.addNewStory(myStoryCommonDetailViewVM: dev.myStoryCommonDetailViewVM) , .back]
    static var previews: some View {
        CustomNavBarContainerView {
            ZStack {
                Color.green.ignoresSafeArea()
                Text("Hello world")
                    .foregroundColor(Color.white)
            }
            .navigationBarBackButtonHidden(true)

            .customNavBarItems(title: "Test title", buttons: buttons)
//            .customNavigationTitle("CustomNavigation Title")
//            .customNavigationSubtitle("Custom Navigation subTitle")
          
        }
    }
}
