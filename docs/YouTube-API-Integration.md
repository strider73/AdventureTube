# YouTube API Integration

**YouTube Data API v3 with Google Sign-In**

[← Back to CLAUDE.md](../CLAUDE.md)

---

## Table of Contents
1. [Overview](#overview)
2. [Authentication](#authentication)
3. [API Endpoints](#api-endpoints)
4. [Data Models](#data-models)
5. [YoutubeAPIService](#youtubeapiservice)
6. [Pagination](#pagination)
7. [Usage Examples](#usage-examples)
8. [Best Practices](#best-practices)

---

## Overview

AdventureTube uses **YouTube Data API v3** to fetch user's YouTube channel and video content.

### Key Features
- ✅ Read user's YouTube channel information
- ✅ Fetch uploaded videos (playlist items)
- ✅ Pagination support (next/prev page tokens)
- ✅ OAuth 2.0 authentication via Google Sign-In
- ✅ Combine-based reactive API

### API Documentation
- [YouTube Data API v3 Guide](https://developers.google.com/youtube/v3)
- [Auth Guide (Server-Side)](https://developers.google.com/youtube/v3/guides/auth/server-side-web-apps)
- [Google Cloud Console](https://console.cloud.google.com/apis/dashboard?project=adventuretube-1639805164044)

---

## Authentication

### Required Scope

```swift
static let youtubeContentReadScope = kGTLRAuthScopeYouTubeReadonly
```

**Scope:** `https://www.googleapis.com/auth/youtube.readonly`

**Permissions:**
- View YouTube account
- View channel information
- View uploaded videos
- **Cannot:** Upload, edit, or delete content

### Authentication Flow

1. **User signs in** with Google (via GoogleLoginService)
2. **Request YouTube scope** (if not already granted)
3. **Access token** obtained from Google OAuth
4. **Token included** in API requests

---

## API Endpoints

### 1. Get Channel Information

**Endpoint:**
```
GET https://youtube.googleapis.com/youtube/v3/channels
```

**Query Parameters:**
```
part=snippet,statistics,contentDetails
mine=true
```

**Purpose:** Fetch authenticated user's YouTube channel data

**Response:** Channel name, description, statistics, uploads playlist ID

---

### 2. Get Playlist Items (Videos)

**Endpoint:**
```
GET https://youtube.googleapis.com/youtube/v3/playlistItems
```

**Query Parameters:**
```
part=snippet,contentDetails,id
maxResults=5
playlistId={uploadsPlaylistId}
pageToken={optional}
```

**Purpose:** Fetch user's uploaded videos

**Max Results:** 5 (can be increased to 50 max)

**Pagination:** Uses `nextPageToken` and `prevPageToken`

---

## Data Models

### YoutubeContentResource

**File:** `YoutubeContentResource.swift`

```swift
struct YoutubeContentResource: Codable {
    let kind: String
    let etag: String
    let nextPageToken: String?
    let prevPageToken: String?
    let pageInfo: PageInfo
    let items: [YoutubeItem]
}

struct PageInfo: Codable {
    let totalResults: Int
    let resultsPerPage: Int
}

struct YoutubeItem: Codable {
    let kind: String
    let etag: String
    let id: String
    let snippet: Snippet
}

struct Snippet: Codable {
    let publishedAt: String
    let channelId: String
    let title: String
    let description: String
    let thumbnails: Thumbnails
    let channelTitle: String
    let resourceId: ResourceId
}

struct Thumbnails: Codable {
    let `default`: ThumbnailInfo?
    let medium: ThumbnailInfo?
    let high: ThumbnailInfo?
    let standard: ThumbnailInfo?
    let maxres: ThumbnailInfo?
}

struct ThumbnailInfo: Codable {
    let url: String
    let width: Int
    let height: Int
}

struct ResourceId: Codable {
    let kind: String
    let videoId: String
}
```

---

### YoutubeChannelResource

**File:** `YoutubeChannelResource.swift`

```swift
struct YoutubeChannelResource: Codable {
    let kind: String
    let etag: String
    let pageInfo: PageInfo
    let items: [ChannelItem]
}

struct ChannelItem: Codable {
    let kind: String
    let etag: String
    let id: String
    let snippet: ChannelSnippet
    let contentDetails: ContentDetails
    let statistics: Statistics
}

struct ContentDetails: Codable {
    let relatedPlaylists: RelatedPlaylists
}

struct RelatedPlaylists: Codable {
    let uploads: String  // Uploads playlist ID
}
```

---

## YoutubeAPIService

**File:** `YoutubeAPIService.swift`

### Configuration

```swift
class YoutubeAPIService {
    // API Key for Maps SDK, Places API, YouTube Data API v3
    static let API_KEY = "REDACTED_GOOGLE_API_KEY"

    // OAuth 2.0 Read-only scope
    static let youtubeContentReadScope = kGTLRAuthScopeYouTubeReadonly

    // Base URLs
    private let youtubeChannelBaseURLString = "https://youtube.googleapis.com/youtube/v3/channels"
    private let youtubeContentInfoBaseURLString = "https://youtube.googleapis.com/youtube/v3/playlistItems"

    // Pagination tokens
    var nextPageToken: String?
    var prevPageToken: String?
}
```

---

### URL Components

#### Channel Info Request

```swift
private lazy var channelInfoComponents: URLComponents? = {
    var comps = URLComponents(string: youtubeChannelBaseURLString)
    comps?.queryItems = [
        URLQueryItem(name: "part", value: "snippet,statistics,contentDetails"),
        URLQueryItem(name: "mine", value: "true")
    ]
    return comps
}()
```

**Generated URL:**
```
https://youtube.googleapis.com/youtube/v3/channels?part=snippet,statistics,contentDetails&mine=true
```

---

#### Playlist Items Request

```swift
private lazy var youtubeContentInfoComponents: URLComponents? = {
    var comps = URLComponents(string: youtubeContentInfoBaseURLString)
    comps?.queryItems = [
        URLQueryItem(name: "part", value: "snippet,contentDetails,id"),
        URLQueryItem(name: "maxResults", value: "5")
    ]
    return comps
}()
```

**Generated URL:**
```
https://youtube.googleapis.com/youtube/v3/playlistItems?part=snippet,contentDetails,id&maxResults=5&playlistId={id}
```

---

### Reactive Publisher Pattern

```swift
func youtubeContentResourcePublisher(
    completion: @escaping (AnyPublisher<YoutubeContentResource, Error>) -> Void
) {
    // 1. Get channel info to obtain uploads playlist ID
    // 2. Create publisher for playlist items
    // 3. Return publisher via completion handler
}
```

---

## Pagination

### Token-Based Pagination

YouTube API uses **token-based pagination** instead of page numbers.

**Response includes:**
- `nextPageToken` - For fetching next page
- `prevPageToken` - For fetching previous page
- `pageInfo.totalResults` - Total available results
- `pageInfo.resultsPerPage` - Results in current page

### Implementation

```swift
class YoutubeAPIService {
    var nextPageToken: String?
    var prevPageToken: String?

    func youtubeContentResourcePublisher(
        pageToken: String? = nil,
        completion: @escaping (AnyPublisher<YoutubeContentResource, Error>) -> Void
    ) {
        // Build URL with pageToken if provided
        var components = youtubeContentInfoComponents
        if let pageToken = pageToken {
            components?.queryItems?.append(
                URLQueryItem(name: "pageToken", value: pageToken)
            )
        }

        // Make request...
    }

    // In response handler
    func handleResponse(_ resource: YoutubeContentResource) {
        self.nextPageToken = resource.nextPageToken
        self.prevPageToken = resource.prevPageToken
    }
}
```

---

### ViewModel Integration

```swift
class MyStoryListViewVM: ObservableObject {
    @Published var youtubeContentItems: [YoutubeContentItem] = []
    @Published var isLoadingMore = false

    private let youtubeAPIService = YoutubeAPIService()
    private let limitOfYoutubeContentItem = 100

    func downloadYoutubeContent(completion: @escaping () -> Void) {
        youtubeAPIService.youtubeContentResourcePublisher { [weak self] publisher in
            publisher.sink(
                receiveCompletion: { result in
                    switch result {
                    case .finished:
                        // Check if more pages available
                        if self?.youtubeAPIService.nextPageToken != nil,
                           self?.youtubeContentItems.count ?? 0 < self?.limitOfYoutubeContentItem ?? 0 {
                            // Can fetch more
                        }
                        completion()
                    case .failure(let error):
                        print("Error: \(error)")
                    }
                },
                receiveValue: { [weak self] resource in
                    self?.youtubeContentItems.append(contentsOf: resource.items)
                }
            )
        }
    }

    func loadMoreContent() {
        guard let nextToken = youtubeAPIService.nextPageToken,
              !isLoadingMore else { return }

        isLoadingMore = true

        youtubeAPIService.youtubeContentResourcePublisher(pageToken: nextToken) { publisher in
            // Handle next page...
        }
    }
}
```

---

## Usage Examples

### Example 1: Fetch User's Videos

```swift
let youtubeService = YoutubeAPIService()

youtubeService.youtubeContentResourcePublisher { publisher in
    publisher.sink(
        receiveCompletion: { completion in
            switch completion {
            case .finished:
                print("Fetch completed")
            case .failure(let error):
                print("Error: \(error)")
            }
        },
        receiveValue: { resource in
            print("Fetched \(resource.items.count) videos")
            resource.items.forEach { item in
                print("- \(item.snippet.title)")
            }
        }
    )
    .store(in: &cancellables)
}
```

---

### Example 2: Pagination with Load More

```swift
func fetchVideos(pageToken: String? = nil) {
    youtubeService.youtubeContentResourcePublisher(pageToken: pageToken) { publisher in
        publisher.sink(
            receiveCompletion: { _ in },
            receiveValue: { [weak self] resource in
                self?.videos.append(contentsOf: resource.items)

                // Check if more pages available
                if let nextToken = resource.nextPageToken {
                    print("Next page available: \(nextToken)")
                    // Can call fetchVideos(pageToken: nextToken)
                }
            }
        )
        .store(in: &cancellables)
    }
}
```

---

### Example 3: Map to Core Data

```swift
func downloadAndSaveToCoreData() {
    youtubeService.youtubeContentResourcePublisher { [weak self] publisher in
        publisher.sink(
            receiveCompletion: { _ in },
            receiveValue: { resource in
                self?.mapToStoryEntities(resource.items)
            }
        )
        .store(in: &cancellables)
    }
}

func mapToStoryEntities(_ items: [YoutubeItem]) {
    let context = CoreDataManager.instance.context

    items.forEach { item in
        let story = StoryEntity(context: context)
        story.id = UUID().uuidString
        story.youtubeId = item.snippet.resourceId.videoId
        story.youtubeTitle = item.snippet.title
        story.youtubeDescription = item.snippet.description
        story.youtubePublishedAt = item.snippet.publishedAt

        // Map thumbnails
        story.youtubeDefaultThumbnailURL = item.snippet.thumbnails.default?.url
        story.youtubeMediumThumbnailURL = item.snippet.thumbnails.medium?.url
        story.youtubehighThumbnailURL = item.snippet.thumbnails.high?.url
    }

    CoreDataManager.instance.save()
}
```

---

## Best Practices

### ✅ Do

1. **Check for valid authentication**
   ```swift
   guard LoginManager.shared.hasYoutubeAccessScope else {
       // Request YouTube scope
       return
   }
   ```

2. **Handle pagination limits**
   ```swift
   let limitOfYoutubeContentItem = 100
   if youtubeContentItems.count >= limitOfYoutubeContentItem {
       return  // Stop fetching
   }
   ```

3. **Use weak self in closures**
   ```swift
   publisher.sink { [weak self] resource in
       self?.handleResponse(resource)
   }
   ```

4. **Store cancellables**
   ```swift
   .store(in: &cancellables)
   ```

5. **Handle errors gracefully**
   ```swift
   case .failure(let error):
       print("YouTube API error: \(error.localizedDescription)")
       // Show user-friendly error message
   ```

---

### ❌ Don't

1. **Don't hardcode video IDs**
2. **Don't exceed rate limits** - Implement throttling
3. **Don't ignore quota limits** - Monitor API usage
4. **Don't fetch all videos at once** - Use pagination
5. **Don't store access tokens** - Use Google Sign-In SDK

---

## API Quotas & Limits

### Daily Quota
- **Default:** 10,000 units/day
- **Channels.list:** 1 unit
- **PlaylistItems.list:** 1 unit

### Rate Limits
- **Queries per 100 seconds:** 100 (default)
- **Queries per user per 100 seconds:** 1

### Best Practices for Quotas
✅ Cache responses when possible
✅ Use `maxResults` wisely (5-50 range)
✅ Implement exponential backoff for retries
✅ Monitor quota usage in Google Cloud Console

---

## Error Handling

### Common Errors

| Error Code | Meaning | Solution |
|------------|---------|----------|
| 400 | Bad Request | Check query parameters |
| 401 | Unauthorized | Refresh OAuth token |
| 403 | Forbidden | Check API key and quota |
| 404 | Not Found | Verify resource ID |
| 429 | Rate Limit | Implement exponential backoff |
| 500 | Server Error | Retry with backoff |

### Implementation

```swift
func handleYouTubeError(_ error: Error) {
    if let urlError = error as? URLError {
        switch urlError.code {
        case .notConnectedToInternet:
            showAlert("No internet connection")
        case .timedOut:
            showAlert("Request timed out")
        default:
            showAlert("Network error")
        }
    }
}
```

---

## Testing

### Mock YouTube Service

```swift
protocol YoutubeServiceProtocol {
    func youtubeContentResourcePublisher(completion: @escaping (AnyPublisher<YoutubeContentResource, Error>) -> Void)
}

class MockYoutubeService: YoutubeServiceProtocol {
    func youtubeContentResourcePublisher(completion: @escaping (AnyPublisher<YoutubeContentResource, Error>) -> Void) {
        let mockResource = YoutubeContentResource(/* mock data */)
        let publisher = Just(mockResource)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        completion(publisher)
    }
}
```

---

## Related Documentation

- [JWT Authentication](./JWT-Authentication.md) - OAuth 2.0 flow
- [MVVM Pattern](./MVVM-Pattern.md) - ViewModel integration
- [Combine Reactive Programming](./Combine-Reactive.md) - Publisher patterns
- [Core Data Architecture](./CoreData-Architecture.md) - Mapping to Core Data

---

[← Back to CLAUDE.md](../CLAUDE.md)
