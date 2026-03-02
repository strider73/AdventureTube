# Combine Reactive Programming

**Reactive Data Flow with Apple's Combine Framework**

[← Back to CLAUDE.md](../CLAUDE.md)

---

## Table of Contents
1. [Combine Overview](#combine-overview)
2. [Core Concepts](#core-concepts)
3. [Publishers in AdventureTube](#publishers-in-adventuretube)
4. [Custom Publishers](#custom-publishers)
5. [Common Patterns](#common-patterns)
6. [Memory Management](#memory-management)
7. [Best Practices](#best-practices)

---

## Combine Overview

**Combine** is Apple's framework for processing values over time, enabling reactive programming in Swift.

### Why Combine in AdventureTube?

✅ **Reactive UI** - Automatic view updates via `@Published`
✅ **Async Operations** - Handle network requests reactively
✅ **Core Data Integration** - Cross-context observation
✅ **Composable** - Chain and transform data streams
✅ **Type-Safe** - Compile-time error checking
✅ **Memory Safe** - Automatic subscription cleanup

---

## Core Concepts

### Publisher

**Definition:** Emits values over time

```swift
// Examples of Publishers in AdventureTube
@Published var stories: [StoryEntity] = []  // Published<[StoryEntity]>
URLSession.shared.dataTaskPublisher(for: url)  // DataTaskPublisher
CoreDataFetchResultsPublisher<StoryEntity>  // Custom publisher
```

**Key Types:**
- `Output` - Type of values emitted
- `Failure` - Type of errors (or `Never` if no errors)

---

### Subscriber

**Definition:** Receives values from a publisher

```swift
// Sink is the most common subscriber
publisher.sink(
    receiveCompletion: { completion in
        // Handle completion or error
    },
    receiveValue: { value in
        // Handle received value
    }
)
```

---

### Operators

**Definition:** Transform, filter, or combine publishers

```swift
publisher
    .map { $0.uppercased() }  // Transform
    .filter { $0.count > 5 }  // Filter
    .eraseToAnyPublisher()    // Type erase
```

---

### AnyCancellable

**Definition:** Token that cancels subscription when deallocated

```swift
private var cancellables = Set<AnyCancellable>()

publisher.sink { ... }
    .store(in: &cancellables)  // Stores subscription
```

---

## Publishers in AdventureTube

### 1. @Published (Most Common)

**Location:** ViewModels

**Purpose:** Auto-notify observers when property changes

```swift
class MyStoryListViewVM: ObservableObject {
    @Published var youtubeContentItems: [YoutubeContentItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
}
```

**How it Works:**
1. Property assignment triggers `willSet`
2. `objectWillChange` publisher fires
3. SwiftUI re-renders subscribed views

---

### 2. URLSession.DataTaskPublisher

**Location:** API Services

**Purpose:** Network requests

```swift
func loginWithPassword(adventureUser: UserModel) -> AnyPublisher<AuthResponse, Error> {
    return session.dataTaskPublisher(for: request)
        .tryMap { try self.handleHttpResponse($0, decodingType: AuthResponse.self) }
        .mapError { error -> BackendError in
            if let backendError = error as? BackendError {
                return backendError
            } else {
                return BackendError.unknownError
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
}
```

---

### 3. NotificationCenter.Publisher

**Location:** CoreDataStorage

**Purpose:** Observe Core Data changes

```swift
func publisher<T: NSManagedObject>(
    for managedObject: T,
    in context: NSManagedObjectContext
) -> AnyPublisher<T, Never> {
    let notification = NSManagedObjectContext.didMergeChangesObjectIDsNotification

    return NotificationCenter.default.publisher(for: notification, object: context)
        .compactMap { notification in
            // Extract updated object
        }
        .eraseToAnyPublisher()
}
```

---

### 4. PassthroughSubject

**Location:** Custom publishers, event streams

**Purpose:** Manually send values

```swift
private let playListIdPublisher = PassthroughSubject<String, Error>()

// Send value
playListIdPublisher.send("UUMg4QJXtDH-VeoJvlEpfEYg")

// Send completion
playListIdPublisher.send(completion: .finished)

// Send error
playListIdPublisher.send(completion: .failure(someError))
```

---

### 5. Future

**Location:** API services

**Purpose:** Single-value async operation

```swift
func getData<T: Decodable>(endpoint: String, returnData: T.Type) -> Future<T, Error> {
    return Future<T, Error> { [weak self] promise in
        guard let self = self, let url = URL(string: endpoint) else {
            return promise(.failure(NetworkError.invalidURL))
        }

        self.session.dataTaskPublisher(for: url)
            .tryMap { (data, response) -> Data in
                // Validate response
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        promise(.failure(error))
                    }
                },
                receiveValue: { data in
                    promise(.success(data))
                }
            )
            .store(in: &self.cancellables)
    }
}
```

---

## Custom Publishers

### 1. CoreDataFetchResultsPublisher

**Purpose:** One-time reactive fetch

```swift
struct CoreDataFetchResultsPublisher<Entity>: Publisher where Entity: NSManagedObject {
    typealias Output = [Entity]
    typealias Failure = NSError

    private let request: NSFetchRequest<Entity>
    private let context: NSManagedObjectContext

    func receive<S>(subscriber: S) where S: Subscriber,
                                         Self.Failure == S.Failure,
                                         Self.Output == S.Input {
        let subscription = Subscription(subscriber: subscriber, context: context, request: request)
        subscriber.receive(subscription: subscription)
    }
}
```

---

### 2. CoreDataSaveModelPublisher

**Purpose:** Reactive save operation

```swift
struct CoreDataSaveModelPublisher: Publisher {
    typealias Output = Bool
    typealias Failure = NSError

    private let action: Action  // () -> Void
    private let context: NSManagedObjectContext

    func request(_ demand: Subscribers.Demand) {
        do {
            action()  // Execute entity creation
            try context.save()
            subscriber.receive(true)  // Success
        } catch {
            subscriber.receive(completion: .failure(error as NSError))
        }
    }
}
```

---

### 3. UserDefaultPublisher

**Purpose:** Observe UserDefaults changes

```swift
class UserDefaultPublisher {
    func publisher<T>(for key: String, defaultValue: T) -> AnyPublisher<T, Never> {
        return NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .compactMap { _ in
                UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
            }
            .eraseToAnyPublisher()
    }
}
```

---

## Common Patterns

### Pattern 1: Chaining Network Requests

```swift
func fetchChannelThenVideos() {
    fetchChannelInfo()
        .flatMap { channelInfo in
            // Use channel info to fetch videos
            return self.fetchVideos(playlistId: channelInfo.uploadsPlaylistId)
        }
        .sink(
            receiveCompletion: { completion in
                // Handle final completion
            },
            receiveValue: { videos in
                // Process videos
            }
        )
        .store(in: &cancellables)
}
```

---

### Pattern 2: Combining Multiple Publishers

```swift
func fetchUserDataAndVideos() {
    let userPublisher = AdventureTubeAPIService.shared.getUser()
    let videosPublisher = YoutubeAPIService().getVideos()

    Publishers.Zip(userPublisher, videosPublisher)
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { (user, videos) in
                // Both completed, process together
            }
        )
        .store(in: &cancellables)
}
```

---

### Pattern 3: Debouncing Search Input

```swift
class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var results: [Result] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] text in
                self?.performSearch(text)
            }
            .store(in: &cancellables)
    }
}
```

---

### Pattern 4: Retry with Delay

```swift
func fetchDataWithRetry() {
    apiService.fetchData()
        .retry(3)  // Retry up to 3 times
        .catch { error in
            // Fallback publisher on error
            return Just([])
                .setFailureType(to: Error.self)
        }
        .sink { data in
            // Process data
        }
        .store(in: &cancellables)
}
```

---

### Pattern 5: Transform and Filter

```swift
$stories
    .map { stories in
        // Transform: Filter published stories only
        stories.filter { $0.isPublished }
    }
    .map { stories in
        // Transform: Sort by date
        stories.sorted { $0.youtubePublishedAt > $1.youtubePublishedAt }
    }
    .assign(to: &$publishedStories)
```

---

## Memory Management

### AnyCancellable Storage

**Problem:** Subscriptions need to be stored or they cancel immediately

```swift
// BAD - Cancels immediately
publisher.sink { value in
    print(value)
}

// GOOD - Stored, cancels when viewModel deallocates
publisher.sink { value in
    print(value)
}
.store(in: &cancellables)
```

---

### Weak Self Pattern

**Problem:** Strong reference cycles in closures

```swift
// BAD - Retain cycle
publisher.sink { value in
    self.property = value  // Strong capture of self
}

// GOOD - No retain cycle
publisher.sink { [weak self] value in
    self?.property = value
}
```

---

### Automatic Cleanup

```swift
class MyViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupObservers()
    }

    deinit {
        // Cancellables automatically cancel when Set deallocates
        print("Cleaning up subscriptions")
    }
}
```

---

## Best Practices

### ✅ Do

1. **Store cancellables**
   ```swift
   .store(in: &cancellables)
   ```

2. **Use [weak self] in closures**
   ```swift
   .sink { [weak self] value in ... }
   ```

3. **Handle both success and failure**
   ```swift
   .sink(
       receiveCompletion: { completion in },
       receiveValue: { value in }
   )
   ```

4. **Use appropriate schedulers**
   ```swift
   .receive(on: DispatchQueue.main)  // UI updates
   .subscribe(on: DispatchQueue.global())  // Background work
   ```

5. **Type erase when needed**
   ```swift
   .eraseToAnyPublisher()  // Hide implementation details
   ```

---

### ❌ Don't

1. **Don't forget to store subscriptions**
2. **Don't create retain cycles**
3. **Don't perform UI updates on background threads**
4. **Don't ignore errors**
5. **Don't over-complicate with operators**

---

## Operator Cheat Sheet

| Operator | Purpose | Example |
|----------|---------|---------|
| `map` | Transform values | `.map { $0.uppercased() }` |
| `filter` | Filter values | `.filter { $0.count > 5 }` |
| `compactMap` | Map + remove nils | `.compactMap { Int($0) }` |
| `flatMap` | Chain publishers | `.flatMap { fetchUser($0) }` |
| `debounce` | Delay emissions | `.debounce(for: .seconds(1), ...)` |
| `removeDuplicates` | Skip duplicates | `.removeDuplicates()` |
| `retry` | Retry on failure | `.retry(3)` |
| `catch` | Handle errors | `.catch { Just([]) }` |
| `receive(on:)` | Switch scheduler | `.receive(on: DispatchQueue.main)` |
| `subscribe(on:)` | Set work scheduler | `.subscribe(on: DispatchQueue.global())` |

---

## Real-World Examples from AdventureTube

### Example 1: Login Flow

```swift
func googleSignIn(completion: @escaping (Result<UserModel, Error>) -> Void) {
    loginService.signIn { [weak self] result in
        guard let self = self else { return }

        switch result {
        case .success(let adventureUser):
            self.userData = adventureUser
            self.loginState = .signedIn
            completion(.success(adventureUser))

        case .failure(let error):
            completion(.failure(error))
        }
    }
}
```

---

### Example 2: Core Data + Combine

```swift
func listenCoreDataSaveAndUpdate() {
    coreDataStorage.didSavePublisher(
        for: StoryEntity.self,
        in: context,
        changeTypes: [.inserted, .updated]
    )
    .sink { [weak self] changes in
        self?.handleStoryChanges(changes)
    }
    .store(in: &cancellables)
}
```

---

### Example 3: API + Core Data Pipeline

```swift
func downloadAndSave() {
    youtubeAPIService.fetchVideos()
        .flatMap { videos in
            // Transform to Core Data save publisher
            return CoreDataSaveModelPublisher(
                action: { self.createStories(from: videos) },
                context: self.context
            )
        }
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Error: \(error)")
                }
            },
            receiveValue: { success in
                print("Saved: \(success)")
            }
        )
        .store(in: &cancellables)
}
```

---

## Troubleshooting

### Issue: Subscription cancels immediately

**Cause:** Not storing AnyCancellable

**Solution:**
```swift
.store(in: &cancellables)
```

---

### Issue: Memory leak

**Cause:** Strong reference cycle

**Solution:**
```swift
.sink { [weak self] in ... }
```

---

### Issue: UI not updating

**Cause:** Not on main thread

**Solution:**
```swift
.receive(on: DispatchQueue.main)
```

---

## Related Documentation

- [MVVM Pattern](./MVVM-Pattern.md) - ViewModel integration
- [Core Data Architecture](./CoreData-Architecture.md) - Reactive Core Data
- [JWT Authentication](./JWT-Authentication.md) - API publishers
- [YouTube API Integration](./YouTube-API-Integration.md) - Network publishers

---

[← Back to CLAUDE.md](../CLAUDE.md)
