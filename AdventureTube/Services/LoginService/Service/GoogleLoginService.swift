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

//https://developers.google.com/identity/sign-in/ios/start-integrating
/*
 1)  OAuth Client ID
 
 ClientId  is App's OAuth client ID to identify itself to Google's authentication backend.
 for iOS and mac OS the "OAuth clientID application type" must be configured as iOS.
 here is my clintID section .
 https://console.cloud.google.com/projectselector2/apis/credentials?project=_&supportedpurview=project
 => clientID has been moved to info.plist
 clientID = "657433323337-c4p5785b3e7dirj8l19egvcuaug45eei.apps.googleusercontent.com"
 
 2)  OAuth Server Client
 App will need to pass the identity of signed-in users to backend service.
 To securely pass the identity of users who signed in with Google to backend , use the ID token.
 Retrieving a user's ID token requires server client ID which represents backend server
 => serverClientID  has been moved to info.plist
 serverClientID = "657433323337-t5e70nbjmink2ldmt3e34pci55v3sv6k.apps.googleusercontent.com"
 */

import Foundation
import GoogleSignIn
import Combine
//import GoogleAPIClientForREST

/// An observable class for authenticating via Google.
final class GoogleLoginService: LoginServiceProtocol {
    
    
    
    private var adventuretubeAPI: AdventureTubeAPIPrototol
    private var cancellables = Set<AnyCancellable>()
    
    
    /// Creates an instance of this authenticator.
    /// - parameter authViewModel: The view model this authenticator will set logged in status on.
    init(apiService:AdventureTubeAPIPrototol = AdventureTubeAPIService.shared) {
        self.adventuretubeAPI = apiService
    }
    
