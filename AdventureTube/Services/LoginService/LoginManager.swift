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
    
    //TODO:Google Login only at ths moment so loginService property setting need to change later
    private var loginService : LoginServiceProtocol?
    
    private init(){
        //check the UserDefault
        print("init LoginManager")
        do{
            //step1 bring the userModel from the UserDefault Object
            let adventureUser = try UserDefaults.standard.getObject(forKey: "user", castTo: UserModel.self)
            
            
            //step2 check the loginSource and initiate loginService instance accordinly
            switch(adventureUser.loginSource){
                case .google:
                    loginService = GoogleLoginService(loginManager: self)
                    
                    GIDSignIn.sharedInstance.restorePreviousSignIn {[weak self] user, error in
                        guard let self = self else {return}
                        
                        if let user = user {
                            self.loginState = .signedIn
                            print("adventuretube_id :\(adventureUser.adventureTube_id?.uuidString ?? "nil" ) ")
                            print("adventuretube_accessToken : \(adventureUser.adventuretubeJWTToken as String?)")
                            print("email : \(adventureUser.emailAddress as String?)")
                            print("fullName  : \(adventureUser.fullName as String?)")
                            print("profilePicUrl  : \(adventureUser.profilePicUrl as String?)")
                            self.userData = adventureUser
                            AdventureTubeAPIService.shared.userData = self.userData
                            print("user setting has been stored in enviromentObject")
                        } else if let error = error {
                            self.loginState = .signedOut
                            print("There was an error restoring the previous sign-in: \(error)")
                        } else {
                            self.loginState = .signedOut
                            print("user state signed out ")
                        }
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
        //TODO can be assigned different Login Service so  loginService property need to be assigned accordingly
        
        loginService = GoogleLoginService(loginManager: self)
        
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
            //delete User deafult
            UserDefaults.resetStandardUserDefaults()
            //disconnect youtube access
            loginService.disconnectAdditionalScope()
            //sign out from google
            loginService.signOut()
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


