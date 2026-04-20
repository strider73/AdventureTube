/*
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 GoogleLoginService - Google Authentication Implementation

 CONFIGURATION:
 - OAuth Client ID: Configured in Info.plist for iOS app identification
 - Server Client ID: Configured in Info.plist for backend authentication
 - Reference: https://developers.google.com/identity/sign-in/ios/start-integrating

 AUTHENTICATION FLOW:
 1. Google OAuth sign-in with UI presentation
 2. Token refresh and ID token retrieval
 3. Backend authentication (register new users or login existing users)
 4. JWT token storage for API access
 5. YouTube scope management for content access

 BACKEND INTEGRATION:
 - Uses AdventureTubeAPIService for user registration/login
 - Manages JWT tokens for authenticated API requests
 - Handles token refresh automatically
 */

import Foundation
import GoogleSignIn
import Combine
//import GoogleAPIClientForREST

/// Google authentication service implementing LoginServiceProtocol.
///
/// Handles complete Google OAuth flow including:
/// - User sign-in/sign-out with Google
/// - Backend user registration and authentication
/// - JWT token management
/// - YouTube API scope requests
/// - Session restoration
final class GoogleLoginService: LoginServiceProtocol {


    private var adventuretubeAPI: AdventureTubeAPIProtocol
    private var cancellables = Set<AnyCancellable>()
    
    
    /// Creates a GoogleLoginService instance.
    /// - Parameter apiService: Backend API service for user authentication (defaults to shared instance)
    init(apiService:AdventureTubeAPIProtocol = AdventureTubeAPIService.shared) {
        self.adventuretubeAPI = apiService
    }
    
    
    /// Signs in user with Google authentication and backend registration/login.
    ///
    /// **Usage:** Called from LoginView when user taps the Google Login button
    ///
    /// Performs complete authentication flow:
    /// 1. Google OAuth sign-in with UI presentation
    /// 2. Token refresh and validation
    /// 3. Backend authentication (register new users or login existing users)
    /// 4. JWT token retrieval and storage
    ///
    /// - Parameter completion: Result callback with authenticated UserModel or error
    /// - Note: Completion is called only after all backend authentication steps complete
    func signIn(completion:@escaping(Result<UserModel,Error>) -> Void){
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("There is no root view controller!")
            return
        }
        
        ///https://developers.google.com/identity/sign-in/ios/reference/Classes/GIDSignIn
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            
            // STEP 1: Validate Google sign-in response
            if let error = error {
                completion(.failure(error))
                return
            }
            // STEP 2: Extract user data from sign-in result
            guard let signInResult = signInResult else { return }
            let user = signInResult.user
            print("Initial Google Signed in Success")
            
            // STEP 3: Create AdventureTube user model from Google user data
            // Note: User is initially marked as logged in, but will be updated if backend authentication fails
            var adventureUser  = self.createAdventureUser(from: user);
            
            // STEP 4: Authenticate with backend server
            // Reference: https://developers.google.com/identity/sign-in/ios/backend-auth
            // Refreshes Google tokens if needed before backend communication
            // Ensures fresh idToken is available for backend validation
    
