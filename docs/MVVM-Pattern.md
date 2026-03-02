# MVVM Architecture Pattern

**Model-View-ViewModel with SwiftUI & Combine**

[← Back to CLAUDE.md](../CLAUDE.md)

---

## Table of Contents
1. [MVVM Overview](#mvvm-overview)
2. [Architecture Layers](#architecture-layers)
3. [Property Wrappers](#property-wrappers)
4. [ViewModel Patterns](#viewmodel-patterns)
5. [Data Flow](#data-flow)
6. [Real Example: MyStoryListViewVM](#real-example-mystorylistviewvm)
7. [Best Practices](#best-practices)

---

## MVVM Overview

AdventureTube uses **MVVM (Model-View-ViewModel)** architecture pattern with SwiftUI's reactive framework.

### Why MVVM?

✅ **Separation of Concerns** - UI, business logic, and data are separated
✅ **Testability** - ViewModels can be unit tested without UI
✅ **Reactive** - Automatic UI updates via Combine
✅ **Reusability** - ViewModels can be shared across views
✅ **SwiftUI Native** - Perfect match for declarative UI

### Architecture Diagram

```
┌──────────────────────────────────────────────────────┐
│                      View                            │
│                   (SwiftUI)                          │
│  - Declarative UI                                    │
│  - Observes ViewModel via @StateObject/@ObservedObject
│  - User interactions → ViewModel methods            │
└────────────────┬─────────────────────────────────────┘
                 │ @Published properties
                 │ objectWillChange publisher
                 ▼
┌──────────────────────────────────────────────────────┐
│                   ViewModel                          │
│              (ObservableObject)                      │
│  - Business logic                                    │
│  - @Published properties                             │
│  - Combine publishers/subscribers                    │
│  - Transforms Model → View data                      │
└────────────────┬─────────────────────────────────────┘
                 │ Fetch/Save operations
                 │ API calls
                 ▼
┌──────────────────────────────────────────────────────┐
│                     Model                            │
│               (Data Layer)                           │
│  - Core Data entities                                │
│  - Swift structs/classes                             │
│  - Network DTOs                                      │
│  - Business models                                   │
└──────────────────────────────────────────────────────┘
```

---

## Architecture Layers

### 1. Model Layer

**Responsibilities:**
- Data structures
- Core Data entities
- Network response models
- Business logic rules

**Files:**
- `StoryEntity`, `ChapterEntity`, `PlaceEntity` (Core Data)
- `UserModel`, `AdventureTubeData` (Swift models)
- `YoutubeContentResource`, `AuthResponse` (DTOs)

---

### 2. ViewModel Layer

**Responsibilities:**
- UI state management
- Business logic execution
- Data transformation
- API calls via services
- Core Data operations
- Reactive updates via Combine

**Naming Convention:**
- `MyStoryListViewVM` for `MyStoryListView`
- `AddStoryViewVM` for `AddStoryView`
- `CreateChapterViewVM` for `CreateChapterView`

**Key Protocols:**
- `ObservableObject` - Enables reactive updates

---

### 3. View Layer

**Responsibilities:**
- UI rendering
- User interaction handling
- Observing ViewModel
- Navigation
- Animations

**Naming Convention:**
- `MyStoryListView`
- `AddStoryView`
- `CreateChapterView`

---

## Property Wrappers

### @Published (ViewModel)

**Purpose:** Notifies observers when property changes

```swift
class MyStoryListViewVM: ObservableObject {
    @Published var youtubeContentItems: [YoutubeContentItem] = []
    @Published var isShowRefreshAlert = false
    @Published var adventureTubeData: AdventureTubeData?
}
```

**How it works:**
1. Property changes → triggers `objectWillChange` publisher
2. SwiftUI observes `objectWillChange`
3. View automatically re-renders

---

### @StateObject (View)

**Purpose:** Creates and owns a ViewModel instance

**When to use:**
- View creates the ViewModel
- ViewModel lifetime tied to View lifetime
- View is the source of truth

```swift
struct MyStoryListView: View {
    @StateObject private var viewModel = MyStoryListViewVM()

    var body: some View {
        List(viewModel.youtubeContentItems) { item in
            Text(item.title)
        }
    }
}
```

**Lifecycle:**
- Created once when View initializes
- Persists across View re-renders
- Destroyed when View is removed

---

### @ObservedObject (View)

**Purpose:** Observes an externally-owned ViewModel

**When to use:**
- ViewModel passed from parent View
- Shared ViewModel across multiple Views
- ViewModel lifetime managed externally

```swift
struct StoryDetailView: View {
    @ObservedObject var viewModel: MyStoryCommonDetailVM

    var body: some View {
        Text(viewModel.adventureTubeData?.youtubeTitle ?? "")
    }
}
```

**Lifecycle:**
- Not owned by this View
- Can be recreated on View re-render
- Lifetime managed by parent

---

### @EnvironmentObject (View)

**Purpose:** Inject shared ViewModel down view hierarchy

**When to use:**
- Global app state (LoginManager)
- Shared across many views
- Avoids prop drilling

```swift
// Parent view
MyStoryListView()
    .environmentObject(LoginManager.shared)

// Child view
struct ChildView: View {
    @EnvironmentObject var loginManager: LoginManager

    var body: some View {
        Text(loginManager.userData.fullName ?? "")
    }
}
```

---

## ViewModel Patterns

### Pattern 1: Reactive Core Data Integration

```swift
class MyStoryListViewVM: ObservableObject {
    @Published var stories: [StoryEntity] = []

    private var coreDataStorage = CoreDataStorage()
    private var context = CoreDataManager.instance.context
    private var cancellables = Set<AnyCancellable>()

    init() {
        listenCoreDataChanges()
        fetchStories()
    }

    // Observe Core Data changes reactively
    func listenCoreDataChanges() {
        coreDataStorage.didSavePublisher(
            for: StoryEntity.self,
            in: context,
            changeTypes: [.inserted, .updated, .deleted]
        )
        .sink { [weak self] changes in
            self?.handleChanges(changes)
        }
        .store(in: &cancellables)
    }

    func handleChanges(_ changes: [([StoryEntity], CoreDataStorage.ChangeType)]) {
        // Refresh list when data changes
        fetchStories()
    }

    func fetchStories() {
        let request: NSFetchRequest<StoryEntity> = StoryEntity.fetchRequest()
        do {
            stories = try context.fetch(request)
        } catch {
            print("Fetch error: \(error)")
        }
    }
}
```

---

### Pattern 2: API Integration with Combine

```swift
class MyStoryListViewVM: ObservableObject {
    @Published var youtubeContentItems: [YoutubeContentItem] = []
    @Published var isLoading = false

    private let youtubeAPIService = YoutubeAPIService()
    private var cancellable: AnyCancellable?

    func downloadYoutubeContent(completion: @escaping () -> Void) {
        isLoading = true

        youtubeAPIService.youtubeContentResourcePublisher { [weak self] publisher in
            guard let self = self else { return }

            self.cancellable = publisher
                .sink(
                    receiveCompletion: { [weak self] result in
                        self?.isLoading = false
                        switch result {
                        case .finished:
                            completion()
                        case .failure(let error):
                            print("Error: \(error)")
                        }
                    },
                    receiveValue: { [weak self] youtubeContentResource in
                        self?.youtubeContentItems.append(contentsOf: youtubeContentResource.items)
                    }
                )
        }
    }
}
```

---

### Pattern 3: State Management

```swift
class AddStoryViewVM: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSuccessAlert = false

    enum ViewState {
        case idle
        case loading
        case success
        case error(String)
    }

    @Published var viewState: ViewState = .idle

    func saveStory() {
        viewState = .loading

        // Perform save operation
        CoreDataManager.instance.save()

        viewState = .success
        showSuccessAlert = true
    }
}
```

---

## Data Flow

### Unidirectional Data Flow

```
User Interaction (View)
         │
         ▼
    View calls ViewModel method
         │
         ▼
    ViewModel executes business logic
         │
         ▼
    ViewModel updates @Published properties
         │
         ▼
    objectWillChange fires
         │
         ▼
    SwiftUI re-renders View
```

### Example Flow

```swift
// 1. User taps button (View)
Button("Save Story") {
    viewModel.saveStory()
}

// 2. ViewModel method called
func saveStory() {
    isLoading = true  // 3. @Published property updated

    let publisher = CoreDataSaveModelPublisher(
        action: { /* create story */ },
        context: context
    )

    publisher.sink { [weak self] completion in
        self?.isLoading = false  // 4. @Published property updated
        // 5. SwiftUI automatically re-renders View
    }
}
```

---

## Real Example: MyStoryListViewVM

**File:** `MyStoryListViewVM.swift`

### Full Implementation Breakdown

```swift
final class MyStoryListViewVM: ObservableObject {
    // MARK: - Published Properties (View observes these)
    @Published var youtubeContentItems: [YoutubeContentItem] = []
    @Published var isShowRefreshAlert = false
    @Published var adventureTubeData: AdventureTubeData?

    // MARK: - Private Properties
    private let limitOfYoutubeContentItem = 100
    private var coreDataStorage = CoreDataStorage()
    private var context = CoreDataManager.instance.context
    var stories: [StoryEntity] = []
    private var cancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    let youtubeAPIService = YoutubeAPIService()

    // MARK: - Initialization
    init() {
        print("init MyStoryListViewVM")
        listenCoreDataSaveAndUpdate()
    }

    // MARK: - Core Data Observation
    func listenCoreDataSaveAndUpdate() {
        coreDataStorage.didSavePublisher(
            for: StoryEntity.self,
            in: context,
            changeTypes: [.inserted, .updated]
        )
        .sink { [weak self] changes in
            // Handle Core Data changes
            self?.handleStoryChanges(changes)
        }
        .store(in: &cancellables)
    }

    // MARK: - YouTube API Integration
    func downloadYoutubeContentsAndMappedWithCoreData(outerCompletion: @escaping () -> Void) {
        youtubeAPIService.youtubeContentResourcePublisher { [weak self] publisher in
            guard let self = self else { return }

            self.cancellable = publisher.sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("YouTube content fetched successfully")
                        outerCompletion()
                    case .failure(let error):
                        print("Error: \(error)")
                    }
                },
                receiveValue: { [weak self] youtubeContentResource in
                    self?.processYoutubeContent(youtubeContentResource)
                }
            )
        }
    }

    // MARK: - Business Logic
    func processYoutubeContent(_ resource: YoutubeContentResource) {
        // Transform API response to View models
        let newItems = resource.items.map { YoutubeContentItem(from: $0) }
        youtubeContentItems.append(contentsOf: newItems)
    }

    func deleteExistingYoutubeContent() {
        youtubeContentItems = []
    }
}
```

### Key Patterns Used

✅ **ObservableObject conformance** - Enables reactive updates
✅ **@Published properties** - Automatic UI updates
✅ **Combine integration** - Reactive API calls and Core Data observation
✅ **Weak self** - Prevents retain cycles
✅ **Cancellables storage** - Memory management for subscriptions
✅ **Separation of concerns** - Business logic in ViewModel, not View

---

## Best Practices

### ✅ Do

1. **Use final class for ViewModels**
   ```swift
   final class MyStoryListViewVM: ObservableObject { }
   ```

2. **Always use [weak self] in closures**
   ```swift
   publisher.sink { [weak self] value in
       self?.handleValue(value)
   }
   ```

3. **Store cancellables**
   ```swift
   .store(in: &cancellables)
   ```

4. **Keep Views dumb**
   ```swift
   // Good: View calls ViewModel method
   Button("Save") { viewModel.save() }

   // Bad: View has business logic
   Button("Save") {
       let context = CoreDataManager.instance.context
       // ... Core Data logic in View
   }
   ```

5. **Use descriptive @Published property names**
   ```swift
   @Published var isLoading = false  // Good
   @Published var flag = false       // Bad
   ```

6. **Initialize in init()**
   ```swift
   init() {
       setupObservers()
       fetchInitialData()
   }
   ```

---

### ❌ Don't

1. **Don't import SwiftUI in ViewModel**
   ```swift
   // Bad
   import SwiftUI

   // Good
   import Foundation
   import Combine
   ```

2. **Don't reference View from ViewModel**
   ```swift
   // Bad
   class MyViewModel: ObservableObject {
       var view: MyView?  // NO!
   }
   ```

3. **Don't use @State in ViewModel**
   ```swift
   // Bad - @State is for Views only
   @State var value = 0

   // Good - Use @Published in ViewModel
   @Published var value = 0
   ```

4. **Don't perform UI operations in ViewModel**
   ```swift
   // Bad
   func showAlert() {
       UIAlertController.show(...)  // NO!
   }

   // Good
   @Published var shouldShowAlert = false
   ```

5. **Don't create retain cycles**
   ```swift
   // Bad
   publisher.sink { value in
       self.property = value  // Retain cycle!
   }

   // Good
   publisher.sink { [weak self] value in
       self?.property = value
   }
   ```

---

## Testing ViewModels

### Example Unit Test

```swift
import XCTest
@testable import AdventureTube

class MyStoryListViewVMTests: XCTestCase {
    var viewModel: MyStoryListViewVM!

    override func setUp() {
        super.setUp()
        viewModel = MyStoryListViewVM()
    }

    func testDeleteExistingYoutubeContent() {
        // Given
        viewModel.youtubeContentItems = [YoutubeContentItem(), YoutubeContentItem()]

        // When
        viewModel.deleteExistingYoutubeContent()

        // Then
        XCTAssertEqual(viewModel.youtubeContentItems.count, 0)
    }

    func testFetchStoriesFromCoreData() {
        // Given
        let expectation = XCTestExpectation(description: "Fetch stories")

        // When
        viewModel.fetchStories()

        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertNotNil(self.viewModel.stories)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }
}
```

---

## Common Patterns Summary

| Pattern | Use Case | Example |
|---------|----------|---------|
| **@StateObject** | View owns ViewModel | `@StateObject var vm = MyVM()` |
| **@ObservedObject** | ViewModel passed from parent | `@ObservedObject var vm: MyVM` |
| **@EnvironmentObject** | Global shared state | `@EnvironmentObject var loginManager` |
| **Combine + Core Data** | Reactive data updates | `didSavePublisher` |
| **Combine + Network** | Reactive API calls | `sink(receiveCompletion:receiveValue:)` |
| **State Management** | Loading/Error states | `@Published var viewState: ViewState` |

---

## Related Documentation

- [Combine Reactive Programming](./Combine-Reactive.md) - Reactive patterns
- [Core Data Architecture](./CoreData-Architecture.md) - Data persistence
- [YouTube API Integration](./YouTube-API-Integration.md) - API integration

---

[← Back to CLAUDE.md](../CLAUDE.md)
