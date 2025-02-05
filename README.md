# AdventureTube

AdventureTube is an iOS application designed to help users explore and create YouTube-based adventure stories. The app integrates with Google APIs to enable YouTube authentication, Google Places, and Google Maps services, providing a seamless experience for location-based storytelling. Most importantly, it communicates with [AdventureTube Microservice](https://github.com/strider73/adventuretube-microservice), the backbone service that powers the entire AdventureTube application. This backend is built using Spring Microservices with Spring Cloud, ensuring scalability and reliability.

## Features
- **Google Sign-In**: Secure authentication using Google OAuth.
- **YouTube API Integration**: Fetch and manage YouTube content for storytelling.
- **Google Places API**: Search and retrieve place information for adventure mapping.
- **Google Maps Integration**: Display location-based content interactively.
- **CoreData Support**: Efficient local data storage and synchronization.
- **Combine Framework**: Handles asynchronous operations efficiently.
- **GoogleMapView with CoreData**: Unique approach to updating UI based on CoreData changes for a seamless experience.
- **AdventureTubeAPI Service**: Facilitates communication between the iOS application and the backend built using Spring Microservices. The backend microservices can be found at [AdventureTube Microservice](https://github.com/strider73/adventuretube-microservice).

## Setup and Installation
### Prerequisites
Ensure you have the following installed:
- Xcode (latest version recommended)
- CocoaPods
- A Google Cloud account with enabled APIs (Google Sign-In, Places API, YouTube Data API). API keys are required for each of these services and can be requested from [Google Cloud Console](https://console.cloud.google.com/apis/credentials):
   - **Google Sign-In API Key**: Used for authenticating users securely.
   - **Google Places API Key**: Required for search name autocompletion and place-related queries.
   - **YouTube Data API Key**: Needed for fetching and managing YouTube content.
   Ensure these API keys are properly configured and restricted for security.

### Clone the Repository
```sh
 git clone https://github.com/your-repository/adventuretube.git
 cd adventuretube
```

### Install Dependencies
```sh
 pod install
```
Open `AdventureTube.xcworkspace` in Xcode to proceed.

### Google API Setup
1. **Google Sign-In 7.0** ([Google Sign-In Setup](https://developers.google.com/identity/sign-in/ios/start))
   - Enable OAuth 2.0 authentication in [Google Developer Console](https://console.cloud.google.com/apis/credentials?project=adventuretube-1639805164044)
   - Configure `GoogleService-Info.plist` in the project
   
   * **OAuth Client** ([Setup Guide](https://developers.google.com/identity/sign-in/ios/start-integrating))
     - Google Sign-In requires your iOS project to be configured with your OAuth client ID and a custom URL scheme.
     - This application can only access Google API when the user is actively using the app.
     
   * **Web Client** ([Offline Access Guide](https://developers.google.com/identity/sign-in/ios/offline-access))
     - Allows servers to make Google API calls on behalf of users or while they are offline.
     - Example: A photo app could enhance a photo in a user's Google Photos album by processing it on a backend server and uploading the result to another album.
     - To do this, your server requires an access token and a refresh token.

2. **Google Places API**
   - Enable Places API and obtain an API key [here](https://developers.google.com/maps/documentation/places/ios-sdk/get-api-key)
   - In order to use Places information from Google, such as search name autocompletion on the Google search screen within `GoogleMapViewController`, an API key is required.
   - Currently, it is restricted by application iOS and bundle identifier.

3. **YouTube Data API**
   - Enable YouTube API for content retrieval and management [here](https://developers.google.com/youtube/v3/guides/auth/server-side-web-apps)

## AdventureTubeAPI Service
AdventureTubeAPI Service is responsible for communication between the iOS application and the backend built using Spring Microservices.
- **File**: `AdventureTubeAPIService.swift`
- **Created by**: Chris Lee on 29/11/2023
- **Functionality**:
  - Provides API services that use `adventuretube_id`, `refresh_token`, and `access_token`.
  - Ensures user data is correctly set and updated.
  - Uses `LoginManager.userData` for authentication and data retrieval.
  - Built using Combine framework for reactive API calls.

More details on API calls using Combine can be found [here](https://medium.com/@hemalasanka/making-api-calls-with-ios-combines-future-publisher-7a5011f81c2).

## Customized Core Data with Combine
- **Observing changes to managed objects across contexts with Combine** ([Guide](https://www.donnywals.com/observing-changes-to-managed-objects-across-contexts-with-combine/))
  - Allows observation of specific managed objects across different contexts so the app UI can easily update when the object is changed on a background queue.

## Usage
- **Sign in** with your Google account.
- **Search locations** using the Places API.
- **Fetch YouTube videos** and associate them with locations.
- **View content on an interactive map**.

## Architecture
- **MVVM Pattern**: Ensures a clean separation of concerns.
- **Combine Framework**: Handles data streams efficiently.
- **CoreData**: Stores user-related adventure data locally.
- **GoogleMapView with CoreData**: Provides a unique method for managing UI updates with CoreData.
- **AdventureTubeAPI Service**: Acts as a bridge between the frontend and backend services.

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss the changes.

## License
AdventureTube is licensed under the MIT License.

## Contact
For inquiries, please reach out to [your email/contact info].

## Figma Prototype
[View the AdventureTube Prototype](https://www.figma.com/proto/RZCJw60n7wgWTN4jMYfkoy/AdventureVictoria?kind=proto&node-id=1676-1354&page-id=0%3A1&scaling=min-zoom&starting-point-node-id=1062%3A1567&t=tXBHoTPyfjWpV2TS-1)

