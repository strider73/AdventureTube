//
//  ExplainViewNo2.swift
//  Momentale
//
//  Created by chris Lee on 8/10/21.
//

import SwiftUI

struct ExplainViewNo2: View {
    var body: some View {
        ZStack{
            Color.black.opacity(0.1).ignoresSafeArea()
            VStack {
                Spacer()
                Text("Explore Different Stories")
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .padding()
                Image("Launch screen2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width:117,height: 110 )
                Text("Now you can look the other's story  on the map  and directly point out  place you are interested in and quicklty move to next one if that is not the one you looking for.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            }
            
        }
    }
}

struct ExplainViewNo2_Previews: PreviewProvider {
    static var previews: some View {
        ExplainViewNo2()
    }
}
