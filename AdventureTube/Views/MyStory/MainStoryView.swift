//
//  MyStoriesView.swift
//  Momentale
//
//  Created by chris Lee on 1/10/21.
//

import SwiftUI

struct MainStoryView: View {
    
    
    /*
     using a Enviroment property wrapper
     call the managedObjectContext and store at private property
     
     */
//    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var loginManager : LoginManager
    @State private var isShowingLogin = false
    @StateObject var myStoryListVM : MyStoryListViewVM  =  MyStoryListViewVM()
    
    init(){
        print("Init MyStoriesView ")
    }
    
    
    var body: some View {
        ZStack {
            ColorConstant.background.color.edgesIgnoringSafeArea(.all)
            switch(loginManager.loginState){
            case .signedOut:
                Button("Sign In"){
                    isShowingLogin.toggle()
                }
                .fullScreenCover(isPresented: $isShowingLogin) {
                    LoginView()
                }
            case .signedIn:
                //check the permission
                if loginManager.hasYoutubeAccessScope{
                    MyStoryListView()
                }else{
                    NavigationView{
                        YoutubeAccessGrantRequestView1()
                            .navigationBarHidden(true)
                    }
                }
            default :
                SystemErrorView()
            }
        }
        .preferredColorScheme(.light)
        .environmentObject(myStoryListVM)
    }
    
}

struct MyStoryView_Previews: PreviewProvider {
    static var previews: some View {
        MainStoryView()
            .environmentObject(dev.loginManager)

    }
}


extension MainStoryView {
    
    private var myStoryList : some View {
        
        Text("MyStoryView !!!!")
        
    }
    
    
    
    private var myStoryIsLoading  : some View {
        
        Text("My Story List wil be loading soon")
        
    }
}


