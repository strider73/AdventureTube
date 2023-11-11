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

import Foundation
import GoogleSignIn
//import GoogleAPIClientForREST

/// An observable class for authenticating via Google.
final class GoogleLoginService: LoginServiceProtocol {
 
    /*    OAuth Client ID  from  https://developers.google.com/identity/sign-in/ios/start-integrating
    ClientId  is App's OAuth client ID to identify itself to Google's authentication backend.
    for iOS and mac OS the "OAuth clientID application type" must be configured as iOS.
     
    here is my clintID section .
    https://console.cloud.google.com/projectselector2/apis/credentials?project=_&supportedpurview=project
     
    => clientID has been moved to info.plist
     */
    // private let clientID = "657433323337-c4p5785b3e7dirj8l19egvcuaug45eei.apps.googleusercontent.com"
    
    /*   OAuth Server Client ID  from  https://developers.google.com/identity/sign-in/ios/start-integrating
     App will need to pass the identity of signed-in users to backend service.
     To securely pass the identity of users who signed in with Google to backend , use the ID token.
     
     Retrieving a user's ID token requires server client ID which represents backend server 
     
     => serverClientID  has been moved to info.plist
     */
     // private let serverClientID = "657433323337-t5e70nbjmink2ldmt3e34pci55v3sv6k.apps.googleusercontent.com"
    
//    private let service = GTLRYouTubeService()

    
//    private lazy var configuration: GIDConfiguration = {
//        return GIDConfiguration(clientID: clientID,serverClientID: serverClientID)
//    }()
//
    private var loginManager: LoginManager
    
    /// Creates an instance of this authenticator.
    /// - parameter authViewModel: The view model this authenticator will set logged in status on.
    init(loginManager: LoginManager) {
        self.loginManager = loginManager
    }
    
    /// Signs in the user based upon the selected account.'
    /// - note: Successful calls to this will set the `authViewModel`'s `state` property.
    
