//
//  BoardingView.swift
//  Momentale
//
//  Created by chris Lee on 8/10/21.
//

import SwiftUI

struct BoardingView: View {
    var viewName : String
    var body: some View {
        ZStack{
            Image("startPage_Background")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            VStack{
                Image("appIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width:146)
                    .offset(y:-240)
                    .opacity(0.4)
                Text("\(viewName)")
                    .foregroundColor(.white)
            }
            
        }
    }
}

struct BoardingView_Previews: PreviewProvider {
    static var previews: some View {
        BoardingView(viewName: "testViewName")
    }
}
