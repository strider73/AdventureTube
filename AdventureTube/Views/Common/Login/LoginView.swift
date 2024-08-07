//
//  LoginView.swift
//  AdventureVictoria
//
//  Created by chris Lee on 22/9/21.
//

import SwiftUI
import GoogleSignIn
//TODO: This is the view to make decison of implementation of LoginServiceProtocol
struct LoginView: View {
    
    @EnvironmentObject private var loginManager : LoginManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingYoutubeLoginViewController = false
    @State private var name :   String = "E-Mail"
    @State private var passwd : String = "Password"
    @State private var checked = false
    @State private var isLoading = false // Add a state variable for loading
    @State private var errorMessag : String?

    
    var body: some View {
        ZStack{
            ColorConstant.background.color.edgesIgnoringSafeArea(.all)
                .ignoresSafeArea()
            //            switch  loginManager.loginState{
            //            case .signedIn:
            //                AdventureTubeTabBarView()
            //            default:
            //                loginView
            //            }
            VStack{
                Spacer()
                Image("appIcon")
                    .modifier(AppSymbolicStyle())
                Spacer()
                Group{
                    CustomTextFieldView(field:$name)
                    CustomTextFieldView(field:$passwd, isSecureField: true)
                    
                    HStack {
                        CheckBoxView(checked: $checked)
                        Text("Remember me")
                        Spacer()
                        Button("Forgot password") {
                            print("Do nothing yet")
                        }
                        Spacer()
                    }
                    Button(action: {}) {
                        Text("Login")
                            .font(Font.system(size: 20))
                            .padding(EdgeInsets(top: 20, leading: 160, bottom: 20, trailing: 160))
                            .overlay(RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.black, lineWidth: 1))
                            .background(Color.black)
                            .foregroundColor(.white)
                    }
                }
                Spacer()
                Text("Or Connect with")
                Spacer()
                HStack{
                    
                    Image("FacebookLogin_type1")
                        .loginButton()
                    Button(action: {
                        isLoading = true // Set loading state to true
                        loginManager.googleSignIn{ result in
                            isLoading = false // Set loading state to false after login finished
                            //This closure will called after login finished
                            switch result {
                                case  .success(let user):
                                    print("user signed in successfully")
                                case .failure(let error):
                                    errorMessag = error.localizedDescription
                                    print("Login error :\(error.localizedDescription)")
                            }
                        }
                        
                    }) {
                        Image("GoogleLogin_type1")
                            .loginButton()
                    }
                    Image("TweeterLogin_type1")
                        .loginButton()
                }
                Spacer()
            }
            if isLoading {
                // Show a loading indicator when isLoading is true
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                ProgressView("Signing in...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2)
            }
            
            
        }
        .navigationBarBackButtonHidden(true)
        .preferredColorScheme(.light)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView{
            LoginView()
                .navigationBarHidden(true)
        }
        .environmentObject(dev.loginManager)
    }
}


//extension LoginView{
//    private var loginView : some View {
//        VStack{
//            Spacer()
//            Image("appIcon")
//                .modifier(AppSymbolicStyle())
//            Spacer()
//            Group{
//                CustomTextFieldView(field:$name)
//                CustomTextFieldView(field:$passwd, isSecureField: true)
//
//                HStack {
//                    CheckBoxView(checked: $checked)
//                    Text("Remember me")
//                    Spacer()
//                    Button("Forgot password") {
//                        print("Do nothing yet")
//                    }
//                    Spacer()
//                }
//                Button(action: {}) {
//                    Text("Login")
//                        .font(Font.system(size: 20))
//                        .padding(EdgeInsets(top: 20, leading: 160, bottom: 20, trailing: 160))
//                        .overlay(RoundedRectangle(cornerRadius: 4)
//                                    .stroke(Color.black, lineWidth: 1))
//                        .background(Color.black)
//                        .foregroundColor(.white)
//                }
//            }
//            Spacer()
//            Text("Or Connect with")
//            Spacer()
//            HStack{
//                Image("FacebookLogin_type1")
//                    .loginButton()
//                Button(action: {
////                    authViewModel.signIn()
//                    loginManager.signIn()
//                }) {
//                    Image("GoogleLogin_type1")
//                        .loginButton()
//                }
////                GoogleSignInButtonWrapper(handler: authViewModel.signIn)
////                    .accessibility(hint: Text("Sign in with Google button."))
//                Image("TweeterLogin_type1")
//                    .loginButton()
//            }
//            Spacer()
//        }
//    }
//
//}


