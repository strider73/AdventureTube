//
//  LoginManager.swift
//  AdventureTube
//
//  Created by chris Lee on 21/1/22.
//


//TODO: loginService injection
/*
 
 in LoginManager I've used Dependecy injection with Protocol
 in order to prepare to use other login service
 but since its currently google  only using computed property instead atm.
 
 */

import Foundation
import GoogleSignIn

class LoginManager : ObservableObject  {
    @Published  var userData : UserModel = UserModel()
    @Published  var loginState : State = .initial{
          willSet(loginState){
            switch loginState  {
            case .signedIn:
                   print("loginState :===signedIn===")
            case .signedOut:
                   print("loginState :===signedOut===")
            case .initial :
                    print("loginState :===initial===")
       
            }
            
        }
    }
    
    //This is computed value and will not evalueated and
    //it will initailized when it called first time
    //
    //only stored property require evaluated in the intialization process
    private var loginService : LoginServiceProtocol {
        return GoogleLoginService(loginManager: self)
    }
    
    
    /*
     must be initiated only once but not able to guarrenty here
     */
    init(){
        //check the UserDefault
        print("init LoginManager")
        do{
            let adventureUser = try UserDefaults.standard.getObject(forKey: "user", castTo: UserModel.self)
            
            GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                if let user = user {
                    self.loginState = .signedIn(user)
                    print("email : \(adventureUser.emailAddress as String?)")
                    print("fullName  : \(adventureUser.fullName as String?)")
                    print("profilePicUrl  : \(adventureUser.profilePicUrl as String?)")
                    self.userData = adventureUser
                    print("user setting has been stored in enviromentObject")
                } else if let error = error {
                    self.loginState = .signedOut
                    print("There was an error restoring the previous sign-in: \(error)")
                } else {
                    self.loginState = .signedOut
                    print("user state signed out ")
                }
            }
            
        }catch{
            //here is the case user is not signed in or signed out
            print(error.localizedDescription)
            print("user never been singed in before ")
            self.loginState = .initial
            
        }
    }

    
    /* call the loginService Sign - In (currently GoogleLoginService)
     
     but since it is protocol it can be different sign - in service like FacebookLogin
     and that  different service can be assigned using a dependencey injection
     
     */
    func signIn(completion:@escaping () -> Void){
        //TODO can be assigned different Login Service 
        
        loginService.signIn { [weak self] adventureUser in
            //check the user data
            print("loginService.login completionHandlder =======>")
            print(adventureUser.signed_in)
            print("user fullName \(adventureUser.fullName ?? "No FallName")")
            print("user email \(adventureUser.emailAddress ?? "No Email")")
            print("user token  \(adventureUser.idToken?.count ?? 0)")
            
            // update user object 
            self?.userData = adventureUser
            completion()
        }

    }
   
    
    func signOut(){
        //delete User deafult
        UserDefaults.resetStandardUserDefaults()
        //disconnect youtube access
        loginService.disconnectAdditionalScope()
        //sign out from google
        loginService.signOut()
        
        
    }
    
    
    func requestMoreAccess(completion : @escaping () -> Void ){
        //change loginState
        /// This single line make everything not working
        /// since loginState was publisher for the view it will trigger all the viiews update
        /// once state has been changed
        ///
        /// in my case it has updated just before  request youtube service which needs
        /// both YoutubeService & MyStoryListModelView .
        ///
        /// since MyStoryListModelView has been initialize at MyStoryView  anytime
        /// MyStoryView hsa been initialise it will be initialize as well
        /// so moment just before call the  YoutubeService and update loginState will causing
        /// reinitalize MyStoriesView and also create New YoutubeService with New MyStoryListViewModel
        /// will be the reason of deinitialize of origianal both object 
        //loginState = .youtubeAccessRequest
        loginService.addMoreScope(completion:completion)
    }
    
    
//    func disconnectPrivilegeAndSignedOut(){
//        loginService.disconnectAdditionalScope()
//    }
    
    /// The user-authorized scopes.
    /// - note: If the user is logged out, then this will default to empty.
    var authorizedScopes: [String] {
      switch loginState {
      case .signedIn(let user):
        return user.grantedScopes ?? []
      case .signedOut:
        return []
      case .initial:
        return []
      }
    }

    
    deinit{
        print("Deinitialize Login Manager")
    }
    
    var hasYoutubeAccessScope:Bool{
        return authorizedScopes.contains(YoutubeAPIService.youtubeContentReadScope)
    }
}


extension LoginManager  {
    enum State : Equatable{
        case signedIn(GIDGoogleUser)
        case signedOut
        case initial
    }
}
