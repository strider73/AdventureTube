//
//  LoginManager.swift
//  AdventureTube
//
//  Created by chris Lee on 21/1/22.
//


/*
 LoginManager - Singleton Authentication Manager

 ARCHITECTURE PATTERNS:

 1. SINGLETON PATTERN:
    - static let shared = LoginManager() - Single instance for entire app lifecycle
    - private init() - Prevents external instantiation
    - Global access point for authentication state across the app
    - Lives for entire app duration (never deallocates)

 2. OBSERVABLE OBJECT PATTERN:
    - Conforms to ObservableObject protocol for SwiftUI reactive programming
    - @Published properties automatically trigger UI updates via objectWillChange publisher
    - Works with @StateObject and @ObservedObject in SwiftUI views
    - Integrates with Combine framework for reactive data flow
    - Views automatically re-render when userData or loginState changes

 RESPONSIBILITIES:
 - Manages user authentication state across the app
 - Handles login/logout operations with Google (future: multiple providers)
 - Persists user data and JWT tokens to UserDefaults
 - Provides reactive state updates via @Published properties
 - Manages YouTube API scope permissions

 IMPLEMENTATION NOTES:
 - Uses protocol-based design (LoginServiceProtocol) for future multi-provider support
 - Currently only implements Google login via GoogleLoginService
 - Properties use private(set) for controlled external access
 - Automatic state persistence on login state changes via willSet observers
 - Single source of truth for authentication state

 TODO: Implement proper dependency injection for loginService
 TODO: Fix potential memory leak in signOut method (line 188)
 TODO: Add loginService cleanup and reuse logic
 */

import Foundation
/// LoginManager combines Singleton + ObservableObject patterns to provide:
/// - Single source of truth for authentication state (Singleton)
/// - Automatic UI updates without manual refresh calls (ObservableObject)
/// - Properties use private(set) for controlled external access while enabling reactive updates
class LoginManager : ObservableObject  {
    static let shared = LoginManager()
    // Properties with private(set) to restrict external modification
    @Published private(set) var userData: UserModel = UserModel()
    /// Skip UserDefaults save during init to avoid overwriting stored tokens
    private var isRestoringSession = false
    @Published private(set) var loginState: State = .initial {
        willSet {
            switch newValue {
                case .signedIn:
                    print("loginState :===signedIn===")
                    if !isRestoringSession {
                        saveUserStateToUserDefault()
                    }

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
        
        /// Attempts to retrieve the `UserModel` from `UserDefaults`.
        /// - If successful, it indicates the user is already registered and has a valid `adventureTube_id`.
        /// - If the retrieval fails, an error is thrown, and the user is assumed to have never signed in.
        ///
        /// This process ensures the app correctly initializes the user's state based on prior usage.
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
                        // Set signedIn immediately so HomeView shows the main app
                        // while tokens are refreshed in the background
                        isRestoringSession = true
                        loginState = .signedIn
                        isRestoringSession = false
                        loginService = GoogleLoginService()
                        if let  loginService = loginService{
                            loginService.restorePreviousSignIn(completion: {[weak self] result in
                                guard let self = self else {return}

                                // MARK: in here returned googleUser may have updated information for tokenId!
                                switch result {
                                    case .success(let adventureUser):
                                        // Update user object with refreshed tokens
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
                //TODO: before update to signed out
                /// need to  use
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


