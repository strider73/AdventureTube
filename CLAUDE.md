# AdventureTube iOS - Claude Assistant Guide

**Information Hub for AI-Assisted Development**

---

## 📚 Quick Navigation

### Detailed Technical Documentation
- **[JWT Authentication](./docs/JWT-Authentication.md)** - Security, tokens, auth flow
- **[Core Data Architecture](./docs/CoreData-Architecture.md)** - Data persistence & reactive patterns
- **[MVVM Pattern](./docs/MVVM-Pattern.md)** - Architecture implementation
- **[YouTube API Integration](./docs/YouTube-API-Integration.md)** - Video content fetching
- **[Combine Reactive Programming](./docs/Combine-Reactive.md)** - Reactive patterns & publishers
- **[Google Maps & Places](./docs/Google-Maps-Places.md)** - Location services
- **[Custom Tab Bar & Navigation](./docs/Custom-TabBar-Navigation.md)** - PreferenceKey, MatchedGeometryEffect

### User-Facing Documentation
- **[README.md](./README.md)** - Setup instructions & project overview

---

## Standard Workflow

1. **Grammar & Spelling Check**: Always first correct any grammar and spelling mistakes in the user's instruction and display the corrected version, while trying to remain as close to the original sentence as possible. Display the correction but do not wait or ask for permission - proceed directly with the corrected version's action
2. **Plan First**: Think through problem, read codebase, write plan to tasks/todo.md
3. **Check Plan**: Get verification before starting work
4. **Work Simply**: Make every change as simple as possible, minimal code impact
5. **Track Progress**: Mark todo items complete as you go
6. **Explain Changes**: Give high-level explanation at each step
7. **Review**: Add summary to todo.md when complete
8. **Security Check**: Please check through all the code you just wrote and make sure it follows security best practices. Make sure no sensitive information is in the front end and there are no vulnerabilities people can exploit

---

## Project Overview

AdventureTube is a platform that enables users to create **YouTube-based adventure stories** tied to geographic locations. The iOS app allows users to transform their YouTube content into interactive, location-driven storytelling experiences.

### What AdventureTube Does

**Core Concept:**
- Connect YouTube videos with specific geographic locations on a map
- Create location-driven adventure narratives with chapters and timestamps
- Transform travel vlogs and adventure content into interactive map experiences
- Share geographically-aware YouTube content with viewers

**User Journey:**
1. **Sign In**: Authenticate with Google (requires YouTube access)
2. **Select Videos**: Browse and choose YouTube videos from user's channel
3. **Add Locations**: Search places using Google Places API and pin to map
4. **Create Chapters**: Break videos into timestamped chapters, each with specific locations
5. **Publish Stories**: Share adventure stories with interactive map visualization
6. **Explore**: View stories on an interactive map showing the adventure journey

**Target Users:**
- Travel vloggers and adventure content creators
- Outdoor enthusiasts documenting expeditions
- Educational content creators showcasing locations
- Anyone wanting to add geographic context to their YouTube videos

