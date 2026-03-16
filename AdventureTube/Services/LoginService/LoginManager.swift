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
 TODO: Add loginService cleanup and reuse logic
 */

import Foundation

/// LoginManager combines Singleton + ObservableObject patterns to provide:
/// - Single source of truth for authentication state (Singleton)
/// - Automatic UI updates without manual refresh calls (ObservableObject)
/// - Properties use private(set) for controlled external access while enabling reactive updates
class LoginManager: ObservableObject {

    // MARK: - Singleton

    static let shared = LoginManager()

    // MARK: - Published Properties

    @Published private(set) var userData: UserModel = UserModel()
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
                    userData.adventuretubeAcessJWTToken = nil
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

    // MARK: - Computed Properties

    var hasYoutubeAccessScope: Bool {
        return userData.storedScopes.contains(YoutubeAPIService.youtubeContentReadScope)
    }

    // MARK: - Private Properties

    /// Skip UserDefaults save during init to avoid overwriting stored tokens
    private var isRestoringSession = false
    // TODO: Google Login only at this moment so loginService property setting need to change later
    private var loginService: LoginServiceProtocol?

    // MARK: - Init

    private init() {
        print("init LoginManager")

        /// Attempts to retrieve the `UserModel` from `UserDefaults`.
        /// - If successful, it indicates the user is already registered and has a valid `adventureTube_id`.
        /// - If the retrieval fails, an error is thrown, and the user is assumed to have never signed in.
        do {
            let adventureUser = try UserDefaults.standard.getObject(forKey: "user", castTo: UserModel.self)
            self.userData = adventureUser

            if adventureUser.signed_in == true {
                switch(adventureUser.loginSource) {
                    case .google:
                        // Set signedIn immediately so HomeView shows the main app
                        // while tokens are refreshed in the background
                        isRestoringSession = true
                        loginState = .signedIn
                        isRestoringSession = false
                        loginService = GoogleLoginService()
                        if let loginService = loginService {
                            loginService.restorePreviousSignIn(completion: { [weak self] result in
                                guard let self = self else { return }
                                switch result {
                                    case .success(let adventureUser):
                                        self.userData = adventureUser
                                        self.loginState = .signedIn
                                    case .failure(let error):
                                        print("error : \(error.localizedDescription)")
                                        // Only sign out if server explicitly rejected the tokens (401/403)
                                        // For network errors (server down, timeout, no internet),
                                        // keep the session alive so tokens aren't wiped
                                        if let backendError = error as? BackendError,
                                           case .unauthorized = backendError {
                                            print("Server rejected tokens — signing out")
                                            self.loginState = .signedOut
                                        } else {
                                            print("Network/server error — keeping session with existing tokens")
                                            // Stay signed in with existing tokens
                                            // They will be refreshed on the next successful API call
                                        }
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
                        print("twitter login is not implemented yet")
                    case .none:
                        print("user never been signed in !!!")
                }
            } else {
                loginState = .signedOut
            }
        } catch {
            print(error.localizedDescription)
            print("user never been signed in before")
            self.loginState = .initial
        }
    }

    deinit {
        print("Deinitialize Login Manager")
    }

    // MARK: - Public Methods (State Updates)

    func updateUserData(_ updateUserData: UserModel) {
        self.userData = updateUserData
    }

    func updateLoginState(_ updateState: State) {
        self.loginState = updateState
    }

    // MARK: - Sign In

    /// Call the loginService Sign-In (currently GoogleLoginService)
    /// Since it is protocol-based, it can be a different sign-in service like FacebookLogin
    /// and that different service can be assigned using dependency injection
    func googleSignIn(completion: @escaping (Result<UserModel, Error>) -> Void) {
        // TODO: can be assigned different Login Service so loginService property need to be assigned accordingly
        loginService = GoogleLoginService()

        if let loginService = loginService {
            loginService.signIn { [weak self] result in
                guard let self = self else { return }
                switch result {
                    case .success(let adventureUser):
                        print("loginService.login completionHandler =======>")
                        print(adventureUser.signed_in)
                        print("user fullName \(adventureUser.fullName ?? "No FullName")")
                        print("user email \(adventureUser.emailAddress ?? "No Email")")
                        print("user token \(adventureUser.idToken?.count ?? 0)")
                        self.userData = adventureUser
                        self.loginState = .signedIn
                        completion(.success(adventureUser))
                    case .failure(let error):
                        completion(.failure(error))
                }
            }
        }
    }

    func facebookSignIn() {
        print("No Facebook SignIn Support Yet")
    }

    func twitterSignIn() {
        print("No Twitter SignIn Support Yet")
    }

    // MARK: - Sign Out

    func signOut() {
        if let loginService = loginService {
            loginService.signOut { [weak self] result in
                guard let self = self else { return }
                switch result {
                    case .success:
                        print("Sign out successful")
                        loginService.disconnectAdditionalScope()
                        loginState = .signedOut
                    case .failure(let error):
                        print("Sign out failed: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Scope Management

    func requestMoreAccess(completion: @escaping (Error?) -> Void) {
        print("requestMoreAccess has been called~~~")

        if let loginService = loginService {
            loginService.addMoreScope { [weak self] result in
                guard let self = self else { return }
                switch result {
                    case .success(let adventureUser):
                        userData.storedScopes.append(contentsOf: adventureUser.storedScopes)
                        saveUserStateToUserDefault()
                        completion(nil)
                    case .failure(let error):
                        print("Error requesting additional scopes: \(error.localizedDescription)")
                        completion(NSError(domain: "com.adventuretube", code: -1, userInfo: [NSLocalizedDescriptionKey: "Login service not available"]))
                }
            }
        }
    }

    // MARK: - Persistence

    private func saveUserStateToUserDefault() {
        do {
            try UserDefaults.standard.setObject(userData, forKey: "user")
            print("User data has been saved to UserDefault")
        } catch {
            print(error.localizedDescription)
        }
    }
}

// MARK: - State Enum

extension LoginManager {
    enum State: Equatable {
        case signedIn
        case signedOut
        case initial
    }
}
