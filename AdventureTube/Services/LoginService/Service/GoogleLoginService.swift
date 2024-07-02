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
    
    
    
    private var loginManager: LoginManager
    private var cancellables = Set<AnyCancellable>()
    private var adventuretubeAPIService : AdventureTubeAPIPrototol

    
    /// Creates an instance of this authenticator.
    /// - parameter authViewModel: The view model this authenticator will set logged in status on.
    init(loginManager: LoginManager, apiService:AdventureTubeAPIPrototol = AdventureTubeAPIService.shared) {
        self.loginManager = loginManager
        self.adventuretubeAPIService = apiService
    }
    
    /// Signs in the user based upon the selected account.'
    /// - note: Successful calls to this will set the `authViewModel`'s `state` property.
    
    func signIn(completion: @escaping (UserModel?) -> Void) {
        
        guard let rootViewController =  UIApplication.shared.windows.first?.rootViewController else {
            print("There is no root view controller!")
            return
        }
        
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            
            //step1  make sure there is no error in signIn process
            guard error == nil else {
                print("Error! \(String(describing: error))")
                completion(nil)
                return
            }
            //step2 get the signInResult
            guard let signInResult = signInResult else { 
                completion(nil)
                return
            }
            let user = signInResult.user
            print("Initial Google Signed in Success")
            
            //create adventuretube userModel base on information from google user object 
            var adventureUser  = self.createAdventureUser(from: user);
            
            user.refreshTokensIfNeeded {[weak self] refreshedUSer, error in
                guard let self = self else {return}
                guard error == nil else {
                    completion(nil)
                    return
                }
                guard let refreshedUSer = refreshedUSer else {
                    completion(nil)
                    return
                }
                
                if let idToken = refreshedUSer.idToken , let userId = refreshedUSer.userID {
                    
                    //not quite sure to cast to String type
                    adventureUser.idToken = idToken.tokenString
                    adventureUser.userId = userId
                    
                    adventuretubeAPIService.signIn(adventureUser: adventureUser)
                        .sink(receiveCompletion: { completionSink in
                            switch completionSink {
                            case .finished:
                                print("Request finished successfully")
                            case .failure(let error):
                                print("Error: \(error.localizedDescription)")
                                //TODO need to show up error message and ask to retry again later
                                adventureUser.signed_in = false;
                                completion(nil)
                            }
                        }, receiveValue: { authResponse in
                            // Process the received authResponse
                            guard let accessToken = authResponse.accessToken ,
                                  let refreshToken = authResponse.refreshToken else{
                                print("Failed to retreive token from backend")
                                adventureUser.signed_in = false;
                                completion(nil)
                                return
                            }
                            //TODO need to validate a token later 
                            adventureUser.adventuretubeJWTToken = accessToken
                            adventureUser.adventuretubeRefreshJWTToken = refreshToken
                            print("adventureUser.adventuretubeJWTToken:  \(accessToken)");
                            let userDefaults = UserDefaults.standard
                            do {
                                try userDefaults.setObject(adventureUser, forKey: "user")
                                print("user data has been setting in user default ")
                            } catch {
                                print(error.localizedDescription)
                            }
                            self.loginManager.loginState = .signedIn(refreshedUSer)
                        })
                        .store(in: &cancellables)
                    
               
                    
                }else{
                    print("idToken for Backend Server retrieve failed!!!!");
                    completion(nil)
                }

                // return the data to call back method
                completion(adventureUser)
                
            }
        
            
        }
    }
      

    
    //TODO: call this function after create my backend server
    public static func tokenSignInExample(idToken: String) {
        guard let authData = try? JSONEncoder().encode(["idToken": idToken]) else {
            return
        }
        let url = URL(string: "https://yourbackend.example.com/tokensignin")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.uploadTask(with: request, from: authData) { data, response, error in
            // Handle response from your backend.
        }
        task.resume()
        
        /*
         Verify the integrity of the ID token
         
         To verify that the token is valid, ensure that the following criteria are satisfied:
         
         1)The ID token is properly signed by Google. Use Google's public keys (available in JWK or PEM format) to verify the token's signature.
         These keys are regularly rotated; examine the Cache-Control header in the response to determine when you should retrieve them again.
         
         2)The value of aud in the ID token is equal to one of your app's client IDs.
         This check is necessary to prevent ID tokens issued to a malicious app being used to access data about the same user on your app's backend server.
         
         3)The value of iss in the ID token is equal to accounts.google.com or https://accounts.google.com.
         The expiry time (exp) of the ID token has not passed.
         
         4)If you want to restrict access to only members of your G Suite domain, verify that the ID token has an hd claim that matches your G Suite domain name.
         
         
         Rather than writing your own code to perform these verification steps, we strongly recommend using a Google API client library for your platform,
         
         check the link : https://developers.google.com/identity/sign-in/ios/backend-auth
         */
    }
    
    /// Signs out the current user.
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        loginManager.loginState = .signedOut
        //sign Out from backend server
        adventuretubeAPIService.signOut()
            .sink(receiveCompletion: { completionSink in
                switch completionSink {
                case .finished:
                    print("Request finished successfully")
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                    //TODO need to show up error message and ask to retry again later
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
                let userDefaults = UserDefaults.standard
                //self.loginManager.loginState = .signedIn(refreshedUSer)
            })
            .store(in: &cancellables)
        
        
        
        
        
        
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
            self.loginManager.loginState = .signedIn(currentUser)
            //TODO:  Check if the user granted access to the scopes you requested.
            
            completion()
        }
    }
    
    
    
    private func createAdventureUser(from user: GIDGoogleUser) -> UserModel {
           let emailAddress = user.profile?.email ?? "No Email"
           let fullName = user.profile?.name ?? "No Name"
           let givenName = user.profile?.givenName ?? "No Given Name"
           let familyName = user.profile?.familyName ?? "No Family Name"
           let profilePicUrl = user.profile?.imageURL(withDimension: 320)
           
           return UserModel(signed_in: true,
                            emailAddress: emailAddress,
                            fullName: fullName,
                            givenName: givenName,
                            familyName: familyName,
                            profilePicUrl: profilePicUrl?.absoluteString,
                            loginSource: .google)
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



