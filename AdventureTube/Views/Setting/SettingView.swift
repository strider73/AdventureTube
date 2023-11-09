//
//  SettingView.swift
//  AdventureTube
//
//  Created by chris Lee on 14/2/22.
//

import SwiftUI
import GoogleSignIn

struct SettingView: View {
    //User Profile Data
    @EnvironmentObject private var loginManager : LoginManager
    @State private var isShowingMapView = false
    @State private var isShowingLogintoggle = false
    
    private var user: GIDGoogleUser? {
        return GIDSignIn.sharedInstance.currentUser
    }
    
    init(){
        print("Init SettingView ")
    }
    
    
    var body: some View {
        NavigationView{
            ZStack {
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
                        Spacer()
                        if let userProfile = user?.profile{
                            HStack(alignment: .top) {
                                UserProfileSmallImageView(userProfile: userProfile)
                                    .padding(.leading)
                                VStack(alignment: .leading) {
                                    Text(userProfile.name)
                                        .accessibilityLabel(Text("User name."))
                                    Text(userProfile.email)
                                        .accessibilityLabel(Text("User email."))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            Text( loginManager.userData.emailAddress ?? "No_Email")
                            Text( loginManager.userData.fullName ?? "No_FullName")
                            Text( loginManager.userData.givenName ?? "No_GivenName")
                            Text( loginManager.userData.familyName ?? "No_FamilyName")
                        }
                        
                        
                        Button(action: {
                            loginManager.signOut()
                        }) {
                            Text("Sign Out")
                        }
                        
                        Spacer()
                        Spacer()
                        
                    default :
                        SystemErrorView()
                    }
                }//text color in the view
                .foregroundColor(ColorConstant.foreground.color)
            }
            .preferredColorScheme(.light)
            .navigationBarHidden(true)
        }
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
            .environmentObject(dev.loginManager)
    }
}