### Platform Components
- **iOS App**: Native SwiftUI app for creating and viewing adventure stories
- **Web Platform**: [adventuretube.net](https://adventuretube.net/) for broader access
- **Backend**: Spring Microservices handling data synchronization and user management

---

## Core Architecture

### Technology Stack
- **Framework**: SwiftUI with MVVM architecture pattern → [Learn More](./docs/MVVM-Pattern.md)
- **Data Persistence**: Core Data with reactive updates → [Learn More](./docs/CoreData-Architecture.md)
- **Async Operations**: Combine framework for reactive programming → [Learn More](./docs/Combine-Reactive.md)
- **Authentication**: Google Sign-In with YouTube API access → [Learn More](./docs/JWT-Authentication.md)
- **Maps & Places**: Google Maps SDK and Google Places API → [Learn More](./docs/Google-Maps-Places.md)
- **Backend**: Spring Microservices at `https://api.travel-tube.com`
- **Dependency Management**: CocoaPods

### Key Design Patterns
- **Singleton pattern** for managers (`LoginManager`, `AdventureTubeAPIService`)
- **MVVM** with reactive data binding using `@Published` and `@StateObject`
- **Dependency injection** via environment objects
- **Protocol-oriented programming** for service abstractions
- **Custom Combine publishers** for reactive Core Data

---

## Data Models Quick Reference

### Core Data Entities (Local Persistence)
```
StoryEntity (1) ─── chapters (ordered) ──> (N) ChapterEntity
            └─── places ───────────────> (N) PlaceEntity
                                              ↑ (1:1)
ChapterEntity (1) ─── place ──────────────────┘
```

**Key Entities:**
- **StoryEntity**: YouTube video + metadata (id, youtubeId, title, thumbnails, isPublished)
- **ChapterEntity**: Timestamped segments (youtubeTime, category, thumbnail) → **NSOrderedSet** maintains sequence!
- **PlaceEntity**: Geographic data (latitude, longitude, placeID, name, rating, types)

→ **[Full Core Data Documentation](./docs/CoreData-Architecture.md)**

### Swift Models (API Data Transfer)
- `UserModel` - User authentication and profile data
- `AdventureTubeData` - Complete story data structure
- `YoutubeContentResource` - YouTube API response models
- `AdventureTubePlace` - Location data with coordinates
- `AdventureTubeChapter` - Chapter data with places and timestamps

---

## Project Structure

```
AdventureTube/
├── docs/                        (Technical documentation)
├── Models/
│   ├── User/                    (UserModel, LoginSource)
│   ├── Youtube/                 (YoutubeContentResource, YoutubeChannelResource)
│   └── GoogleModel/             (AdventureTubeData, GoogleMapAPIPlace)
├── Services/
│   ├── APIService/              (AdventureTubeAPIService, YoutubeAPIService)
│   ├── LoginService/            (LoginManager, GoogleLoginService)
│   ├── CoreDataService/         (CoreDataManager, CoreDataStorage)
│   └── FileService/             (LocalFileManager, LocalImageFileManager)
├── Views/
│   ├── MyStory/                 (Story creation and management)
│   ├── StoryMap/                (Interactive map views)
│   ├── Common/                  (Shared UI components)
│   └── Tab&Navi/                (Custom tab bar and navigation)
└── Util/                        (Extensions, protocols, utilities)
```

---

## Key Services Quick Reference

### 🔐 Authentication & Security
**LoginManager** - Auth state management (Singleton)
- States: `.initial`, `.signedIn`, `.signedOut`
- Handles Google Sign-In and YouTube scope permissions
- Persists JWT tokens to UserDefaults

**AdventureTubeAPIService** - Backend API with JWT tokens
- Endpoints: `/auth/users`, `/auth/token`, `/auth/refreshToken`, `/auth/logout`
- Custom error handling: `BackendError` enum
- Combine-based reactive API

→ **[Full JWT Authentication Guide](./docs/JWT-Authentication.md)**

---

### 📦 Data & Storage
**CoreDataManager** - Singleton data manager
- Auto-merge changes from background contexts
- Simple save/fetch API
- Reactive observation with Combine

**CoreDataStorage** - Custom Combine publishers
- `didSavePublisher` - Observe insert/update/delete
- Cross-context observation
- Type-safe generic publishers

→ **[Full Core Data Guide](./docs/CoreData-Architecture.md)**

---

### 🎬 External APIs
**YoutubeAPIService** - YouTube Data API v3
- Fetches user's videos and channel info
- Pagination with next/prev tokens
- Scope: `kGTLRAuthScopeYouTubeReadonly`
- Max results: 5-50 per request

→ **[Full YouTube API Guide](./docs/YouTube-API-Integration.md)**

**GoogleMapAPIService** - Maps & Places integration
- Place search and details
- Custom map markers
- Location coordinates

→ **[Full Maps & Places Guide](./docs/Google-Maps-Places.md)**

---

### 🏗️ Architecture Patterns
**MVVM with Combine**
- ViewModels conform to `ObservableObject`
- `@Published` properties trigger UI updates
- `@StateObject` / `@ObservedObject` in Views
- Reactive data binding

→ **[Full MVVM Guide](./docs/MVVM-Pattern.md)**

**Reactive Programming**
- Custom Combine publishers
- Network request publishers
- Core Data observation publishers
- Memory-safe subscription management

→ **[Full Combine Guide](./docs/Combine-Reactive.md)**

**Custom UI Components**
- Custom tab bar with PreferenceKey
- MatchedGeometryEffect animations
- Generic container with ViewBuilder
- Dynamic show/hide capability

→ **[Full Tab Bar Guide](./docs/Custom-TabBar-Navigation.md)**

---

## Critical Files Reference

| File | Purpose | Documentation |
|------|---------|---------------|
| `LoginManager.swift` | Global auth state, token lifecycle | [JWT Auth](./docs/JWT-Authentication.md#critical-files) |
| `AdventureTubeAPIService.swift` | All JWT API endpoints | [JWT Auth](./docs/JWT-Authentication.md#3-authentication-flow) |
| `CoreDataManager.swift` | Data persistence singleton | [Core Data](./docs/CoreData-Architecture.md#coredatamanager) |
| `CoreDataStorage.swift` | Reactive Core Data publishers | [Core Data](./docs/CoreData-Architecture.md#custom-combine-publishers) |
| `MyStoryListViewVM.swift` | Main ViewModel example | [MVVM](./docs/MVVM-Pattern.md#real-example-mystorylistviewvm) |
| `YoutubeAPIService.swift` | YouTube Data API v3 client | [YouTube API](./docs/YouTube-API-Integration.md#youtubeapiservice) |
| `StoryMapViewController.swift` | Google Maps integration | [Maps](./docs/Google-Maps-Places.md#uikit-bridges) |

---

## Current Development Context

### Active Branch
- `MyStoryViewList-LoadMore`: Implementing pagination for story lists
- Recent API endpoint updates and documentation improvements
- Load-more functionality in `MyStoryListView` with `isLoadingMore` state

### Recent Changes
- API endpoint corrections in `AdventureTubeAPIService`
- Code documentation improvements in `AddStoryView`
- Server address configuration updates
- Documentation restructure (you're reading it!)

---

## Development Guidelines

### Code Style
- Use SwiftUI declarative syntax
- Follow MVVM pattern with reactive data flow → [MVVM Guide](./docs/MVVM-Pattern.md)
- Implement proper error handling with Result types
- Use `@Published` for reactive UI updates → [Combine Guide](./docs/Combine-Reactive.md)
- Follow iOS naming conventions

### Testing Commands
```bash
# Build project
xcodebuild -workspace AdventureTube.xcworkspace -scheme AdventureTube build

# Run tests (if test target exists)
xcodebuild -workspace AdventureTube.xcworkspace -scheme AdventureTube test
```

### Common Tasks
- **Story list pagination**: `MyStoryListView` + `MyStoryListViewVM`
- **API integration**: `AdventureTubeAPIService` → [JWT Guide](./docs/JWT-Authentication.md)
- **Authentication**: `LoginManager` → [JWT Guide](./docs/JWT-Authentication.md)
- **Maps/Places**: `StoryMap/` → [Maps Guide](./docs/Google-Maps-Places.md)
- **Core Data**: `CoreDataManager` → [Core Data Guide](./docs/CoreData-Architecture.md)

---

## Environment Variables

```swift
// Google API Key (Maps, Places, YouTube)
static let API_KEY = "REDACTED_GOOGLE_API_KEY"

// Backend Server
private var targetServerAddress = "https://api.travel-tube.com"

// YouTube Scope
static let youtubeContentReadScope = kGTLRAuthScopeYouTubeReadonly
```

---

## Critical Reminders

### 🔴 Security
- **NEVER** log JWT tokens in production → [JWT Security](./docs/JWT-Authentication.md#when-working-with-authentication)
- **ALWAYS** use `LoginManager.shared.userData` for tokens
- **ALWAYS** clear tokens on sign out via `loginState = .signedOut`
- Check all code changes for vulnerabilities

### 📊 Data
- **USE** reactive publishers for Core Data UI updates → [Core Data Reactive](./docs/CoreData-Architecture.md#reactive-observation-patterns)
- **MAINTAIN** chapter order with NSOrderedSet
- **HANDLE** merge conflicts in Core Data contexts

### 🔄 Reactive Programming
- **STORE** all cancellables → [Combine Memory](./docs/Combine-Reactive.md#memory-management)
- **USE** `[weak self]` in closures
- **RECEIVE** UI updates on main thread

### 🎬 APIs
- **RESPECT** YouTube API quotas → [YouTube Quotas](./docs/YouTube-API-Integration.md#api-quotas--limits)
- **IMPLEMENT** pagination for video lists
- **CACHE** Google Places data to reduce costs

---

## Quick Start Checklist

When working on AdventureTube:

- [ ] Read relevant documentation linked above
- [ ] Check current branch context
- [ ] Follow MVVM pattern for new features
- [ ] Use Combine for reactive operations
- [ ] Test authentication flow if touching auth
- [ ] Verify Core Data relationships
- [ ] Handle errors gracefully
- [ ] Use weak self in closures
- [ ] Store cancellables properly
- [ ] Security check before committing

---

## Documentation Index

| Topic | File | What You'll Learn |
|-------|------|-------------------|
| **Authentication** | [JWT-Authentication.md](./docs/JWT-Authentication.md) | Token flow, endpoints, security best practices |
| **Data Persistence** | [CoreData-Architecture.md](./docs/CoreData-Architecture.md) | Entities, relationships, reactive publishers |
| **Architecture** | [MVVM-Pattern.md](./docs/MVVM-Pattern.md) | ViewModels, property wrappers, data flow |
| **YouTube Integration** | [YouTube-API-Integration.md](./docs/YouTube-API-Integration.md) | API endpoints, pagination, data models |
| **Reactive Programming** | [Combine-Reactive.md](./docs/Combine-Reactive.md) | Publishers, operators, memory management |
| **Location Services** | [Google-Maps-Places.md](./docs/Google-Maps-Places.md) | Maps SDK, Places API, UIKit bridges |
| **Custom UI** | [Custom-TabBar-Navigation.md](./docs/Custom-TabBar-Navigation.md) | Tab bar, PreferenceKey, MatchedGeometryEffect |

---

This guide provides the essential context and navigation for AI assistants to effectively help with AdventureTube iOS development tasks. For detailed implementation specifics, refer to the linked documentation above.
