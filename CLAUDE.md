# AdventureTube iOS - Claude Assistant Guide

## Standard Workflow

1. **Grammar & Spelling Check**: Always first correct any grammar and spelling mistakes in the user's instruction and display the corrected version, while trying to remain as close to the original sentence as possible. Display the correction but do not wait or ask for permission - proceed directly with the corrected version's action
2. **Plan First**: Think through problem, read codebase, write plan to tasks/todo.md
3. **Check Plan**: Get verification before starting work
4. **Work Simply**: Make every change as simple as possible, minimal code impact
5. **Track Progress**: Mark todo items complete as you go
6. **Explain Changes**: Give high-level explanation at each step
7. **Review**: Add summary to todo.md when complete
8. **Security Check**: Please check through all the code you just wrote and make sure it follows security best practices. Make sure no sensitive information is in the front end and there are no vulnerabilities people can exploit

## Project Overview

AdventureTube is an iOS app that enables users to create location-based YouTube adventure stories by connecting YouTube videos with specific geographic locations. Users can associate their YouTube content with places on a map, creating interactive adventure narratives with chapters and timestamps.

> **📖 For detailed project information, setup instructions, and user-facing documentation, see [README.md](./README.md)**

## Core Architecture

### Technology Stack
- **Framework**: SwiftUI with MVVM architecture pattern
- **Data Persistence**: Core Data with reactive updates
- **Async Operations**: Combine framework for reactive programming
- **Authentication**: Google Sign-In with YouTube API access
- **Maps & Places**: Google Maps SDK and Google Places API
- **Backend**: Spring Microservices at `http://192.168.1.105:8030`
- **Dependency Management**: CocoaPods

### Key Design Patterns
- Singleton pattern for managers (`LoginManager`, `AdventureTubeAPIService`)
- MVVM with reactive data binding using `@Published` and `@StateObject`
- Dependency injection via environment objects
- Protocol-oriented programming for service abstractions

## Core Data Models

### Entities
- `StoryEntity`: Main story data with YouTube video information
- `ChapterEntity`: Story chapters with timestamps and locations
- `PlaceEntity`: Geographic locations with coordinates and metadata

### Swift Models
- `UserModel`: User authentication and profile data
- `AdventureTubeData`: Complete story data structure
- `YoutubeContentResource`: YouTube API response models
- `AdventureTubePlace`: Location data with coordinates
- `AdventureTubeChapter`: Chapter data with places and timestamps

## Project Structure

```
AdventureTube/
├── Models/
│   ├── User/ (UserModel, LoginSource)
│   ├── Youtube/ (YoutubeContentResource, YoutubeChannelResource)
│   └── GoogleModel/ (AdventureTubeData, GoogleMapAPIPlace)
├── Services/
│   ├── APIService/ (AdventureTubeAPIService, YoutubeAPIService)
│   ├── LoginService/ (LoginManager, GoogleLoginService)
│   ├── CoreDataService/ (CoreDataManager, CoreDataStorage)
│   └── FileService/ (LocalFileManager, LocalImageFileManager)
├── Views/
│   ├── MyStory/ (Story creation and management)
│   ├── StoryMap/ (Interactive map views)
│   ├── Common/ (Shared UI components)
│   └── Tab&Navi/ (Custom tab bar and navigation)
└── Util/ (Extensions, protocols, utilities)
```

## Key Services

### LoginManager
- Singleton managing user authentication state
- States: `.initial`, `.signedIn`, `.signedOut`
- Handles Google Sign-In and YouTube scope permissions
- Persists user data to UserDefaults

### AdventureTubeAPIService
- Backend API communication with error handling
- JWT token management and refresh logic
- Endpoints: `/auth/users`, `/auth/token`, `/auth/token/refresh`, `/auth/token/revoke`

### YoutubeAPIService
- YouTube Data API v3 integration
- Fetches user's video content and channel information
- Handles pagination with next/prev page tokens
- Requires `kGTLRAuthScopeYouTubeReadonly` scope

### MyStoryListViewVM
- Core view model for story list management
- Reactive Core Data integration with Combine
- Handles YouTube content fetching and Core Data mapping
- Implements load-more functionality for pagination

## Current Development Context

### Active Branch
- `MyStoryViewList-LoadMore`: Implementing pagination for story lists
- Recent API endpoint updates and documentation improvements
- Load-more functionality in `MyStoryListView` with `isLoadingMore` state

### Recent Changes
- API endpoint corrections in `AdventureTubeAPIService`
- Code documentation improvements in `AddStoryView`
- Server address configuration updates

## Development Guidelines

### Code Style
- Use SwiftUI declarative syntax
- Follow MVVM pattern with reactive data flow
- Implement proper error handling with Result types
- Use `@Published` for reactive UI updates
- Follow iOS naming conventions

### Testing Commands
```bash
# Build project
xcodebuild -workspace AdventureTube.xcworkspace -scheme AdventureTube build

# Run tests (if test target exists)
xcodebuild -workspace AdventureTube.xcworkspace -scheme AdventureTube test
```

### Common Tasks
- Story list pagination: Focus on `MyStoryListView` and `MyStoryListViewVM`
- API integration: Check `AdventureTubeAPIService` for backend calls
- Authentication: Review `LoginManager` for user state management
- Maps/Places: Work with Google Maps integration in `StoryMap/`
- Core Data: Use `CoreDataManager` for data persistence operations

### Environment Variables
- Google API Key: `REDACTED_GOOGLE_API_KEY`
- Backend Server: `http://192.168.1.105:8030`
- YouTube API Scope: `kGTLRAuthScopeYouTubeReadonly`

## Important Notes

### Authentication Flow
1. User signs in with Google
2. App requests YouTube read scope
3. Backend validates Google ID token
4. JWT tokens stored for API access
5. Token refresh handled automatically

### Data Flow
1. YouTube videos fetched via API
2. User adds location data to create stories
3. Stories saved to Core Data with chapters/places
4. Real-time UI updates via Combine publishers
5. Map visualization of story locations

### Error Handling
- Network errors handled with custom `BackendError` enum
- Core Data operations wrapped in do-catch blocks
- UI shows loading states and error messages
- Token refresh automatic on 401 responses

This guide provides the essential context for AI assistants to effectively help with AdventureTube iOS development tasks.