    func signIn(completion: @escaping (UserModel) -> ()) {
        guard let rootViewController =  UIApplication.shared.windows.first?.rootViewController else {
            print("There is no root view controller!")
            return
        }
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
  
            guard error == nil else {
                print("Error! \(String(describing: error))")
                return
            }
            guard let signInResult = signInResult else { return }
            let user = signInResult.user
            print("Initial Google Signed in Success")
            
            
            let emailAddress = user.profile?.email ?? "NoEamil"
            let fullName = user.profile?.name ?? "No Name"
            let givenName = user.profile?.givenName ?? "No Given Name"
            let familyName = user.profile?.familyName ?? "No Family Name"
            let profilePicUrl = user.profile?.imageURL(withDimension: 320) ?? URL(string: "No image URL")
            
            
            var adventureUser  = UserModel(signed_in: true,
                                  emailAddress: emailAddress,
                                  fullName: fullName,
                                  givenName: givenName,
                                  familyName: familyName,
                                  profilePicUrl: profilePicUrl?.absoluteString)
            
            
            
            signInResult.user.refreshTokensIfNeeded { user, error in
                guard error == nil else {return}
                guard let user = user else {return}
                
                if let idToken = user.idToken {
                    //not quite sure to cast to String type
                    adventureUser.idToken = idToken.tokenString
                }else{
                    print("idToken for Backend Server retrieve failed!!!!");
                }
                
                // Store Data in UserDefault
                let userDefaults = UserDefaults.standard
                do {
                    try userDefaults.setObject(adventureUser, forKey: "user")
                    print("user data has been setting in user default ")
                } catch {
                    print(error.localizedDescription)
                }
                self.loginManager.loginState = .signedIn(user)

                // return the data to call back method
                completion(adventureUser)
                
            }
            
            //get the UserID token
            /* GoogleSignIn V6.0 pattern need to remmove
            user.authentication.do { authentication, error in
                guard error == nil else { return }
                guard let authentication = authentication else { return }
                
                let idToken = authentication.idToken
                adventureUser.idToken = idToken
                
                // Store Data in UserDefault
                let userDefaults = UserDefaults.standard
                do {
                    try userDefaults.setObject(adventureUser, forKey: "user")
                    print("user data has been setting in user default ")
                } catch {
                    print(error.localizedDescription)
                }
                self.loginManager.loginState = .signedIn(user)

                // return the data to call back method
                completion(adventureUser)
            }
             */
            
//            self.loginManager.loginState = .signedIn(googleUser)
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
            return /* not signed in .*/
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

        
        /* GoogleSignIn V6 pattern need to removed
         
        GIDSignIn.sharedInstance.addScopes([YoutubeAPIService.youtubeContentReadScope],
                                           presenting: rootViewController) { user, error in
            if let error = error {
                print("Found error while Youtube read scope: \(error).")
                return
            }
            
            guard let currentUser = user else { return }
            self.loginManager.loginState = .signedIn(currentUser)
            completion()
            //            self.service.authorizer = currentUser.authentication.fetcherAuthorizer()
            //            self.fetchChannelResource()
        }
         
         */
    }
    
    
    
    
    /*
     'https://youtube.googleapis.com/youtube/v3/channels?part=snippet%2Cstatistics%2CcontentDetails&mine=true&key=[YOUR_API_KEY]' \
     --header 'Authorization: Bearer [YOUR_ACCESS_TOKEN]' \
     --header 'Accept: application/json' \
     --compressed
     */
//    func fetchChannelResource() {
////        let query = GTLRYouTubeQuery_ChannelsList.query(withPart: "snippet,statistics,contentDetails")
//        let query = GTLRYouTubeQuery_ChannelsList.query(withPart: "snippet,statistics,contentDetails")
//        print("Querty :  \(query)")
//        query.mine = true
//        service.executeQuery(query) { _, result, error in
//            guard let response = result as? GTLRYouTube_ChannelListResponse ,
//                  let channels = response.items
//            else{
//                print("Found error while Youtube read scope: \(error!).")
//                return
//            }
//
//            if !channels.isEmpty{
//                var outputText = ""
//                let channel = response.items![0]
//                let title = channel.snippet!.title
//                let description = channel.snippet?.descriptionProperty
//                let viewCount = channel.statistics?.viewCount
//                outputText += "title: \(title!)\n"
//                outputText += "description: \(description!)\n"
//                outputText += "view count: \(viewCount!)\n"
//
//                //added bty Chris
//                if let playListIdForUploads = channel.contentDetails?.relatedPlaylists?.uploads{
//                    print("uploadListId is ===> \(playListIdForUploads)")
//                   self.fetchUploadsResource(playListIdForUploads)
//                }else{
//                    print("Fail to get the uploadListId !!!!!");
//                }
//                print(outputText)
////                self.output.text = outputText
//
//            }
//        }
//    }
   /*
    'https://youtube.googleapis.com/youtube/v3/playlistItems?part=snippet%2CcontentDetails%2Cid&playlistId=UUMg4QJXtDH-VeoJvlEpfEYg&key=[YOUR_API_KEY]' \
    --header 'Authorization: Bearer [YOUR_ACCESS_TOKEN]' \
    --header 'Accept: application/json' \
    --compressed
    */
    
//    func fetchUploadsResource(_ playListIdForUploads:String) {
//        let query = GTLRYouTubeQuery_PlaylistItemsList.query(withPart: "snippet,contentDetails,id")
//        query.playlistId = playListIdForUploads
//        query.maxResults = 10
//        //query.pageToken = "EAAaBlBUOkNCUQ"
//        
//        service.executeQuery(query) { _, result, error in
//            guard let response = result as? GTLRYouTube_PlaylistItemListResponse
//            else{
//                print("Found error while Youtube read scope: \(error!).")
//                return
//            }
//            print(response.json!)
//            
////            let data = response.jsonString().data(using: .utf8)!
////            let items = try! JSONDecoder().decode(Items.self,from: data)
////
////            print("items pageInfo \(items.pageInfo)")
////            //prepare date  convertion
////            let localISOFormatter = ISO8601DateFormatter()
////            localISOFormatter.timeZone = TimeZone.current
////            // Parsing a string timestamp representing a date
////            //            let dateString = "2019-09-22T07:15:56Z"
////            //            if  let localDate :Date = localISOFormatter.date(from: dateString){
////            //            print(localDate)
////            //            }
////            //prepare coredate
////            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
////                return
////            }
////            let managedContext = appDelegate.persistentContainer.viewContext
////            items.items.forEach { item in
////                let entity = NSEntityDescription.entity(forEntityName: "Video", in: managedContext)!
////                let video =  NSManagedObject(entity: entity, insertInto: managedContext)
////                video.setValue(item.id, forKeyPath: "id")
////                video.setValue(item.etag, forKeyPath: "etag")
////
////                video.setValue(item.contentDetails.videoID, forKeyPath: "videoId")
////                if  let localDate :Date = localISOFormatter.date(from: item.contentDetails.videoPublishedAt){
////                    video.setValue(localDate, forKey: "publishedAt")
////                }
////                video.setValue(item.snippet.playlistID, forKey: "playListId")
////                video.setValue(item.snippet.title, forKeyPath: "title")
////                video.setValue(item.snippet.snippetDescription, forKeyPath: "videoDescription")
////                video.setValue(item.snippet.channelID, forKeyPath: "channelId")
////                video.setValue(item.snippet.channelTitle, forKeyPath: "channelTitle")
////                video.setValue(item.snippet.position, forKeyPath: "position")
////
////
////
////                //Default image
////                video.setValue(item.snippet.thumbnails.thumbnailsDefault?.url,    forKeyPath: "thumbnailDefaultURL")
////                video.setValue(item.snippet.thumbnails.thumbnailsDefault?.width,  forKeyPath: "thumbnailDefaultWidth")
////                video.setValue(item.snippet.thumbnails.thumbnailsDefault?.height, forKeyPath: "thumbnailDefaultHeight")
////                //High image
////                video.setValue(item.snippet.thumbnails.high?.url,    forKeyPath: "thumbnailHighURL")
////                video.setValue(item.snippet.thumbnails.high?.width,  forKeyPath: "thumbnailHighWidth")
////                video.setValue(item.snippet.thumbnails.high?.height, forKeyPath: "thumbnailHighHeight")
////                //Maxres Image
////                video.setValue(item.snippet.thumbnails.maxres?.url,   forKeyPath: "thumbnailMaxresURL")
////                video.setValue(item.snippet.thumbnails.maxres?.width, forKeyPath: "thumbnailMaxresWidth")
////                video.setValue(item.snippet.thumbnails.maxres?.height, forKeyPath: "thumbnailMaxresHeight")
////                //Medium Image
////                video.setValue(item.snippet.thumbnails.medium?.url,    forKeyPath: "thumbnailMediumURL")
////                video.setValue(item.snippet.thumbnails.medium?.width,  forKeyPath: "thumbnailMediumWidth")
////                video.setValue(item.snippet.thumbnails.medium?.height, forKeyPath: "thumbnailMediumHeight")
////                //Standard Image
////                video.setValue(item.snippet.thumbnails.standard?.url,    forKeyPath: "thumbnailStandardURL")
////                video.setValue(item.snippet.thumbnails.standard?.width,  forKeyPath: "thumbnailStandardWidth")
////                video.setValue(item.snippet.thumbnails.standard?.height, forKeyPath: "thumbnailStandardHeight")
////
////
////
////                do{
////                    try managedContext.save()
////
////                }catch let error as NSError{
////                    print("Could not save. \(error), \(error.userInfo)")
////                }
////            }
//
//            
//            
//            
//            //           error message is important when it need a test
//            //            do{
//            //                 items = try JSONDecoder().decode(Items.self,from: data)
//            //
//            //            }catch{
//            //                print(error)
//            //            }
//            
//        }
//    }
    
    
    /// Disconnects the previously granted scope and signs the user out.
    func disconnectAdditionalScope() {
        GIDSignIn.sharedInstance.disconnect { error in
          if let error = error {
            print("Encountered error disconnecting scope: \(error).")
          }
        }
    }
    

}