            signInResult.user.refreshTokensIfNeeded {[weak self] user, error in
                guard let self = self , let user = user , error  == nil else {
                    if let error = error {
                        completion(.failure(error))
                    }
                    return
                }
                
                // STEP 5: Extract updated token information from Google
                if let idToken = user.idToken , let userId = user.userID  {
                    // Store Google ID token and user ID for backend authentication
                    adventureUser.idToken = idToken.tokenString
                    adventureUser.googleUserId = userId
                }else{
                    print("idToken for Backend Server retrieve failed!!!!");
                    completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "idToken for Backend Server retrieve failed"])))
                }
                
                // STEP 6: Determine backend authentication flow
                // - No AdventureTube ID: New user registration required
                // - Has AdventureTube ID: Existing user login required

                if adventureUser.adventureTube_id != nil{

                    // Existing user: Login with backend to refresh JWT tokens
                    print("Existing user detected - performing backend login")
                    adventuretubeAPI.loginWithGoogleIdToken(adventureUser: adventureUser)
                        .sink(receiveCompletion: { completionSink in
                            if case .failure(let error) = completionSink {
                                print("BackEnd Connection Error: \(error.localizedDescription)")
                                adventureUser.signed_in = false
                                completion(.failure(error))
                            }
                        }, receiveValue: { response in
                            self.handleSuccessfulLoginTokenResponse(response, adventureUser: &adventureUser, completion: completion)
                        })
                        .store(in: &cancellables)
                }else{
                    // New user: Register with backend to create account
                    print("New user detected - performing backend registration")
                    adventuretubeAPI.registerUser(adventureUser: adventureUser)
                        .sink(receiveCompletion: {[weak self] completionSink in
                            guard let self = self else { return }
                            switch completionSink {
                                case .finished:
                                    print("Request finished successfully")
                                case .failure(let error):
                                    // 409 Conflict: User already exists on backend (e.g. app reinstall)
                                    // Fall back to login instead of failing
                                    if let backendError = error as? BackendError,
                                       case .conflict = backendError {
                                        print("User already exists (409 Conflict) - falling back to login")
                                        self.adventuretubeAPI.loginWithGoogleIdToken(adventureUser: adventureUser)
                                            .sink(receiveCompletion: { loginCompletion in
                                                if case .failure(let error) = loginCompletion {
                                                    print("Fallback login also failed: \(error.localizedDescription)")
                                                    adventureUser.signed_in = false
                                                    completion(.failure(error))
                                                }
                                            }, receiveValue: { response in
                                                self.handleSuccessfulLoginTokenResponse(response, adventureUser: &adventureUser, completion: completion)
                                            })
                                            .store(in: &self.cancellables)
                                    } else {
                                        print("BackEnd Connection Error: \(error.localizedDescription)")
                                        adventureUser.signed_in = false
                                        completion(.failure(error))
                                    }
                            }
                        }, receiveValue: { response in
                            // Process the received authResponse
                            guard let tokenData = response.data,
                                  let accessToken = tokenData.accessToken ,
                                  let refreshToken = tokenData.refreshToken ,
                                  let userId = tokenData.userId
                            else{
                                print("Failed to retreive token from backend")
                                adventureUser.signed_in = false;
                                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve token from backend"])
                                completion(.failure(error))
                                // TODO: Display error message to user
                                return
                            }
                            // TODO: Add JWT token validation before storing
                            adventureUser.adventuretubeAcessJWTToken = accessToken
                            adventureUser.adventuretubeRefreshJWTToken = refreshToken
                            adventureUser.adventureTube_id = userId
                            adventureUser.signed_in = true
                            print("adventureUser.adventuretubeJWTToken:  \(accessToken)");
                            completion(.success(adventureUser))
                        })
                        .store(in: &cancellables)
                }//end of user register
            }//end of google refresh token
        }//end of google login
    }
    
    
    /// Shared token handler for both direct login and fallback login flows.
    /// Extracts tokens from the response and marks the user as signed in.
    private func handleSuccessfulLoginTokenResponse(
        _ response: ServiceResponse<AuthTokenData>,
        adventureUser: inout UserModel,
        completion: (Result<UserModel, Error>) -> Void
    ) {
        guard let tokenData = response.data,
              let accessToken = tokenData.accessToken,
              let refreshToken = tokenData.refreshToken
        else {
            print("Failed to retrieve token from backend")
            adventureUser.signed_in = false
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve token from backend"])
            completion(.failure(error))
            return
        }
        adventureUser.adventuretubeAcessJWTToken = accessToken
        adventureUser.adventuretubeRefreshJWTToken = refreshToken
        adventureUser.signed_in = true
        print("Login successful - accessToken: \(accessToken)")
        completion(.success(adventureUser))
    }
    
    
    /// Restores previous Google sign-in session and refreshes backend tokens.
    ///
    /// **Usage:** Automatically called during app initialization by LoginManager
    ///
    /// Restores user sessions and refreshes JWT tokens with backend
    /// to ensure valid authentication state on app startup.
    ///
    /// - Parameter completion: Result callback with restored UserModel or error
    func restorePreviousSignIn(completion:@escaping(Result<UserModel,Error>) -> Void) {
        GIDSignIn.sharedInstance.restorePreviousSignIn {[weak self] user , error in
            guard let self = self else {return}
            // Restore previous session using existing Google credentials
            if let user = user {
                var adventureUser  = self.createAdventureUser(from: user);
                
                
                // Refresh backend JWT tokens for restored session
                adventuretubeAPI.refreshToken(adventureUser: adventureUser)
                    .sink(receiveCompletion: { completionSink in
                        switch completionSink {
                            case .finished:
                                print("Request finished successfully")
                            case .failure(let error):
                                print("BackEnd Connection Error: \(error.localizedDescription)")
                                // Only mark as signed out if server explicitly rejected tokens
                                // For network errors, keep signed_in so tokens aren't wiped
                                if let backendError = error as? BackendError,
                                   case .unauthorized = backendError {
                                    adventureUser.signed_in = false
                                }
                                completion(.failure(error))
                        }
                    }, receiveValue: { response in
                        // Process the received authResponse
                        guard let tokenData = response.data,
                              let accessToken = tokenData.accessToken ,
                              let refreshToken = tokenData.refreshToken
                                //let userDetail  = authResponse.userDetails
                        else{
                            print("Failed to retreive token from backend")
                            adventureUser.signed_in = false;
                            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve token from backend"])
                            completion(.failure(error))
                            // TODO: Display error message to user
                            return
                        }
                        // Update user model with refreshed tokens
                        adventureUser.adventuretubeAcessJWTToken = accessToken
                        adventureUser.adventuretubeRefreshJWTToken = refreshToken
                        adventureUser.signed_in = true
                        print("adventureUser.adventuretubeJWTToken:  \(accessToken)");
                        completion(.success(adventureUser))
                    })
                    .store(in: &cancellables)
            } else if let error = error {
                print("There was an error restoring the previous sign-in: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    /// Signs out current user from Google and backend services.
    ///
    /// **Usage:** Called from LoginManager when user explicitly signs out
    ///
    /// Performs complete sign-out:
    /// - Google OAuth sign-out
    /// - Backend session termination
    /// - Local token cleanup
    ///
    /// - Parameter completion: Result callback indicating success or error
    func signOut(completion: @escaping (_ result: Result<Void, Error>) -> Void) {
        //sign Out from backend server
        adventuretubeAPI.signOut()
            .sink(receiveCompletion: { completionSink in
                switch completionSink {
                    case .finished:
                        GIDSignIn.sharedInstance.signOut()
                        print("logout finished successfully")
                        completion(.success(()))
                    case .failure(let error):
                        print("Error: \(error.localizedDescription)")
                        completion(.failure(error))
                }
            }, receiveValue: { response in
                guard response.success else {
                    print("Failed to logout from backend: \(response.message ?? "unknown")")
                    return
                }
            })
            .store(in: &cancellables)
    }
    
    
    private func createAdventureUser(from user: GIDGoogleUser) -> UserModel {
        let emailAddress = user.profile?.email ?? "No Email"
        let fullName = user.profile?.name ?? "No Name"
        let givenName = user.profile?.givenName ?? "No Given Name"
        let familyName = user.profile?.familyName ?? "No Family Name"
        let profilePicUrl = user.profile?.imageURL(withDimension: 320)
        let idToken = user.idToken?.tokenString ?? ""
        
        // Initialize user model from LoginManager's current state
        // Note: Preserves existing user data while updating with Google information
        var userData : UserModel = LoginManager.shared.userData
        userData.idToken = idToken
        userData.emailAddress = emailAddress
        userData.fullName = fullName
        userData.familyName = familyName
        userData.profilePicUrl = profilePicUrl?.absoluteString
        userData.loginSource = .google
        if let grantScopes = user.grantedScopes {
            userData.storedScopes.append(contentsOf: grantScopes.map { "\($0)" })
        }
        return userData
    }

    
    
    
    
    /// Requests YouTube content read scope for the current user.
    ///
    /// **Usage:** Called from LoginManager when user needs YouTube API access
    ///
    /// Presents Google authorization UI to grant additional YouTube API access.
    /// Required for fetching user's YouTube videos and channel information.
    ///
    /// - Parameter completion: Result callback with updated UserModel containing new scopes or error
    /// - Note: User must be already signed in before requesting additional scopes
    func addMoreScope(completion : @escaping (Result<UserModel,Error>) -> Void) {
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("There is no root view controller!")
            completion(.failure( NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No root view controller found"])))
            return
        }
        /*
         migration to Google Sign-In SDK v7.0.0  https://developers.google.com/identity/sign-in/ios/quick-migration-guide
         
         The addScopes: https://developers.google.com/identity/sign-in/ios/api-access#2_request_additional_scopes
         method has been moved to GIDGoogleUser.
         Instead of requesting additional authorization scopes from GIDSignIn,
         you should now request them from GIDGoogleUser after authentication has completed
         
         */
        
        guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
            print("No user signed in!")
            completion(.failure( NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user signed in"])))
            return
        }
        
        currentUser.addScopes([YoutubeAPIService.youtubeContentReadScope], presenting: rootViewController){ signInResult,error in
            guard error == nil else {
                print("Found error while Youtube read scope: \(String(describing: error?.localizedDescription)).")
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No scopes granted"])))
                return
            }
            
            
            guard let signInResult = signInResult, let grantedScopes = signInResult.user.grantedScopes else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No scopes granted"])))
                return
            }
            
            
            // Use map to convert the grantedScopes to an array of Strings, if not already.
            let scopes = grantedScopes.map { "\($0)" } // Ensure each scope is a String
            
            // Log each scope for debugging purposes
            scopes.forEach { scope in
                print("User has scope: \(scope)")
            }
            
            let user = signInResult.user
            var adventureUser  = self.createAdventureUser(from: user);
            
            // Complete with the scopes
            completion(.success(adventureUser))
            
        }
    }
    
    
    
    /// Revokes all granted scopes and disconnects Google authentication.
    ///
    /// **Usage:** Called from LoginManager during complete sign-out process
    ///
    /// Completely disconnects the app from user's Google account,
    /// revoking all previously granted permissions including YouTube access.
    func disconnectAdditionalScope() {
        GIDSignIn.sharedInstance.disconnect { error in
            if let error = error {
                print("Encountered error disconnecting scope: \(error).")
            }
        }
    }


}
