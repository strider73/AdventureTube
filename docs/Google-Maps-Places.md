# Google Maps & Places API

**Location Services with Google Maps SDK and Places API**

[← Back to CLAUDE.md](../CLAUDE.md)

---

## Table of Contents
1. [Overview](#overview)
2. [Google Maps SDK](#google-maps-sdk)
3. [Google Places API](#google-places-api)
4. [UIKit Bridges](#uikit-bridges)
5. [Location Data Models](#location-data-models)
6. [Usage Examples](#usage-examples)
7. [Best Practices](#best-practices)

---

## Overview

AdventureTube integrates Google Maps SDK and Google Places API for location-based storytelling.

### Key Features
✅ **Interactive Maps** - Display story locations on Google Maps
✅ **Place Search** - Find locations using Google Places API
✅ **Custom Markers** - Show chapters on map with custom pins
✅ **Place Details** - Rich location metadata (rating, photos, types)
✅ **Coordinates** - Latitude/longitude for precise positioning
✅ **UIKit Integration** - Bridges Google Maps UIKit views to SwiftUI

### APIs Used
- **Google Maps SDK for iOS** v7.3.0
- **Google Places SDK for iOS** v5.0.0
- **Google Maps iOS Utils** v4.2.2

---

## Google Maps SDK

### Dependencies (Podfile)

```ruby
pod 'GoogleMaps', '7.3.0'
pod 'GooglePlaces', '5.0.0'
pod 'Google-Maps-iOS-Utils', '4.2.2'
```

### API Key

```swift
static let API_KEY = "REDACTED_GOOGLE_API_KEY"
```

**⚠️ Security Note:** In production, use a restricted API key

---

### Map View Integration

AdventureTube uses **UIKit bridges** to integrate Google Maps into SwiftUI.

**Files:**
- `StoryMapViewController.swift` - UIKit map controller
- `StoryMapViewControllerBridge.swift` - SwiftUI wrapper
- `GoogleMapViewForCreateStoryController.swift` - Chapter creation map

---

## Google Places API

### Place Search

**Purpose:** Search for locations by name, coordinates, or query

**API Endpoint:**
```
https://maps.googleapis.com/maps/api/place/textsearch/json
```

**Query Parameters:**
- `query` - Search term (e.g., "Eiffel Tower")
- `key` - API key
- `location` - Optional lat/lng bias
- `radius` - Search radius in meters

---

### Place Details

**Purpose:** Get detailed information about a specific place

**Data Retrieved:**
- Place ID (unique identifier)
- Name and formatted address
- Coordinates (latitude, longitude)
- Rating and user ratings total
- Place types (restaurant, park, etc.)
- Photos
- Website URL
- Plus Code

---

### Place Autocomplete

**Purpose:** Suggest places as user types

**Use Case:** Chapter location search in `CreateChapterView`

---

## UIKit Bridges

### StoryMapViewController

**File:** `StoryMapViewController.swift`

**Purpose:** UIKit view controller for displaying story map

```swift
class StoryMapViewController: UIViewController {
    private var mapView: GMSMapView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create map
        let camera = GMSCameraPosition.camera(
            withLatitude: 37.7749,
            longitude: -122.4194,
            zoom: 12.0
        )
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        view.addSubview(mapView)
    }

    func addMarker(lat: Double, lng: Double, title: String) {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        marker.title = title
        marker.map = mapView
    }
}
```

---

### StoryMapViewControllerBridge

**File:** `StoryMapViewControllerBridge.swift`

**Purpose:** SwiftUI wrapper for UIKit map controller

```swift
struct StoryMapViewControllerBridge: UIViewControllerRepresentable {
    let story: StoryEntity

    func makeUIViewController(context: Context) -> StoryMapViewController {
        let controller = StoryMapViewController()
        // Configure with story data
        return controller
    }

    func updateUIViewController(_ uiViewController: StoryMapViewController, context: Context) {
        // Update map when story changes
    }
}
```

**Usage in SwiftUI:**
```swift
struct MapView: View {
    let story: StoryEntity

    var body: some View {
        StoryMapViewControllerBridge(story: story)
            .edgesIgnoringSafeArea(.all)
    }
}
```

---

## Location Data Models

### AdventureTubePlace

**File:** `GoogleMapAPIPlace.swift`

```swift
struct AdventureTubePlace: Codable {
    let placeID: String
    let name: String
    let latitude: Double
    let longitude: Double
    let rating: Double?
    let types: [String]?
    let formattedAddress: String?
    let plusCode: String?
    let website: String?
    let photoReference: String?
}
```

---

### PlaceEntity (Core Data)

**File:** `PlaceEntity+CoreDataProperties.swift`

```swift
extension PlaceEntity {
    @NSManaged public var id: String
    @NSManaged public var placeID: String         // Google Place ID
    @NSManaged public var name: String
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var rating: Double
    @NSManaged public var types: [String]
    @NSManaged public var placeCategory: [String]
    @NSManaged public var pluscode: String?
    @NSManaged public var website: URL?
    @NSManaged public var photo: Data?            // Cached photo
    @NSManaged public var youtubeId: String
    @NSManaged public var youtubeTime: Int16

    // Relationships
    @NSManaged public var chapter: ChapterEntity
    @NSManaged public var story: StoryEntity
}
```

---

### CLLocationCoordinate2D Extension

**File:** `CLLocationCoordinate2D.swift`

```swift
extension CLLocationCoordinate2D {
    // Convert to dictionary
    var dictionary: [String: Double] {
        return [
            "latitude": latitude,
            "longitude": longitude
        ]
    }

    // Distance between coordinates
    func distance(to coordinate: CLLocationCoordinate2D) -> Double {
        let from = CLLocation(latitude: latitude, longitude: longitude)
        let to = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return from.distance(from: to)
    }
}
```

---

## Usage Examples

### Example 1: Display Story on Map

```swift
struct StoryMapView: View {
    let story: StoryEntity

    var body: some View {
        StoryMapViewControllerBridge(story: story)
            .onAppear {
                // Map loads and displays story chapters
            }
    }
}
```

---

### Example 2: Search for Place

```swift
class CreateChapterViewVM: ObservableObject {
    @Published var searchResults: [AdventureTubePlace] = []

    func searchPlace(query: String) {
        let urlString = "https://maps.googleapis.com/maps/api/place/textsearch/json"
        var components = URLComponents(string: urlString)
        components?.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "key", value: API_KEY)
        ]

        guard let url = components?.url else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return }

            do {
                let result = try JSONDecoder().decode(PlaceSearchResult.self, from: data)
                DispatchQueue.main.async {
                    self.searchResults = result.results
                }
            } catch {
                print("Decode error: \(error)")
            }
        }.resume()
    }
}
```

---

### Example 3: Add Marker to Map

```swift
class StoryMapViewController: UIViewController {
    func displayStoryChapters(_ story: StoryEntity) {
        guard let chapters = story.chapters.array as? [ChapterEntity] else { return }

        for (index, chapter) in chapters.enumerated() {
            let place = chapter.place
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(
                latitude: place.latitude,
                longitude: place.longitude
            )
            marker.title = place.name
            marker.snippet = "Chapter \(index + 1)"
            marker.map = mapView

            // Custom icon
            marker.icon = UIImage(named: "chapter_marker")
        }

        // Fit all markers in view
        fitMarkersInView(chapters: chapters)
    }

    func fitMarkersInView(chapters: [ChapterEntity]) {
        var bounds = GMSCoordinateBounds()
        for chapter in chapters {
            let coordinate = CLLocationCoordinate2D(
                latitude: chapter.place.latitude,
                longitude: chapter.place.longitude
            )
            bounds = bounds.includingCoordinate(coordinate)
        }

        let update = GMSCameraUpdate.fit(bounds, withPadding: 50)
        mapView.animate(with: update)
    }
}
```

---

### Example 4: Save Place to Core Data

```swift
func savePlace(_ apiPlace: AdventureTubePlace, chapter: ChapterEntity) {
    let context = CoreDataManager.instance.context

    let placeEntity = PlaceEntity(context: context)
    placeEntity.id = UUID().uuidString
    placeEntity.placeID = apiPlace.placeID
    placeEntity.name = apiPlace.name
    placeEntity.latitude = apiPlace.latitude
    placeEntity.longitude = apiPlace.longitude
    placeEntity.rating = apiPlace.rating ?? 0.0
    placeEntity.types = apiPlace.types ?? []
    placeEntity.pluscode = apiPlace.plusCode
    placeEntity.website = URL(string: apiPlace.website ?? "")

    // Download and save photo
    if let photoRef = apiPlace.photoReference {
        downloadPlacePhoto(photoRef) { data in
            placeEntity.photo = data
            CoreDataManager.instance.save()
        }
    }

    // Establish relationship
    placeEntity.chapter = chapter
    chapter.place = placeEntity

    CoreDataManager.instance.save()
}
```

---

## Best Practices

### ✅ Do

1. **Restrict API keys** in Google Cloud Console
2. **Cache place photos** in Core Data to reduce API calls
3. **Use coordinate bounds** when displaying multiple markers
4. **Handle location permissions** properly
5. **Implement error handling** for network requests
6. **Use Plus Codes** as backup location identifier

---

### ❌ Don't

1. **Don't expose API keys** in client code (use backend proxy in production)
2. **Don't make excessive API calls** - implement caching
3. **Don't ignore rate limits** - Google Places has quota limits
4. **Don't store raw API responses** - extract needed data only
5. **Don't use deprecated SDK versions**

---

## Map Customization

### Custom Marker Icons

```swift
// Custom chapter marker
let marker = GMSMarker()
marker.icon = UIImage(named: "custom_pin")
marker.groundAnchor = CGPoint(x: 0.5, y: 1.0)
```

### Map Styling

```swift
do {
    if let styleURL = Bundle.main.url(forResource: "map_style", withExtension: "json") {
        mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
    }
} catch {
    print("Map styling error: \(error)")
}
```

### Custom Info Window

```swift
func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
    let infoWindow = CustomInfoWindowView()
    infoWindow.configure(with: marker)
    return infoWindow
}
```

---

## Location Permissions

### Info.plist Keys

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>AdventureTube needs your location to show nearby adventure stories</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>AdventureTube needs your location to create location-based stories</string>
```

### Request Permission

```swift
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()

    func requestPermission() {
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // Permission granted
            manager.startUpdatingLocation()
        case .denied, .restricted:
            // Show alert
            break
        default:
            break
        }
    }
}
```

---

## API Quotas & Costs

### Google Maps SDK
- **Dynamic Maps:** $7 per 1000 loads
- **Static Maps:** $2 per 1000 loads
- **Free tier:** $200/month credit

### Google Places API
- **Text Search:** $32 per 1000 requests
- **Place Details:** $17 per 1000 requests
- **Autocomplete:** $2.83 per 1000 requests (per session)
- **Place Photos:** $7 per 1000 requests

### Optimization Tips
✅ Cache API responses
✅ Use session tokens for autocomplete
✅ Implement debouncing for search
✅ Compress and cache place photos
✅ Use Place IDs for repeated lookups

---

## Troubleshooting

### Issue: Map not showing

**Possible Causes:**
- API key not configured
- Billing not enabled in Google Cloud
- Incorrect SDK version
- Missing initialization

**Solution:**
```swift
// Initialize in AppDelegate
GMSServices.provideAPIKey("YOUR_API_KEY")
```

---

### Issue: Markers not appearing

**Possible Causes:**
- Invalid coordinates
- Marker not assigned to map
- Camera too far zoomed out

**Solution:**
```swift
marker.map = mapView  // Don't forget this!
```

---

### Issue: Place search returns no results

**Possible Causes:**
- API quota exceeded
- Invalid query
- Network error

**Solution:** Check API quotas in Google Cloud Console

---

## Related Documentation

- [Core Data Architecture](./CoreData-Architecture.md) - PlaceEntity persistence
- [MVVM Pattern](./MVVM-Pattern.md) - Map ViewModels
- [Combine Reactive Programming](./Combine-Reactive.md) - Reactive location updates

---

[← Back to CLAUDE.md](../CLAUDE.md)