    /// Signs in the user based upon the selected account.'
    /// - note: Successful calls to this will set the `authViewModel`'s `state` property.
    /// update Signin  to accept a completion handler that can pass back an error :
    /// wrap the UserModel and Error with Result to use .success and .failure
    ///
    /// Update the signIn method to ensure completion is only called after the registerUser call completes:
    
    
    //func signIn(completion: @escaping (UserModel) -> Void) {
    func signIn(completion:@escaping(Result<UserModel,Error>) -> Void){
        
        guard let rootViewController =  UIApplication.shared.windows.first?.rootViewController else {
            print("There is no root view controller!")
            return
        }
        
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            
            //step1  make sure there is no error in signIn process
            if let error = error {
                completion(.failure(error))
                return
            }
            //step2 get the signInResult
            guard let signInResult = signInResult else { return }
            let user = signInResult.user
            print("Initial Google Signed in Success")
            
            //step3 create adventuretube userModel base on information from google user object
            //and user set as  logged in but there will be update as logged out if any follow process
            //has a issue
            var adventureUser  = self.createAdventureUser(from: user);
            
            //step4 try to refresh token
            //https://developers.google.com/identity/sign-in/ios/backend-auth
            signInResult.user.refreshTokensIfNeeded {[weak self] user, error in
                guard let self = self , let user = user , error  == nil else {
                    if let error = error {
                        completion(.failure(error))
                    }
                    return
                }
                
                //step5 get the update user info from the google
                if let idToken = user.idToken , let userId = user.userID  {
                    //not quite sure to cast to String type
                    adventureUser.idToken = idToken.tokenString
                    adventureUser.googleUserId = userId
                }else{
                    print("idToken for Backend Server retrieve failed!!!!");
                    completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "idToken for Backend Server retrieve failed"])))
                }
                
                //step6 check the JWT  token
                //if user doesn't have a adventuretube UserID  => user need to register
                //if user doesn't have token but have a UserID => user need to login and get token
                
                if adventureUser.adventureTube_id != nil{
                    
                    //user need to login again since logout has been done
                    print("user need to login with password")
                    adventuretubeAPI.loginWithPassword(adventureUser: adventureUser)
                        .sink(receiveCompletion: { completionSink in
                            switch completionSink {
                                case .finished:
                                    print("Request finished successfully")
                                case .failure(let error):
                                    print("BackEnd Connection Error: \(error.localizedDescription)")
                                    adventureUser.signed_in = false;
                                    completion(.failure(error))
                                    //TODO: need to show up error message and ask to retry again later
                            }
                        }, receiveValue: { authResponse in
                            // Process the received authResponse
                            guard let accessToken = authResponse.accessToken ,
                                  let refreshToken = authResponse.refreshToken 
                                  //let userDetail  = authResponse.userDetails
                            else{
                                print("Failed to retreive token from backend")
                                adventureUser.signed_in = false;
                                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve token from backend"])
                                completion(.failure(error))
                                //TODO:  need to show the error to user
                                return
                            }
                            //TODO: need to validate a token later
                            adventureUser.adventuretubeJWTToken = accessToken
                            adventureUser.adventuretubeRefreshJWTToken = refreshToken
                            adventureUser.signed_in = true
                            //MARK: Store Data in UserDefault
                            print("adventureUser.adventuretubeJWTToken:  \(accessToken)");
                            completion(.success(adventureUser))
                        })
                        .store(in: &cancellables)
                }else{
                    //user need to register
                    print("user need to register")
                    adventuretubeAPI.registerUser(adventureUser: adventureUser)
                        .sink(receiveCompletion: { completionSink in
                            switch completionSink {
                                case .finished:
                                    print("Request finished successfully")
                                case .failure(let error):
                                    print("BackEnd Connection Error: \(error.localizedDescription)")
                                    adventureUser.signed_in = false;
                                    completion(.failure(error))
                                    //TODO: need to show up error message and ask to retry again later
                            }
                        }, receiveValue: { authResponse in
                            // Process the received authResponse
                            guard let accessToken = authResponse.accessToken ,
                                  let refreshToken = authResponse.refreshToken ,
                                  let userId = authResponse.userId
                            else{
                                print("Failed to retreive token from backend")
                                adventureUser.signed_in = false;
                                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve token from backend"])
                                completion(.failure(error))
                                //TODO:  need to show the error to user
                                return
                            }
                            //TODO: need to validate a token later
                            adventureUser.adventuretubeJWTToken = accessToken
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
    
    func restorePreviousSignIn(completion:@escaping(Result<UserModel,Error>) -> Void) {
        GIDSignIn.sharedInstance.restorePreviousSignIn {[weak self] user , error in
            guard let self = self else {return}
            //TODO: need to AdventuretubeAPIService
            if let user = user {
                var adventureUser  = self.createAdventureUser(from: user);

                
                //TODO: refresh token
                adventuretubeAPI.refreshToken(adventureUser: adventureUser)
                    .sink(receiveCompletion: { completionSink in
                        switch completionSink {
                            case .finished:
                                print("Request finished successfully")
                            case .failure(let error):
                                print("BackEnd Connection Error: \(error.localizedDescription)")
                                adventureUser.signed_in = false;
                                completion(.failure(error))
                                //TODO: need to show up error message and ask to retry again later
                        }
                    }, receiveValue: { authResponse in
                        // Process the received authResponse
                        guard let accessToken = authResponse.accessToken ,
                              let refreshToken = authResponse.refreshToken
                              //let userDetail  = authResponse.userDetails
                        else{
                            print("Failed to retreive token from backend")
                            adventureUser.signed_in = false;
                            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve token from backend"])
                            completion(.failure(error))
                            //TODO:  need to show the error to user
                            return
                        }
                        //TODO: update token
                        adventureUser.adventuretubeJWTToken = accessToken
                        adventureUser.adventuretubeRefreshJWTToken = refreshToken
                        //adventureUser.signed_in = true
                        print("adventureUser.adventuretubeJWTToken:  \(accessToken)");
                        completion(.success(adventureUser))
                    })
                    .store(in: &cancellables)
                
                
                completion(.success(adventureUser))
                print("user setting has been stored in enviromentObject")
            } else if let error = error {
                print("There was an error restoring the previous sign-in: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    /// Signs out the current user.
    func signOut(completion: @escaping (_ result: Result<Void, Error>) -> Void) {
        GIDSignIn.sharedInstance.signOut()
        //sign Out from backend server
        adventuretubeAPI.signOut()
            .sink(receiveCompletion: { completionSink in
                switch completionSink {
                    case .finished:
                        print("logout finished successfully")
                        completion(.success(()))
                    case .failure(let error):
                        print("Error: \(error.localizedDescription)")
                        completion(.failure(error))
                }
            }, receiveValue: { response in
                // Process the received authResponse
                guard let message = response.message ,
                      let detail = response.details
                else{
                    print("Failed to logut from backend")
                    return
                }
                //TODO need to validate a token later
                
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
        
        //TODO: this doesn't copy the value why ? check the LoginManager.shared.userData first
        var userData : UserModel = LoginManager.shared.publicUserData
        userData.idToken = idToken
        userData.emailAddress = emailAddress
        userData.fullName = fullName
        userData.familyName = familyName
        userData.profilePicUrl = profilePicUrl?.absoluteString
        userData.loginSource = .google
        
        return userData
    }
    
    
    
    /// Adds the youtube channel  read scope for the current user.
    /// - parameter completion: An escaping closure that is called upon successful completion of the
    /// `addScopes(_:presenting:)` request.
    /// - note: Successful requests will update the `loginManager.state` with a new current user that
    /// has the granted scope.
    func addMoreScope(completion : @escaping () -> Void) {
        
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            fatalError("No root view controller!")
        }
        /*
         migration to Google Sign-In SDK v7.0.0  https://developers.google.com/identity/sign-in/ios/quick-migration-guide
         
         The addScopes: https://developers.google.com/identity/sign-in/ios/api-access#2_request_additional_scopes
         method has been moved to GIDGoogleUser.
         Instead of requesting additional authorization scopes from GIDSignIn,
         you should now request them from GIDGoogleUser after authentication has completed
         
         */
        
        guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
            fatalError("No user signed in!")
        }
        
        currentUser.addScopes([YoutubeAPIService.youtubeContentReadScope], presenting: rootViewController){ signInResult,error in
            guard error == nil else {
                print("Found error while Youtube read scope: \(error).")
                return
            }
            guard let signInResult = signInResult else { return }
            //TODO:  Check if the user granted access to the scopes you requested.
            completion()
        }
    }
    
    
    
    /// Disconnects the previously granted scope and signs the user out.
    func disconnectAdditionalScope() {
        GIDSignIn.sharedInstance.disconnect { error in
            if let error = error {
                print("Encountered error disconnecting scope: \(error).")
            }
        }
    }
    
    
}
