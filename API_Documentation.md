# MacClipboard API Documentation

## Overview

MacClipboard is a powerful clipboard management application for macOS built with SwiftUI. This documentation covers all public APIs, functions, and components with examples and usage instructions.

## Table of Contents

1. [Models](#models)
2. [Services](#services)
3. [Views](#views)
4. [Protocols](#protocols)
5. [Usage Examples](#usage-examples)
6. [Architecture Overview](#architecture-overview)

---

## Models

### ClipboardItem

The core data structure representing a clipboard item.

```swift
struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let content: ClipboardContent
    let timestamp: Date
    var isFavorite: Bool
}
```

**Properties:**
- `id`: Unique identifier for the clipboard item
- `content`: The actual clipboard content (text or image)
- `timestamp`: When the item was added to the clipboard
- `isFavorite`: Whether the item is marked as favorite

**Initializer:**
```swift
init(id: UUID = UUID(), content: ClipboardContent, timestamp: Date = Date(), isFavorite: Bool = false)
```

**Example Usage:**
```swift
// Create a text clipboard item
let textItem = ClipboardItem(
    content: .text("Hello, World!"),
    isFavorite: false
)

// Create an image clipboard item
let imageData = imageView.image?.tiffRepresentation
let imageItem = ClipboardItem(
    content: .image(imageData!),
    isFavorite: true
)
```

### ClipboardContent

An enumeration representing different types of clipboard content.

```swift
enum ClipboardContent: Codable {
    case text(String)
    case image(Data)
}
```

**Cases:**
- `.text(String)`: Text content
- `.image(Data)`: Image data

**Example Usage:**
```swift
// Text content
let textContent = ClipboardContent.text("Sample text")

// Image content
let imageContent = ClipboardContent.image(imageData)

// Pattern matching
switch item.content {
case .text(let string):
    print("Text: \(string)")
case .image(let data):
    print("Image size: \(data.count) bytes")
}
```

### ClipboardManager

The main manager class that handles clipboard operations and state management.

```swift
class ClipboardManager: ObservableObject {
    @Published private(set) var clipboardItems: [ClipboardItem]
    @Published private(set) var customGroups: [CustomGroup]
    var favoriteItems: [ClipboardItem] { get }
}
```

**Key Methods:**

#### Initialization
```swift
init(maxItems: Int = 50, 
     pasteboard: PasteboardProtocol = SystemPasteboard(),
     monitoringInterval: TimeInterval = 0.5)
```

#### Clipboard Operations
```swift
func checkForChanges(completion: (() -> Void)? = nil)
func copyToClipboard(_ item: ClipboardItem, completion: (() -> Void)? = nil)
func deleteItem(_ item: ClipboardItem, completion: (() -> Void)? = nil)
func clearHistory(completion: (() -> Void)? = nil)
```

#### Favorite Operations
```swift
func toggleFavorite(_ item: ClipboardItem, completion: (() -> Void)? = nil)
var favoriteItems: [ClipboardItem] { get }
```

#### Custom Group Operations
```swift
func createCustomGroup(name: String, completion: ((CustomGroup) -> Void)? = nil)
func deleteCustomGroup(_ group: CustomGroup)
func addItemToGroup(_ item: ClipboardItem, group: CustomGroup)
func removeItemFromGroup(_ item: ClipboardItem, group: CustomGroup)
func itemsInGroup(_ group: CustomGroup) -> [ClipboardItem]
func isItemInGroup(_ item: ClipboardItem, group: CustomGroup) -> Bool
```

**Example Usage:**
```swift
// Initialize clipboard manager
let clipboardManager = ClipboardManager(maxItems: 100)

// Copy item to clipboard
clipboardManager.copyToClipboard(item) {
    print("Item copied successfully")
}

// Create custom group
clipboardManager.createCustomGroup(name: "Development") { group in
    print("Group created: \(group.name)")
}

// Add item to group
clipboardManager.addItemToGroup(item, group: group)

// Toggle favorite
clipboardManager.toggleFavorite(item) {
    print("Favorite status toggled")
}
```

### CustomGroup

A structure representing a custom group for organizing clipboard items.

```swift
struct CustomGroup: Identifiable, Codable {
    let id: UUID
    var name: String
    var itemIds: Set<UUID>
}
```

**Properties:**
- `id`: Unique identifier for the group
- `name`: Display name of the group
- `itemIds`: Set of clipboard item IDs in this group

**Example Usage:**
```swift
// Create a custom group
let group = CustomGroup(
    name: "Code Snippets",
    itemIds: [item1.id, item2.id]
)

// Check if item is in group
if group.itemIds.contains(item.id) {
    print("Item is in group")
}
```

### Tab

An enumeration representing different tab types in the UI.

```swift
enum Tab: Equatable, Hashable {
    case all
    case favorites
    case custom(CustomGroup)
}
```

**Cases:**
- `.all`: Show all clipboard items
- `.favorites`: Show only favorite items
- `.custom(CustomGroup)`: Show items in a specific custom group

**Example Usage:**
```swift
// Switch between tabs
@State private var selectedTab: Tab = .all

// Change to favorites tab
selectedTab = .favorites

// Change to custom group tab
selectedTab = .custom(myGroup)
```

---

## Services

### ClipboardService

The service layer for clipboard operations.

```swift
class ClipboardService {
    static let shared = ClipboardService()
    
    func getCurrentContent() -> ClipboardContent?
    func copyToClipboard(_ content: ClipboardContent)
}
```

**Methods:**
- `getCurrentContent()`: Get current clipboard content
- `copyToClipboard(_:)`: Copy content to clipboard

**Example Usage:**
```swift
let service = ClipboardService.shared

// Get current clipboard content
if let content = service.getCurrentContent() {
    switch content {
    case .text(let text):
        print("Current text: \(text)")
    case .image(let data):
        print("Current image size: \(data.count)")
    }
}

// Copy content to clipboard
service.copyToClipboard(.text("Hello World"))
```

### ClipboardItemStorage

Handles persistence of clipboard items.

```swift
class ClipboardItemStorage {
    static var shared = ClipboardItemStorage()
    
    func saveItems(_ items: [ClipboardItem])
    func loadItems() -> [ClipboardItem]
}
```

**Methods:**
- `saveItems(_:)`: Save clipboard items to disk
- `loadItems()`: Load clipboard items from disk

**Example Usage:**
```swift
let storage = ClipboardItemStorage.shared

// Save items
storage.saveItems(clipboardItems)

// Load items
let loadedItems = storage.loadItems()
```

### CustomGroupStorage

Handles persistence of custom groups.

```swift
class CustomGroupStorage {
    static let shared = CustomGroupStorage()
    
    func saveGroups(_ groups: [CustomGroup])
    func loadGroups() -> [CustomGroup]
}
```

**Methods:**
- `saveGroups(_:)`: Save custom groups to disk
- `loadGroups()`: Load custom groups from disk

**Example Usage:**
```swift
let storage = CustomGroupStorage.shared

// Save groups
storage.saveGroups(customGroups)

// Load groups
let loadedGroups = storage.loadGroups()
```

### SystemPasteboard

Implementation of `PasteboardProtocol` for system clipboard operations.

```swift
final class SystemPasteboard: PasteboardProtocol {
    func clearContents()
    func setString(_ string: String, forType type: NSPasteboard.PasteboardType)
    func setData(_ data: Data, forType type: NSPasteboard.PasteboardType)
    func string(forType type: NSPasteboard.PasteboardType) -> String?
    func data(forType type: NSPasteboard.PasteboardType) -> Data?
    var changeCount: Int { get }
}
```

**Example Usage:**
```swift
let pasteboard = SystemPasteboard()

// Set text
pasteboard.setString("Hello", forType: .string)

// Get text
if let text = pasteboard.string(forType: .string) {
    print("Pasteboard text: \(text)")
}

// Check for changes
let currentCount = pasteboard.changeCount
```

---

## Views

### ContentView

The main view of the application.

```swift
struct ContentView: View {
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @State private var selectedItemId: UUID?
    @State private var showCopyToast = false
    @FocusState private var isSearchFocused: Bool
    @State private var searchText = ""
    @State private var selectedTab: Tab = .all
    
    var body: some View { ... }
}
```

**Key Features:**
- Displays clipboard history
- Provides search functionality
- Shows toast notifications
- Handles tab switching

**Example Usage:**
```swift
ContentView()
    .environmentObject(clipboardManager)
```

### ClipboardListView

Displays the list of clipboard items with search and filtering.

```swift
struct ClipboardListView: View {
    @Binding var selectedItemId: UUID?
    @FocusState.Binding var isSearchFocused: Bool
    @Binding var searchText: String
    @Binding var selectedTab: Tab
    let onCopy: () -> Void
    
    init(selectedItemId: Binding<UUID?>, 
         isSearchFocused: FocusState<Bool>.Binding,
         searchText: Binding<String>,
         selectedTab: Binding<Tab>,
         onCopy: @escaping () -> Void)
}
```

**Example Usage:**
```swift
ClipboardListView(
    selectedItemId: $selectedItemId,
    isSearchFocused: $isSearchFocused,
    searchText: $searchText,
    selectedTab: $selectedTab,
    onCopy: showCopyFeedback
)
```

### ClipboardItemRow

Displays individual clipboard items in the list.

```swift
struct ClipboardItemRow: View {
    let item: ClipboardItem
    @ObservedObject var clipboardManager: ClipboardManager
    let isLatest: Bool
    let isSelected: Bool
    let onCopy: () -> Void
    
    var body: some View { ... }
}
```

**Features:**
- Shows item content (text or image preview)
- Displays timestamp
- Provides copy, delete, and favorite actions
- Shows image preview popover

**Example Usage:**
```swift
ClipboardItemRow(
    item: clipboardItem,
    clipboardManager: clipboardManager,
    isLatest: index == 0,
    isSelected: selectedItemId == item.id,
    onCopy: onCopyAction
)
```

### ClipboardSearchBar

Provides search functionality for clipboard items.

```swift
struct ClipboardSearchBar: View {
    @Binding var searchText: String
    @FocusState.Binding var isSearchFocused: Bool
    
    var body: some View { ... }
}
```

**Example Usage:**
```swift
ClipboardSearchBar(
    searchText: $searchText,
    isSearchFocused: $isSearchFocused
)
```

### MenuBarContentView

The menu bar interface for quick access to clipboard items.

```swift
struct MenuBarContentView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    
    var body: some View { ... }
}
```

**Features:**
- Shows latest clipboard item
- Displays recent items
- Provides quick actions (clear history, quit)
- Shows custom groups

**Example Usage:**
```swift
MenuBarContentView(clipboardManager: clipboardManager)
```

### LatestItemView

Displays the most recent clipboard item in the menu bar.

```swift
struct LatestItemView: View {
    let item: ClipboardItem
    @ObservedObject var clipboardManager: ClipboardManager
    
    var body: some View { ... }
}
```

**Example Usage:**
```swift
LatestItemView(
    item: latestItem,
    clipboardManager: clipboardManager
)
```

### ToastView

Shows temporary notifications to the user.

```swift
struct ToastView: View {
    let message: String
    
    var body: some View { ... }
}
```

**Example Usage:**
```swift
ToastView(message: "Copied to clipboard!")
    .transition(.move(edge: .bottom).combined(with: .opacity))
```

---

## Protocols

### PasteboardProtocol

Abstraction for pasteboard operations, allowing for testing and mocking.

```swift
protocol PasteboardProtocol {
    func clearContents()
    func setString(_ string: String, forType type: NSPasteboard.PasteboardType)
    func setData(_ data: Data, forType type: NSPasteboard.PasteboardType)
    func string(forType type: NSPasteboard.PasteboardType) -> String?
    func data(forType type: NSPasteboard.PasteboardType) -> Data?
    var changeCount: Int { get }
}
```

**Example Implementation:**
```swift
class MockPasteboard: PasteboardProtocol {
    private var contents: [NSPasteboard.PasteboardType: Any] = [:]
    var changeCount: Int = 0
    
    func clearContents() {
        contents.removeAll()
        changeCount += 1
    }
    
    func setString(_ string: String, forType type: NSPasteboard.PasteboardType) {
        contents[type] = string
        changeCount += 1
    }
    
    // ... other methods
}
```

---

## Usage Examples

### Basic Clipboard Management

```swift
// Initialize the clipboard manager
let clipboardManager = ClipboardManager()

// Check for new clipboard content
clipboardManager.checkForChanges {
    print("Clipboard check completed")
}

// Copy an item back to clipboard
clipboardManager.copyToClipboard(item) {
    print("Item copied successfully")
}

// Delete an item
clipboardManager.deleteItem(item) {
    print("Item deleted")
}

// Clear history (keeps recent, favorites, and grouped items)
clipboardManager.clearHistory {
    print("History cleared")
}
```

### Working with Favorites

```swift
// Toggle favorite status
clipboardManager.toggleFavorite(item) {
    print("Favorite toggled")
}

// Get all favorite items
let favorites = clipboardManager.favoriteItems
print("Found \(favorites.count) favorite items")

// Check if item is favorite
if item.isFavorite {
    print("This item is marked as favorite")
}
```

### Custom Groups Management

```swift
// Create a custom group
clipboardManager.createCustomGroup(name: "Code Snippets") { group in
    print("Created group: \(group.name)")
    
    // Add items to the group
    clipboardManager.addItemToGroup(item1, group: group)
    clipboardManager.addItemToGroup(item2, group: group)
}

// Get items in a group
let groupItems = clipboardManager.itemsInGroup(group)
print("Group has \(groupItems.count) items")

// Check if item is in group
if clipboardManager.isItemInGroup(item, group: group) {
    print("Item is in the group")
}

// Remove item from group
clipboardManager.removeItemFromGroup(item, group: group)

// Delete the entire group
clipboardManager.deleteCustomGroup(group)
```

### UI Integration

```swift
// Main app setup
@main
struct MacClipboardApp: App {
    @StateObject private var clipboardManager = ClipboardManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(clipboardManager)
        }
        
        MenuBarExtra("Clipboard", systemImage: "clipboard") {
            MenuBarContentView(clipboardManager: clipboardManager)
        }
    }
}

// Using in a view
struct MyView: View {
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @State private var searchText = ""
    @State private var selectedTab: Tab = .all
    
    var body: some View {
        VStack {
            // Search bar
            ClipboardSearchBar(
                searchText: $searchText,
                isSearchFocused: $isSearchFocused
            )
            
            // Filtered items
            let filteredItems = clipboardManager.clipboardItems.filter { item in
                searchText.isEmpty || itemContainsText(item, searchText)
            }
            
            // Display items
            ForEach(filteredItems) { item in
                ClipboardItemRow(
                    item: item,
                    clipboardManager: clipboardManager,
                    isLatest: item.id == filteredItems.first?.id,
                    isSelected: selectedItemId == item.id,
                    onCopy: { showCopyToast() }
                )
            }
        }
    }
}
```

### Testing with Mock Objects

```swift
// Create mock pasteboard for testing
class MockPasteboard: PasteboardProtocol {
    var mockChangeCount = 0
    var mockString: String?
    var mockData: Data?
    
    var changeCount: Int { mockChangeCount }
    
    func string(forType type: NSPasteboard.PasteboardType) -> String? {
        return mockString
    }
    
    func data(forType type: NSPasteboard.PasteboardType) -> Data? {
        return mockData
    }
    
    func setString(_ string: String, forType type: NSPasteboard.PasteboardType) {
        mockString = string
        mockChangeCount += 1
    }
    
    func setData(_ data: Data, forType type: NSPasteboard.PasteboardType) {
        mockData = data
        mockChangeCount += 1
    }
    
    func clearContents() {
        mockString = nil
        mockData = nil
        mockChangeCount += 1
    }
}

// Use in tests
func testClipboardManager() {
    let mockPasteboard = MockPasteboard()
    let clipboardManager = ClipboardManager(pasteboard: mockPasteboard)
    
    // Test adding content
    mockPasteboard.mockString = "Test content"
    mockPasteboard.mockChangeCount = 1
    
    clipboardManager.checkForChanges {
        XCTAssertEqual(clipboardManager.clipboardItems.count, 1)
        XCTAssertEqual(clipboardManager.clipboardItems.first?.content, .text("Test content"))
    }
}
```

---

## Architecture Overview

### Key Design Patterns

1. **MVVM (Model-View-ViewModel)**: Uses SwiftUI's `@ObservableObject` pattern with `ClipboardManager` as the view model.

2. **Dependency Injection**: `PasteboardProtocol` allows for easy testing and mocking.

3. **Observer Pattern**: `ClipboardManager` monitors clipboard changes and publishes updates.

4. **Command Pattern**: Actions are encapsulated in closures for async operations.

5. **Repository Pattern**: Storage classes abstract data persistence.

### Data Flow

1. **Clipboard Monitoring**: `ClipboardManager` monitors system clipboard changes via timer
2. **Content Processing**: New content is processed and added to the items array
3. **Storage**: Items are automatically saved to disk when changed
4. **UI Updates**: SwiftUI views react to published changes via `@ObservableObject`
5. **User Actions**: UI actions trigger clipboard operations through the manager

### Thread Safety

- All clipboard operations are performed on a dedicated `updateQueue`
- UI updates are dispatched to the main queue
- Storage operations are performed asynchronously

### Error Handling

- Storage operations include error handling with console logging
- Completion handlers provide feedback for async operations
- Graceful degradation when clipboard access fails

This documentation provides a comprehensive guide to using the MacClipboard API. For additional examples and advanced usage, refer to the source code and test files.