//
//  ExplainViewNo4.swift
//  Momentale
//
//  Created by chris Lee on 26/10/21.
//

import Foundation
import SwiftUI
struct ExplainViewNo4: View {
    @State var isShowingLogin = false
    var body: some View {
        ZStack{
            Color.black.opacity(0.1).ignoresSafeArea()
            VStack {
                Spacer()
                Text("Share Your Stories")
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .padding()
                Image("Launch screen4")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width:112,height: 119 )
                Text("Publish  on our map will promote your story to reach out others not only by youtube  but also  your instagram , gps track ,geochasing and lot more data we can accept. your jounery will become much more informative than ever before.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
                HStack{
                    
                    Button(action: {
                        isShowingLogin.toggle()
                    }) {
                        HStack{
                            Text("GET START WITH")
                            Image("LoginViewArrow")
                                .frame(width: 42, height: 42)
                        }
                    }
                    .fullScreenCover(isPresented: $isShowingLogin) {
                        LoginView()
                    }
//                    NavigationLink(destination: LoginView()) {
//                        HStack{
//                            Text("GET START WITH")
//                            Image("LoginViewArrow")
//                                .frame(width: 42, height: 42)
//                        }
//                    }
                    
                }
            }
        }
    }
}



struct ExplainViewNo4_Previews: PreviewProvider {
    static var previews: some View {
        ExplainViewNo4()
    }
}
