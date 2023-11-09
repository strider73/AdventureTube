//
//  ExplainViewNo1.swift
//  Momentale
//
//  Created by chris Lee on 8/10/21.
//

import SwiftUI

struct ExplainViewNo1: View {
    var body: some View {
        ZStack{
            Color.black.opacity(0.1).ignoresSafeArea()
            VStack{
                Spacer()
                Spacer()
                Spacer()
                Spacer()

                Text("Share your Adventure Anytime, Anywhere ")
                    .font(.custom("Source Sans Pro Bold", size: 28))
                    .multilineTextAlignment(.center)
                    .padding()
                Text("All your memories on the map will become lighthouse for next traveller")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
                
            }
        }
   }
}

struct ExplainViewNo1_Previews: PreviewProvider {
    static var previews: some View {
        ExplainViewNo1()
            .previewLayout(.sizeThatFits)
    }
}
