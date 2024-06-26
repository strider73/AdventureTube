//
//  ProfileView.swift
//  Momentale
//
//  Created by chris Lee on 13/12/21.
//

import SwiftUI
import GoogleSignIn

struct MainSavedStoryView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var loginManager : LoginManager
    @State private var isShowingLogintoggle = false
    init(){
        print("Init ProfileView ")
    }
    var body: some View {
        NavigationView{
            ZStack{
                ColorConstant.background.color.edgesIgnoringSafeArea(.all)
                VStack{
                    switch(loginManager.loginState){
                    case .signedOut:
                        Button("Sign In"){
                            isShowingLogintoggle.toggle()
                        }
                        .fullScreenCover(isPresented: $isShowingLogintoggle) {
                            LoginView()
                        }
                    case .signedIn :
                        Text("SavedStoryView View")
                            .foregroundColor(ColorConstant.foreground.color)
                    default :
                        SystemErrorView()
                        
                    }
                }
            }
            .preferredColorScheme(.light)
            .navigationBarHidden(true)
        }
    }
    
    
    
    func testNavigation(){
        print("TestNaviagation func has been called ")
    }
}

struct SavedStoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView{
            MainSavedStoryView()
                .navigationBarHidden(true)
        }
        .environmentObject(dev.loginManager)
    }
}
