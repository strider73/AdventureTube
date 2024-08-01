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
///To ensure that userData and loginState can only be modified within the LoginManager class but still allow read access from outside,
///Use a combination of private(set) and public computed properties.
/// This setup restricts the ability to set the properties directly outside of LoginManager, while still providing read access.
class LoginManager : ObservableObject  {
    static let shared = LoginManager()
    // Properties with private(set) to restrict external modification
    @Published private(set) var userData: UserModel = UserModel()
    @Published private(set) var loginState: State = .initial {
        willSet {
            switch newValue {
                case .signedIn:
                    print("loginState :===signedIn===")
                    saveUserStateToUserDefault()

                case .signedOut:
                    print("loginState :===signedOut===")
                    userData.adventuretubeJWTToken = nil
                    userData.adventuretubeRefreshJWTToken = nil
                    userData.idToken = nil
                    userData.signed_in = false
                    userData.storedScopes.removeAll()
                    saveUserStateToUserDefault()

                case .initial:
                    print("loginState :===initial===")
            }
        }
    }

    
    var hasYoutubeAccessScope:Bool{
        return userData.storedScopes.contains(YoutubeAPIService.youtubeContentReadScope)
    }
    
    
    
    
    
    // TODO: Google Login only at ths moment so loginService property setting need to change later
    private var loginService : LoginServiceProtocol?
    
    
    func updateUserData(_  updateUserData: UserModel) {
        self.userData = updateUserData
    }
    
    func updateLoginState( _ updateState: State) {
        self.loginState = updateState
    }
    
    private init(){
        // MARK: check the UserDefault
        print("init LoginManager")
        do{
            // MARK: step1 bring the userModel from the UserDefault Object
            /// if user never logged in before   there will be no adventureUser that can be extracted from UserDefaut
            /// so process will go to catch stratight away
            let adventureUser = try UserDefaults.standard.getObject(forKey: "user", castTo: UserModel.self)
            self.userData = adventureUser
            /// if user is log
            if adventureUser.signed_in == true {
                // MARK: step2 check the loginSource and initiate loginService instance accordinly
                switch(adventureUser.loginSource){
                    case .google:
                        // MARK:  in here AdventureTubeAPI called and intialize first time
                        loginService = GoogleLoginService()
                        if let  loginService = loginService{
                            loginService.restorePreviousSignIn(completion: {[weak self] result in
                                guard let self = self else {return}
                                
                                // MARK: in here returned googleUser may have updated information for tokenId!
                                switch result {
                                    case .success(let adventureUser):
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
                        // Update user object and loginState
                        self.userData = adventureUser
                        self.loginState = .signedIn
                        //MARK: Store Data in UserDefault
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
                        //STEP 1
                        loginService.disconnectAdditionalScope()
                        //STEP2
                        loginState = .signedOut
                    case .failure(let error):
                        print("Sign out failed: \(error.localizedDescription)")
                        // Handle sign out failure
                }
            }
        }
        
        
    }
    
    
    func requestMoreAccess(completion: @escaping (Error?) -> Void) {
        print("requestMoreAccess  has been called~~~")
        
        if let loginService = loginService {
            loginService.addMoreScope {[weak self]result in
                guard let self = self else {return}

                switch result{
                    case .success(let adventureUser):
                        userData.storedScopes.append(contentsOf: adventureUser.storedScopes)
                        saveUserStateToUserDefault()
                        completion(nil)
                    case .failure(let error ):
                        print("Error requesting additional scopes: \(error.localizedDescription)")
                        completion(NSError(domain: "com.adventuretube", code: -1, userInfo: [NSLocalizedDescriptionKey: "Login service not available"])) // Handle loginService nil case
                }
                
            }
        }
    }

    
    deinit{
        print("Deinitialize Login Manager")
    }
    
    
    
    private func saveUserStateToUserDefault(){
        
        let userDefaults = UserDefaults.standard
        
        do {
            try userDefaults.setObject( userData, forKey: "user")
            print("User data has been saved to UserDefault")
        }catch{
            print(error.localizedDescription)
        }
    }
}



extension LoginManager  {
    enum State : Equatable{
        case signedIn
        case signedOut
        case initial
    }
}


