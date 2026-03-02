# Core Data Architecture

**Reactive Data Persistence with Custom Combine Publishers**

[← Back to CLAUDE.md](../CLAUDE.md)

---

## Table of Contents
1. [Data Model Overview](#data-model-overview)
2. [Entity Schemas](#entity-schemas)
3. [Relationships](#relationships)
4. [CoreDataManager](#coredatamanager)
5. [Custom Combine Publishers](#custom-combine-publishers)
6. [Reactive Observation Patterns](#reactive-observation-patterns)
7. [Usage Examples](#usage-examples)
8. [Best Practices](#best-practices)

---

## Data Model Overview

AdventureTube uses Core Data for local persistence of adventure stories, chapters, and geographic locations. The data model is built around three main entities with complex relationships.

### Entity Relationship Diagram

```
StoryEntity (1) ─── chapters (ordered) ──> (N) ChapterEntity
            └─── places ───────────────> (N) PlaceEntity
                                              ↑ (1:1)
                                              │
ChapterEntity (1) ─── place ──────────────────┘
            └─── story ──> (1) StoryEntity
```

**Key Features:**
- ✅ Ordered chapters (`NSOrderedSet`)
- ✅ One-to-many relationships
- ✅ Bidirectional navigation
- ✅ Cascade delete rules

---

## Entity Schemas

### StoryEntity

**File:** `StoryEntity+CoreDataProperties.swift`

**Purpose:** Main adventure story with YouTube video information

```swift
extension StoryEntity {
    // Identifiers
    @NSManaged public var id: String
    @NSManaged public var youtubeId: String

    // YouTube Metadata
    @NSManaged public var youtubeTitle: String
    @NSManaged public var youtubeDescription: String?
    @NSManaged public var youtubePublishedAt: String?

    // Thumbnails (5 resolutions)
    @NSManaged public var youtubeDefaultThumbnailURL: String?
    @NSManaged public var youtubehighThumbnailURL: String?
    @NSManaged public var youtubeMediumThumbnailURL: String?
    @NSManaged public var youtubeStandardThumbnailURL: String?
    @NSManaged public var youtubeMaxresThumbnailURL: String?

    // User Metadata
    @NSManaged public var userContentType: String
    @NSManaged public var userTripDuration: String
    @NSManaged public var isPublished: Bool
    @NSManaged public var gpsData: Date?

    // Relationships
    @NSManaged public var chapters: NSOrderedSet  // One-to-Many (ordered)
    @NSManaged public var places: NSSet           // One-to-Many
}
```

**Relationships:**
- `chapters`: NSOrderedSet of ChapterEntity (ordered by sequence)
- `places`: NSSet of PlaceEntity

---

### ChapterEntity

**File:** `ChapterEntity+CoreDataProperties.swift`

**Purpose:** Timestamped segments of a story

```swift
extension ChapterEntity {
    // Identifiers
    @NSManaged public var id: String
    @NSManaged public var youtubeId: String

    // Chapter Data
    @NSManaged public var youtubeTime: Int16      // Timestamp in video (seconds)
    @NSManaged public var category: [String]      // Chapter categories
    @NSManaged public var thumbnail: Data?        // Chapter thumbnail image

    // Relationships
    @NSManaged public var place: PlaceEntity      // One-to-One
    @NSManaged public var story: StoryEntity      // Many-to-One
}
```

**Key Points:**
- `youtubeTime` is Int16 (max ~9 hours)
- `category` is array for multi-category support
- `thumbnail` stored as binary Data

---

### PlaceEntity

**File:** `PlaceEntity+CoreDataProperties.swift`

**Purpose:** Geographic locations with Google Places data

```swift
extension PlaceEntity {
    // Identifiers
    @NSManaged public var id: String
    @NSManaged public var placeID: String         // Google Place ID
    @NSManaged public var youtubeId: String
    @NSManaged public var youtubeTime: Int16

    // Location Data
    @NSManaged public var name: String
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double

    // Google Places Metadata
    @NSManaged public var rating: Double
    @NSManaged public var types: [String]         // Place types (restaurant, park, etc.)
    @NSManaged public var placeCategory: [String]
    @NSManaged public var pluscode: String?       // Plus Code
    @NSManaged public var website: URL?
    @NSManaged public var photo: Data?            // Place photo

    // Relationships
    @NSManaged public var chapter: ChapterEntity  // One-to-One
    @NSManaged public var story: StoryEntity      // Many-to-One
}
```

**Key Points:**
- Google Place ID for API integration
- Coordinates stored as Double precision
- Arrays for types and categories
- Optional photo as binary Data

---

## Relationships

### Story → Chapters (One-to-Many, Ordered)

```swift
// StoryEntity has ordered chapters
@NSManaged public var chapters: NSOrderedSet

// Access chapters in order
let story = fetchedStory
let firstChapter = story.chapters[0] as? ChapterEntity

// Add chapters maintaining order
story.insertIntoChapters(newChapter, at: index)
```

**⚠️ Important:** Use `NSOrderedSet` to maintain chapter sequence!

### Story → Places (One-to-Many)

```swift
// StoryEntity has unordered places
@NSManaged public var places: NSSet

// Access all places
let story = fetchedStory
let allPlaces = story.places as? Set<PlaceEntity>
```

### Chapter ↔ Place (One-to-One)

```swift
// Each chapter has exactly one place
let chapter = fetchedChapter
let location = chapter.place

// Each place belongs to one chapter
let place = fetchedPlace
let parentChapter = place.chapter
```

### Bidirectional Navigation

```swift
// Navigate from Story to Chapter to Place
story.chapters[0].place.name

// Navigate from Place to Chapter to Story
place.chapter.story.youtubeTitle
```

---

## CoreDataManager

**File:** `CoreDataManager.swift`

### Singleton Pattern

```swift
class CoreDataManager {
    static let instance = CoreDataManager()

    let container: NSPersistentContainer
    let context: NSManagedObjectContext

    private init() {
        container = NSPersistentContainer(name: "AdventureTube")

        container.loadPersistentStores { description, error in
            if let error = error {
                print("Error loading Core Data: \(error)")
            }
        }

        context = container.viewContext

        // 🔑 Auto-merge changes from background contexts
        context.automaticallyMergesChangesFromParent = true
    }

    func save() {
        do {
            try context.save()
            print("Core Data saved successfully!")
        } catch let error {
            print("Error saving Core Data: \(error.localizedDescription)")
        }
    }
}
```

### Key Features

✅ **Singleton Instance** - Single source of truth
✅ **Auto-Merge** - Background changes automatically merge to viewContext
✅ **Main Context** - viewContext for UI operations
✅ **Simple Save** - Centralized save method

---

## Custom Combine Publishers

AdventureTube implements **three custom Combine publishers** for reactive Core Data observation.

### 1. CoreDataFetchResultsPublisher

**File:** `CoreDataFetchResultsPublisher.swift`

**Purpose:** One-time reactive fetch

```swift
struct CoreDataFetchResultsPublisher<Entity>: Publisher where Entity: NSManagedObject {
    typealias Output = [Entity]
    typealias Failure = NSError

    private let request: NSFetchRequest<Entity>
    private let context: NSManagedObjectContext
}
```

**Usage:**
```swift
let request: NSFetchRequest<StoryEntity> = StoryEntity.fetchRequest()
let publisher = CoreDataFetchResultsPublisher(request: request, context: context)

publisher
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("Fetch failed: \(error)")
            }
        },
        receiveValue: { stories in
            print("Fetched \(stories.count) stories")
        }
    )
    .store(in: &cancellables)
```

---

### 2. CoreDataSaveModelPublisher

**File:** `CoreDataSaveModelPublisher.swift`

**Purpose:** Reactive save operations

```swift
struct CoreDataSaveModelPublisher: Publisher {
    typealias Output = Bool
    typealias Failure = NSError

    private let action: Action  // () -> Void closure
    private let context: NSManagedObjectContext
}
```

**Usage:**
```swift
let publisher = CoreDataSaveModelPublisher(
    action: {
        let newStory = StoryEntity(context: context)
        newStory.id = UUID().uuidString
        newStory.youtubeTitle = "New Adventure"
        // ... set properties
    },
    context: context
)

publisher
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("Save failed: \(error)")
            }
        },
        receiveValue: { success in
            print("Save successful: \(success)")
        }
    )
    .store(in: &cancellables)
```

---

### 3. CoreDataStorage (Advanced Observation)

**File:** `CoreDataStorage.swift`

**Purpose:** Cross-context reactive observation with change tracking

#### Publisher Type 1: Simple Update Observer

```swift
func publisher<T: NSManagedObject>(
    for managedObject: T,
    in context: NSManagedObjectContext
) -> AnyPublisher<T, Never>
```

**Usage:**
```swift
let storage = CoreDataStorage()
let story = fetchedStory

storage.publisher(for: story, in: context)
    .sink { updatedStory in
        print("Story updated: \(updatedStory.youtubeTitle)")
    }
    .store(in: &cancellables)
```

**⚠️ Limitation:** Only observes updates, not inserts/deletes

---

#### Publisher Type 2: Multi-Change Observer

```swift
func publisher<T: NSManagedObject>(
    for managedObject: T,
    in context: NSManagedObjectContext,
    changeTypes: [ChangeType]
) -> AnyPublisher<(object: T?, type: ChangeType), Never>
```

**ChangeType Enum:**
```swift
enum ChangeType {
    case inserted
    case updated
    case deleted

    var userInfoKey: String {
        switch self {
        case .inserted: return NSInsertedObjectIDsKey
        case .updated: return NSUpdatedObjectIDsKey
        case .deleted: return NSDeletedObjectIDsKey
        }
    }
}
```

**Usage:**
```swift
storage.publisher(for: story, in: context, changeTypes: [.updated, .deleted])
    .sink { (object, changeType) in
        switch changeType {
        case .updated:
            print("Story updated: \(object?.youtubeTitle ?? "")")
        case .deleted:
            print("Story deleted")
        default:
            break
        }
    }
    .store(in: &cancellables)
```

---

#### Publisher Type 3: Type-Based Observer (Most Powerful!)

```swift
func didSavePublisher<T: NSManagedObject>(
    for type: T.Type,
    in context: NSManagedObjectContext,
    changeTypes: [ChangeType]
) -> AnyPublisher<[([T], ChangeType)], Never>
```

**Usage:**
```swift
// Observe ALL StoryEntity changes
storage.didSavePublisher(
    for: StoryEntity.self,
    in: context,
    changeTypes: [.inserted, .updated, .deleted]
)
.sink { changes in
    changes.forEach { (stories, changeType) in
        switch changeType {
        case .inserted:
            print("New stories inserted: \(stories.count)")
        case .updated:
            print("Stories updated: \(stories.count)")
        case .deleted:
            print("Stories deleted: \(stories.count)")
        }
    }
}
.store(in: &cancellables)
```

**Features:**
- ✅ Observes all objects of a type
- ✅ Groups changes by type
- ✅ Filters by entity description
- ✅ Returns arrays of changed objects
- ✅ Works across contexts

---

## Reactive Observation Patterns

### How Cross-Context Observation Works

1. **Notification System:**
   - Uses `NSManagedObjectContext.didMergeChangesObjectIDsNotification`
   - Triggered when viewContext merges changes from background context

2. **Object ID Tracking:**
   - Each managed object has unique `NSManagedObjectID`
   - IDs persist across contexts
   - Publishers filter notifications by object ID

3. **Change Detection:**
   - UserInfo dictionary contains change sets
   - Keys: `NSInsertedObjectIDsKey`, `NSUpdatedObjectIDsKey`, `NSDeletedObjectIDsKey`
   - Publishers extract relevant object IDs

4. **Object Retrieval:**
   - `context.object(with: objectID)` retrieves object in target context
   - Safe across different contexts
   - Ensures UI updates on main thread

### Why This Matters

✅ **Automatic UI Updates** - ViewModels react to data changes
✅ **Background Saves** - Work happens off main thread
✅ **No Manual Refresh** - Combine handles updates
✅ **Type Safety** - Generic publishers ensure correctness

---

## Usage Examples

### Example 1: ViewModel with Reactive Story List

```swift
class MyStoryListViewVM: ObservableObject {
    @Published var stories: [StoryEntity] = []

    private var cancellables = Set<AnyCancellable>()
    private let context = CoreDataManager.instance.context
    private let storage = CoreDataStorage()

    init() {
        observeStoryChanges()
        fetchStories()
    }

    func observeStoryChanges() {
        storage.didSavePublisher(
            for: StoryEntity.self,
            in: context,
            changeTypes: [.inserted, .updated, .deleted]
        )
        .sink { [weak self] changes in
            self?.handleStoryChanges(changes)
        }
        .store(in: &cancellables)
    }

    func handleStoryChanges(_ changes: [([StoryEntity], CoreDataStorage.ChangeType)]) {
        // Refresh story list
        fetchStories()
    }

    func fetchStories() {
        let request: NSFetchRequest<StoryEntity> = StoryEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "youtubePublishedAt", ascending: false)]

        do {
            stories = try context.fetch(request)
        } catch {
            print("Fetch error: \(error)")
        }
    }
}
```

---

### Example 2: Creating a Story with Chapters and Places

```swift
func createStory(youtubeData: YoutubeContentResource, chapters: [ChapterData]) {
    let publisher = CoreDataSaveModelPublisher(
        action: {
            // Create Story
            let story = StoryEntity(context: context)
            story.id = UUID().uuidString
            story.youtubeId = youtubeData.id
            story.youtubeTitle = youtubeData.title
            story.isPublished = false

            // Create Chapters and Places
            for (index, chapterData) in chapters.enumerated() {
                let chapter = ChapterEntity(context: context)
                chapter.id = UUID().uuidString
                chapter.youtubeId = story.youtubeId
                chapter.youtubeTime = chapterData.timestamp
                chapter.category = chapterData.categories

                let place = PlaceEntity(context: context)
                place.id = UUID().uuidString
                place.placeID = chapterData.placeID
                place.name = chapterData.placeName
                place.latitude = chapterData.latitude
                place.longitude = chapterData.longitude

                // Establish relationships
                chapter.place = place
                chapter.story = story
                place.chapter = chapter
                place.story = story

                // Add chapter to story (ordered)
                story.insertIntoChapters(chapter, at: index)
                story.addToPlaces(place)
            }
        },
        context: context
    )

    publisher
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Save failed: \(error)")
                }
            },
            receiveValue: { success in
                print("Story created: \(success)")
            }
        )
        .store(in: &cancellables)
}
```

---

## Best Practices

### ✅ Do

1. **Use viewContext for UI operations**
   ```swift
   let context = CoreDataManager.instance.context
   ```

2. **Use background contexts for heavy operations**
   ```swift
   let backgroundContext = container.newBackgroundContext()
   ```

3. **Observe changes with didSavePublisher**
   ```swift
   storage.didSavePublisher(for: StoryEntity.self, ...)
   ```

4. **Maintain chapter order with NSOrderedSet**
   ```swift
   story.insertIntoChapters(chapter, at: index)
   ```

5. **Use fetch requests with sort descriptors**
   ```swift
   request.sortDescriptors = [NSSortDescriptor(key: "youtubePublishedAt", ascending: false)]
   ```

### ❌ Don't

1. **Don't save on main thread for large operations**
2. **Don't ignore merge conflicts**
3. **Don't create objects without relationships**
4. **Don't forget to set inverse relationships**
5. **Don't mix objects from different contexts**

---

## Performance Tips

1. **Batch Operations**
   ```swift
   let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
   try context.execute(batchDeleteRequest)
   ```

2. **Prefetch Relationships**
   ```swift
   request.relationshipKeyPathsForPrefetching = ["chapters", "places"]
   ```

3. **Limit Fetch Results**
   ```swift
   request.fetchLimit = 50
   request.fetchOffset = 0
   ```

4. **Use Faulting**
   ```swift
   request.returnsObjectsAsFaults = true
   ```

---

## Troubleshooting

### Issue: Changes not reflecting in UI

**Solution:** Ensure `automaticallyMergesChangesFromParent = true` and using didSavePublisher

### Issue: Merge conflicts

**Solution:** Implement merge policy
```swift
context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
```

### Issue: Memory leaks with publishers

**Solution:** Use `[weak self]` in sink closures and store in cancellables

---

## Related Documentation

- [Combine Reactive Programming](./Combine-Reactive.md) - Publisher patterns
- [MVVM Pattern](./MVVM-Pattern.md) - ViewModel integration
- [JWT Authentication](./JWT-Authentication.md) - User data persistence

---

[← Back to CLAUDE.md](../CLAUDE.md)
