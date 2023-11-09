//
//  ExplainViewNo3.swift
//  Momentale
//
//  Created by chris Lee on 8/10/21.
//

import SwiftUI

struct ExplainViewNo3: View {
    var body: some View {
        ZStack{
            Color.black.opacity(0.1).ignoresSafeArea()
            VStack {
                Spacer()
                Text("Plan Your Adventure")
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .padding()
                Image("Launch screen3")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width:139,height: 114 )
                Text("There is a indicatior symbol that notify you for the activity you can choose from that place and will have much more chance to entertained before you get there.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            }
        }
        
    }
}

struct ExplainViewNo3_Previews: PreviewProvider {
    static var previews: some View {
        ExplainViewNo3()
    }
}
