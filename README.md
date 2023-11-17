External SNS Service 

1 Google(Google API and service Credential (https://console.cloud.google.com/apis/credentials?project=adventuretube-1639805164044)

   1)GoogleSignIn 7.0 (https://developers.google.com/identity/sign-in/ios/start)
   
      * OAuth clinet : (https://developers.google.com/identity/sign-in/ios/start-integrating)
                       Google Sign-In requires your iOS project to be configured with your OAuth client ID and a custom URL scheme,
                       and with this application only able to access google API when user is activley using app
                       
      
      * Web clined   : (https://developers.google.com/identity/sign-in/ios/offline-access)
                       Servers to be able to make Google API calls on behalf of users or while they are offline.
                       ex)For example, a photo app could enhance a photo in a user's Google Photos album by processing it on
                          a backend server and uploading the result to another album.
                          To do this, your server requires an access token and a refresh token.
        
   2)GooglePlaceAPI
      * API keys for Places SDK for iOS (https://developers.google.com/maps/documentation/places/ios-sdk/get-api-key)
          
          In order to use  Places information from google for example search name autocompletion on google search screen
          at GoogleMapViewController , it does require API key and Google recommend that restict API for the usage .
          currently it is restricted by application iOS and bundle identifier.
          
          check the Credentials for GooglePlace API and Youtube Dataq
      
      * Add a map to your iOS app with SwiftUI(https://developers.google.com/codelabs/maps-platform/maps-platform-ios-swiftui#5)
      
  3)Google Data API (https://developers.google.com/youtube/v3/guides/auth/server-side-web-apps)
         YouTube Data API supports the service account flow only for YouTube content owners that own and manage multiple YouTube channels.
 

Observing changes to managed objects across contexts with Combine(https://www.donnywals.com/observing-changes-to-managed-objects-across-contexts-with-combine/)

     This allows to observe specific managed objects across different contexts so app UI can easily update  when that managed object was changed on a background queue.
