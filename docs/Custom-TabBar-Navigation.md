# Custom Tab Bar & Navigation

**Advanced SwiftUI Tab Bar with PreferenceKey & MatchedGeometryEffect**

[← Back to CLAUDE.md](../CLAUDE.md)

---

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Tab Bar Items](#tab-bar-items)
4. [Advanced SwiftUI Patterns](#advanced-swiftui-patterns)
5. [Component Breakdown](#component-breakdown)
6. [Data Flow](#data-flow)
7. [Navigation System](#navigation-system)
8. [Customization](#customization)
9. [Best Practices](#best-practices)

---

## Overview

AdventureTube implements a **custom tab bar** replacing SwiftUI's default `TabView` with advanced animations and full control over appearance.

### Why Custom Tab Bar?

✅ **Full Design Control** - Custom styling, shadows, animations
✅ **Dynamic Visibility** - Show/hide tab bar programmatically
✅ **Smooth Animations** - `matchedGeometryEffect` for selection indicator
✅ **Type-Safe** - Enum-based tab items
✅ **Reusable** - Generic container for any content
✅ **SwiftUI Native** - No UIKit bridging required

### Key Features
- 4 tab items: Story Map, My Stories, Saved Story, Settings
- Animated selection indicator with matched geometry
- Dynamic show/hide capability
- PreferenceKey for bottom-up data flow
- Environment object for global state

---

## Architecture

### File Structure

```
AdventureTube/Views/Tab&Navi/
├── NavigationStateManager.swift        (NavigationPath manager)
└── CustomTabView/
    ├── AdventureTubeTabBarView.swift   (Main tab bar view)
    ├── CustomTabBarContainerView.swift (Generic container)
    ├── CustomTabBarView.swift          (Tab bar UI)
    ├── CustomTabBarViewVM.swift        (Visibility state)
    ├── TabBarItemInfoEnum.swift        (Tab item definitions)
    └── TabBarItemsPreferenceKey.swift  (PreferenceKey + Modifier)
```

### Component Hierarchy

```
AdventureTubeTabBarView
    └─ CustomTabBarContainerView<Content>
        ├─ Content (All Views)
        │   ├─ MapView
        │   ├─ MainStoryView
        │   ├─ MainSavedStoryView
        │   └─ SettingView
        └─ CustomTabBarView (Bottom Overlay)
            └─ ForEach(tabs) { tab in
                tabView1(tab)
            }
```

---

## Tab Bar Items

### TabBarItemInfoEnum

**File:** `TabBarItemInfoEnum.swift`

```swift
enum TabBarItemInfoEnum: String, Hashable, Identifiable {
    var id: String { return self.rawValue }

    case storymap
    case mystory
    case savedstory
    case setting

    var iconName: String {
        switch self {
        case .storymap:   return "map"
        case .mystory:    return "list.and.film"
        case .savedstory: return "square.and.arrow.down"
        case .setting:    return "gear"
        }
    }

    var title: String {
        switch self {
        case .storymap:   return "Story Map"
        case .mystory:    return "My Stories"
        case .savedstory: return "Saved Story"
        case .setting:    return "Setting"
        }
    }

    var color: Color {
        return Color.black  // All tabs use black
    }
}
```

### Tab Configuration

| Tab | Icon | Title | Purpose |
|-----|------|-------|---------|
| `.storymap` | `map` | Story Map | View stories on interactive map |
| `.mystory` | `list.and.film` | My Stories | Manage user's created stories |
| `.savedstory` | `square.and.arrow.down` | Saved Story | View saved/bookmarked stories |
| `.setting` | `gear` | Setting | App settings and profile |

---

## Advanced SwiftUI Patterns

### 1. PreferenceKey (Bottom-Up Data Flow)

**File:** `TabBarItemsPreferenceKey.swift`

**Purpose:** Child views send tab information UP to parent container

```swift
struct TabBarItemsPreferenceKey: PreferenceKey {
    static var defaultValue: [TabBarItemInfoEnum] = []

    static func reduce(value: inout [TabBarItemInfoEnum], nextValue: () -> [TabBarItemInfoEnum]) {
        // Append new tabs to existing array
        value += nextValue()
    }
}
```

**How It Works:**
1. Each child view calls `.preference(key: TabBarItemsPreferenceKey.self, value: [tab])`
2. PreferenceKey collects all tabs via `reduce`
3. Parent listens with `.onPreferenceChange(TabBarItemsPreferenceKey.self)`
4. Parent receives complete tab array

---

### 2. ViewModifier (Tab Behavior)

**File:** `TabBarItemsPreferenceKey.swift`

```swift
struct TabBarItemViewModifer: ViewModifier {
    let tab: TabBarItemInfoEnum
    var selection: TabBarItemInfoEnum

    func body(content: Content) -> some View {
        content
            // Show only selected tab's content
            .opacity(selection == tab ? 1.0 : 0.0)
            // Register this tab with PreferenceKey
            .preference(key: TabBarItemsPreferenceKey.self, value: [tab])
    }
}
```

**Responsibilities:**
- Controls visibility based on selection (opacity 1.0 or 0.0)
- Registers tab with PreferenceKey system
- Applied via `.tabBarItem(tab:selection:)` extension

---

### 3. MatchedGeometryEffect (Smooth Animations)

**File:** `CustomTabBarView.swift`

```swift
struct CustomTabBarView: View {
    @Namespace private var namespace

    private func tabView1(tab: TabBarItemInfoEnum) -> some View {
        VStack {
            Image(systemName: tab.iconName)
            Text(tab.title)
        }
        .background(
            ZStack {
                if localSelection == tab {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(tab.color.opacity(0.2))
                        .matchedGeometryEffect(id: "background_rectangle", in: namespace)
                }
            }
        )
    }
}
```

**Effect:**
- Selection indicator **smoothly animates** between tabs
- `@Namespace` creates shared animation context
- Same `id` on different views creates matched animation
- SwiftUI automatically interpolates position, size, shape

---

### 4. Generic Container with ViewBuilder

**File:** `CustomTabBarContainerView.swift`

```swift
struct CustomTabBarContainerView<Content: View>: View {
    @Binding var selection: TabBarItemInfoEnum
    let content: Content
    @State private var tabs: [TabBarItemInfoEnum] = []

    public init(selection: Binding<TabBarItemInfoEnum>, @ViewBuilder content: () -> Content) {
        self._selection = selection
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // All views stacked
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            // Tab bar overlay
            if customTabVM.isTabBarViewShow {
                CustomTabBarView(tabs: tabs, selection: $selection, localSelection: selection)
                    .transition(AnyTransition.opacity.animation(.easeInOut))
            }
        }
        .onPreferenceChange(TabBarItemsPreferenceKey.self) { value in
            self.tabs = value
        }
    }
}
```

**Features:**
- Generic `<Content: View>` for any content type
- `@ViewBuilder` for SwiftUI DSL syntax
- Observes `TabBarItemsPreferenceKey` to collect tabs
- ZStack with bottom alignment for tab bar overlay

---

## Component Breakdown

### AdventureTubeTabBarView (Main Container)

**File:** `AdventureTubeTabBarView.swift`

```swift
struct AdventureTubeTabBarView: View {
    @EnvironmentObject private var loginManager: LoginManager
    @State private var tabSelection: TabBarItemInfoEnum = .setting

    var body: some View {
        CustomTabBarContainerView(selection: $tabSelection) {
            MapView()
                .tabBarItem(tab: .storymap, selection: tabSelection)
            MainStoryView()
                .tabBarItem(tab: .mystory, selection: tabSelection)
            MainSavedStoryView()
                .tabBarItem(tab: .savedstory, selection: tabSelection)
            SettingView()
                .tabBarItem(tab: .setting, selection: tabSelection)
        }
    }
}
```

**Key Points:**
- Defines 4 views with their associated tabs
- Each view gets `.tabBarItem()` modifier
- `@State` tracks current selection
- `@EnvironmentObject` for auth state

---

### View Extension (Convenience API)

**File:** `AdventureTubeTabBarView.swift`

```swift
extension View {
    func tabBarItem(tab: TabBarItemInfoEnum, selection: TabBarItemInfoEnum) -> some View {
        modifier(TabBarItemViewModifer(tab: tab, selection: selection))
    }
}
```

**Usage:**
```swift
MyView()
    .tabBarItem(tab: .mystory, selection: currentSelection)
```

---

### CustomTabBarView (UI Rendering)

**File:** `CustomTabBarView.swift`

```swift
struct CustomTabBarView: View {
    let tabs: [TabBarItemInfoEnum]
    @Binding var selection: TabBarItemInfoEnum
    @Namespace private var namespace
    @State var localSelection: TabBarItemInfoEnum

    var body: some View {
        HStack {
            ForEach(tabs) { tab in
                tabView1(tab: tab)
                    .onTapGesture {
                        switchToTab(tab: tab)
                    }
            }
        }
        .padding(6)
        .background(Color.white.ignoresSafeArea(edges: .bottom))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
        .onChange(of: selection) { tab in
            withAnimation(.easeInOut) {
                localSelection = tab
            }
        }
    }

    private func switchToTab(tab: TabBarItemInfoEnum) {
        selection = tab
    }
}
```

**Styling:**
- White background with corner radius 10
- Shadow for depth (black 30% opacity, radius 10, y-offset 5)
- 6pt internal padding
- Horizontal margins

---

### CustomTabBarViewVM (Visibility State)

**File:** `CustomTabBarViewVM.swift`

```swift
class CustomTabBarViewVM: ObservableObject {
    static let shared = CustomTabBarViewVM()

    @Published var isTabBarViewShow: Bool = true

    private init() {}
}
```

**Purpose:**
- Global state for tab bar visibility
- Singleton pattern
- Used to hide tab bar (e.g., fullscreen video playback)

**Usage:**
```swift
customTabVM.isTabBarViewShow = false  // Hide tab bar
customTabVM.isTabBarViewShow = true   // Show tab bar
```

---

## Data Flow

### Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ 1. AdventureTubeTabBarView                                  │
│    - Defines 4 views with .tabBarItem()                     │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. View Extension calls TabBarItemViewModifer               │
│    - Sets opacity (selected: 1.0, others: 0.0)              │
│    - Calls .preference(key: TabBarItemsPreferenceKey)       │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. TabBarItemsPreferenceKey.reduce()                        │
│    - Collects all tabs into array                           │
│    - [.storymap, .mystory, .savedstory, .setting]           │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. CustomTabBarContainerView.onPreferenceChange()           │
│    - Receives complete tabs array                           │
│    - Updates @State var tabs                                │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. CustomTabBarView renders tabs                            │
│    - ForEach(tabs) creates tab items                        │
│    - Applies matchedGeometryEffect for selection            │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. User taps tab                                            │
│    - switchToTab() updates selection binding                │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. Selection binding propagates                             │
│    - CustomTabBarView: Updates localSelection (animated)    │
│    - TabBarItemViewModifer: Updates opacity on all views    │
│    - Selected view: opacity 1.0 (visible)                   │
│    - Other views: opacity 0.0 (hidden)                      │
└─────────────────────────────────────────────────────────────┘
```

---

## Navigation System

### NavigationStateManager

**File:** `NavigationStateManager.swift`

```swift
class NavigationStateManager: ObservableObject {
    @Published var selectionPath = NavigationPath()
}
```

**Purpose:** Programmatic navigation using SwiftUI's `NavigationPath`

**Usage:**
```swift
@EnvironmentObject var navigationState: NavigationStateManager

// Navigate to view
navigationState.selectionPath.append(destinationView)

// Pop back
navigationState.selectionPath.removeLast()

// Pop to root
navigationState.selectionPath = NavigationPath()
```

---

## Customization

### Changing Tab Icons

**File:** `TabBarItemInfoEnum.swift`

```swift
var iconName: String {
    switch self {
    case .storymap:   return "map.fill"  // Filled icon
    case .mystory:    return "film"      // Different icon
    // ...
    }
}
```

---

### Changing Tab Colors

```swift
var color: Color {
    switch self {
    case .storymap:   return Color.blue
    case .mystory:    return Color.green
    case .savedstory: return Color.orange
    case .setting:    return Color.purple
    }
}
```

---

### Custom Tab Bar Styling

**File:** `CustomTabBarView.swift`

```swift
.background(Color.blue.ignoresSafeArea(edges: .bottom))  // Blue background
.cornerRadius(20)                                         // Larger radius
.shadow(color: Color.red.opacity(0.5), radius: 15)       // Red shadow
```

---

### Adding New Tab

**Step 1:** Add to enum
```swift
enum TabBarItemInfoEnum {
    case storymap, mystory, savedstory, setting, newTab  // Add newTab

    var iconName: String {
        case .newTab: return "star"
    }

    var title: String {
        case .newTab: return "New Tab"
    }
}
```

**Step 2:** Add to main view
```swift
CustomTabBarContainerView(selection: $tabSelection) {
    // ... existing views ...
    NewTabView()
        .tabBarItem(tab: .newTab, selection: tabSelection)
}
```

---

## Best Practices

### ✅ Do

1. **Use enum for type safety**
   ```swift
   enum TabBarItemInfoEnum  // Type-safe, autocomplete-friendly
   ```

2. **Namespace for matched geometry**
   ```swift
   @Namespace private var namespace
   ```

3. **Animate selection changes**
   ```swift
   withAnimation(.easeInOut) {
       localSelection = tab
   }
   ```

4. **Hide tab bar when needed**
   ```swift
   customTabVM.isTabBarViewShow = false
   ```

5. **Use PreferenceKey for bottom-up data**
   ```swift
   .preference(key: TabBarItemsPreferenceKey.self, value: [tab])
   ```

---

### ❌ Don't

1. **Don't hardcode tab count**
   ```swift
   // Bad: Assuming 4 tabs
   // Good: ForEach(tabs) { ... }
   ```

2. **Don't forget opacity control**
   ```swift
   .opacity(selection == tab ? 1.0 : 0.0)  // Critical for visibility
   ```

3. **Don't skip transitions**
   ```swift
   .transition(AnyTransition.opacity.animation(.easeInOut))
   ```

4. **Don't create multiple namespaces**
   ```swift
   @Namespace private var namespace  // One per view
   ```

---

## Animation Breakdown

### Selection Animation

```swift
// When tab is tapped:
selection = newTab  // Updates binding

// CustomTabBarView.onChange(of: selection):
withAnimation(.easeInOut) {
    localSelection = newTab  // Animated update
}

// matchedGeometryEffect sees change:
// - Old tab's background disappears
// - New tab's background appears
// - SwiftUI interpolates position/size/shape
```

**Result:** Smooth sliding indicator animation

---

## Performance Considerations

### Opacity vs. If/Else

**Current approach (Opacity):**
```swift
.opacity(selection == tab ? 1.0 : 0.0)
```

**Pros:**
- All views remain in memory
- Fast switching (no view recreation)
- Preserves view state

**Cons:**
- Higher memory usage (all 4 views always loaded)

**Alternative (If/Else):**
```swift
if selection == .mystory {
    MainStoryView()
}
```

**Pros:**
- Lower memory (only selected view loaded)

**Cons:**
- Slower switching (view recreation)
- Loses view state on switch

**Current choice:** Opacity for better UX (fast switching, state preservation)

---

## Troubleshooting

### Issue: Tabs not appearing

**Cause:** PreferenceKey not collecting tabs

**Solution:** Ensure `.tabBarItem()` called on all views

---

### Issue: Animation not smooth

**Cause:** Missing namespace or mismatched IDs

**Solution:**
```swift
@Namespace private var namespace
.matchedGeometryEffect(id: "background_rectangle", in: namespace)
```

---

### Issue: Tab bar not hiding

**Cause:** `isTabBarViewShow` not updating

**Solution:**
```swift
@EnvironmentObject var customTabVM: CustomTabBarViewVM
customTabVM.isTabBarViewShow = false
```

---

## Related Documentation

- [MVVM Pattern](./MVVM-Pattern.md) - CustomTabBarViewVM
- [Combine Reactive Programming](./Combine-Reactive.md) - @Published properties

---

## Summary

AdventureTube's custom tab bar demonstrates:

✅ **Advanced SwiftUI** - PreferenceKey, ViewModifier, MatchedGeometryEffect
✅ **Clean Architecture** - Generic container, enum-based tabs
✅ **Smooth UX** - Animated transitions, state preservation
✅ **Flexibility** - Easy to customize, show/hide, add tabs
✅ **Type Safety** - Enum-based tab system

This implementation provides **production-quality** tab navigation with full design control and delightful animations! 🎯

---

[← Back to CLAUDE.md](../CLAUDE.md)
