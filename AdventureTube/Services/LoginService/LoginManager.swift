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
    static let shared = LoginManager()
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
    
    // TODO: Google Login only at ths moment so loginService property setting need to change later
    private var loginService : LoginServiceProtocol?
    
    private init(){
        // MARK: check the UserDefault
        print("init LoginManager")
        do{
            // MARK: step1 bring the userModel from the UserDefault Object
            /// if user never logged in before   there will be no adventureUser that can be extracted from UserDefaut
            /// so process will go to catch stratight away
            let adventureUser = try UserDefaults.standard.getObject(forKey: "user", castTo: UserModel.self)
            self.userData = adventureUser

            if adventureUser.signed_in == true {
                // MARK: step2 check the loginSource and initiate loginService instance accordinly
                switch(adventureUser.loginSource){
                    case .google:
                        // MARK:  in here AdventureTubeAPI called and intialize first time
                        loginService = GoogleLoginService()
                        if let  loginService = loginService{
                            loginService.restorePreviousSignIn(completion: { result in
                                // MARK: in here returned googleUser may have updated information for tokenId!
                                switch result {
                                    case .success(let googleUser):
                                        //MARK: not use any data from googleUser
                                        //check the user data
                                        print("loginService.restorePreviousSignIn completionHandlder =======>")
                                        print("googleUser.idToken :\(googleUser.idToken)")
                                        print("user fullName \(adventureUser.fullName ?? "No FallName")")
                                        print("user email \(adventureUser.emailAddress ?? "No Email")")
                                        print("user token  \(adventureUser.idToken?.count ?? 0)")
                                        // Update user object
                                        self.userData = adventureUser
                                        self.loginState = .signedIn
                                    case .failure(let error):
                                        print("error : \(error.localizedDescription)")
                                        self.loginState = .signedOut
                                        
                                }
                            })
                        }
                    case .apple:
                        print("apple login is not implemented yet")
                    case .facebook:
                        print("facebook login is not implemented yet")
                    case .instagram:
                        print("instagram login is not implemented yet")
                    case .twitter:
                        print("twitter login  is not implemented yet")
                    case .none:
                        print("user never been signed in !!!")
                }
            }else{
                loginState = .signedOut
            }
            
        }catch{
            //here is the case user is not signed in or signed out
            print(error.localizedDescription)
            print("user never been singed in before ")
            self.loginState = .initial
            
        }
    }
    
    ///call the loginService Sign - In (currently GoogleLoginService)
    ///but since it is protocol it can be different sign - in service like FacebookLogin
    ///and that  different service can be assigned using a dependencey injection
    ///
    ///update completion handller that can pass back an error
    ///wrap the UserModel and Error with Result to use .success and .failure
    func googleSignIn(completion:@escaping (Result<UserModel, Error>) -> Void){
        //TODO: can be assigned different Login Service so  loginService property need to be assigned accordingly
        
        loginService = GoogleLoginService()
        
        if let loginService = loginService{
           loginService.signIn{ [weak self] result in
                guard let self = self else {return}
                switch result {
                    case .success(let adventureUser):
                        //check the user data
                        print("loginService.login completionHandlder =======>")
                        print(adventureUser.signed_in)
                        print("user fullName \(adventureUser.fullName ?? "No FallName")")
                        print("user email \(adventureUser.emailAddress ?? "No Email")")
                        print("user token  \(adventureUser.idToken?.count ?? 0)")
                        // Update user object
                        self.userData = adventureUser
                        completion(.success(adventureUser))
                        
                    case .failure(let error):
                        completion(.failure(error))
                }
            }
        }
        
    }
    func facebookSignIn(){
        print("No Facebook SignIn Support Yet")
    }
    
    
    func twitterSignIn(){
        print("No Twitter SignIn Support Yet")
    }
    
    
    func signOut(){
        if let loginService = loginService{
            //sign out from google
            loginService.signOut {[weak self] result in
                guard let self = self else {return}
                
                switch result {
                    case .success:
                        print("Sign out successful")
                        //delete User deafult
                        do {
                            var adventureUser = try UserDefaults.standard.getObject(forKey: "user", castTo: UserModel.self)
                            adventureUser.adventuretubeJWTToken = nil
                            adventureUser.adventuretubeRefreshJWTToken = nil
                            adventureUser.idToken = nil
                            adventureUser.signed_in = false
                            try UserDefaults.standard.setObject(adventureUser, forKey: "user")
                        } catch {
                            print("Failed to update user in UserDefaults: \(error.localizedDescription)")
                        }
                        
                        loginService.disconnectAdditionalScope()
                        loginState = .signedOut
                        
                    case .failure(let error):
                        print("Sign out failed: \(error.localizedDescription)")
                        // Handle sign out failure
                }
            }
        }
        
        
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
        if let loginService = loginService {
            loginService.addMoreScope(completion:completion)
        }
    }
    
    
    //    func disconnectPrivilegeAndSignedOut(){
    //        loginService.disconnectAdditionalScope()
    //    }
    
    /// The user-authorized scopes.
    /// - note: If the user is logged out, then this will default to empty.
    var authorizedScopes: [String] {
        switch loginState {
            case .signedIn:
                return  []
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
        case signedIn
        case signedOut
        case initial
    }
}


