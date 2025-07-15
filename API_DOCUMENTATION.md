# MacClipboard API Documentation

## Table of Contents

1. [Overview](#overview)
2. [Core Models](#core-models)
3. [ClipboardManager](#clipboardmanager)
4. [Services](#services)
5. [UI Components](#ui-components)
6. [Protocols](#protocols)
7. [Usage Examples](#usage-examples)

## Overview

MacClipboard is a powerful clipboard management application for macOS that provides comprehensive clipboard history management, search functionality, custom groups, and favorites system. This documentation covers all public APIs, functions, and components available for developers.

## Core Models

### ClipboardItem

Represents a single clipboard item with content, metadata, and state.

```swift
struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let content: ClipboardContent
    let timestamp: Date
    var isFavorite: Bool
}
```

**Properties:**
- `id: UUID` - Unique identifier for the clipboard item
- `content: ClipboardContent` - The actual content (text or image)
- `timestamp: Date` - When the item was added to clipboard
- `isFavorite: Bool` - Whether the item is marked as favorite

**Initializer:**
```swift
init(id: UUID = UUID(), content: ClipboardContent, timestamp: Date = Date(), isFavorite: Bool = false)
```

**Example:**
```swift
let textItem = ClipboardItem(content: .text("Hello, World!"))
let imageItem = ClipboardItem(content: .image(imageData), isFavorite: true)
```

### ClipboardContent

Represents the content of a clipboard item, supporting both text and image data.

```swift
enum ClipboardContent: Codable {
    case text(String)
    case image(Data)
}
```

**Cases:**
- `text(String)` - Text content
- `image(Data)` - Image data (TIFF or PNG format)

**Example:**
```swift
let textContent = ClipboardContent.text("Sample text")
let imageContent = ClipboardContent.image(imageData)

// Accessing content
switch content {
case .text(let string):
    print("Text: \(string)")
case .image(let data):
    print("Image data size: \(data.count)")
}
```

### CustomGroup

Represents a custom group for organizing clipboard items.

```swift
struct CustomGroup: Identifiable, Codable {
    let id: UUID
    var name: String
    var itemIds: Set<UUID>
}
```

**Properties:**
- `id: UUID` - Unique identifier for the group
- `name: String` - Display name of the group
- `itemIds: Set<UUID>` - Set of clipboard item IDs in this group

**Initializer:**
```swift
init(id: UUID = UUID(), name: String, itemIds: Set<UUID> = [])
```

**Example:**
```swift
let group = CustomGroup(name: "Work Items")
let groupWithItems = CustomGroup(name: "Personal", itemIds: [item1.id, item2.id])
```

### Tab

Represents different views/tabs in the clipboard interface.

```swift
enum Tab: Equatable, Hashable {
    case all
    case favorites
    case custom(CustomGroup)
}
```

**Cases:**
- `all` - Shows all clipboard items
- `favorites` - Shows only favorite items
- `custom(CustomGroup)` - Shows items in a specific custom group

**Example:**
```swift
let allTab = Tab.all
let favoritesTab = Tab.favorites
let customTab = Tab.custom(myGroup)
```

## ClipboardManager

The main manager class that handles clipboard monitoring, item management, and state.

### Initialization

```swift
class ClipboardManager: ObservableObject {
    init(maxItems: Int = 50, 
         pasteboard: PasteboardProtocol = SystemPasteboard(),
         monitoringInterval: TimeInterval = 0.5)
}
```

**Parameters:**
- `maxItems: Int` - Maximum number of clipboard items to keep (default: 50)
- `pasteboard: PasteboardProtocol` - Pasteboard implementation (default: SystemPasteboard)
- `monitoringInterval: TimeInterval` - How often to check for clipboard changes (default: 0.5 seconds)

**Example:**
```swift
let manager = ClipboardManager(maxItems: 100, monitoringInterval: 1.0)
```

### Published Properties

```swift
@Published private(set) var clipboardItems: [ClipboardItem] = []
@Published private(set) var customGroups: [CustomGroup] = []
```

- `clipboardItems` - Array of all clipboard items (read-only)
- `customGroups` - Array of custom groups (read-only)

### Core Methods

#### Clipboard Operations

```swift
func copyToClipboard(_ item: ClipboardItem, completion: (() -> Void)? = nil)
```

Copies an item to the system clipboard and moves it to the top of the list.

**Parameters:**
- `item: ClipboardItem` - The item to copy
- `completion: (() -> Void)?` - Optional completion handler

**Example:**
```swift
clipboardManager.copyToClipboard(item) {
    print("Item copied successfully")
}
```

```swift
func deleteItem(_ item: ClipboardItem, completion: (() -> Void)? = nil)
```

Deletes a clipboard item from the history.

**Parameters:**
- `item: ClipboardItem` - The item to delete
- `completion: (() -> Void)?` - Optional completion handler

**Example:**
```swift
clipboardManager.deleteItem(item) {
    print("Item deleted")
}
```

```swift
func clearHistory(completion: (() -> Void)? = nil)
```

Clears clipboard history while preserving favorites and items in custom groups.

**Parameters:**
- `completion: (() -> Void)?` - Optional completion handler

**Example:**
```swift
clipboardManager.clearHistory {
    print("History cleared")
}
```

#### Favorites Management

```swift
func toggleFavorite(_ item: ClipboardItem, completion: (() -> Void)? = nil)
```

Toggles the favorite status of a clipboard item.

**Parameters:**
- `item: ClipboardItem` - The item to toggle favorite status
- `completion: (() -> Void)?` - Optional completion handler

**Example:**
```swift
clipboardManager.toggleFavorite(item) {
    print("Favorite status toggled")
}
```

```swift
var favoriteItems: [ClipboardItem]
```

Returns all favorite clipboard items.

**Example:**
```swift
let favorites = clipboardManager.favoriteItems
```

#### Custom Groups Management

```swift
func createCustomGroup(name: String, completion: ((CustomGroup) -> Void)? = nil)
```

Creates a new custom group.

**Parameters:**
- `name: String` - Name of the group
- `completion: ((CustomGroup) -> Void)?` - Optional completion handler with the created group

**Example:**
```swift
clipboardManager.createCustomGroup(name: "Work Items") { group in
    print("Created group: \(group.name)")
}
```

```swift
func deleteCustomGroup(_ group: CustomGroup)
```

Deletes a custom group.

**Parameters:**
- `group: CustomGroup` - The group to delete

**Example:**
```swift
clipboardManager.deleteCustomGroup(group)
```

```swift
func addItemToGroup(_ item: ClipboardItem, group: CustomGroup)
```

Adds a clipboard item to a custom group.

**Parameters:**
- `item: ClipboardItem` - The item to add
- `group: CustomGroup` - The target group

**Example:**
```swift
clipboardManager.addItemToGroup(item, group: workGroup)
```

```swift
func removeItemFromGroup(_ item: ClipboardItem, group: CustomGroup)
```

Removes a clipboard item from a custom group.

**Parameters:**
- `item: ClipboardItem` - The item to remove
- `group: CustomGroup` - The source group

**Example:**
```swift
clipboardManager.removeItemFromGroup(item, group: workGroup)
```

```swift
func itemsInGroup(_ group: CustomGroup) -> [ClipboardItem]
```

Returns all clipboard items in a specific group.

**Parameters:**
- `group: CustomGroup` - The group to query

**Returns:**
- `[ClipboardItem]` - Array of items in the group

**Example:**
```swift
let workItems = clipboardManager.itemsInGroup(workGroup)
```

```swift
func isItemInGroup(_ item: ClipboardItem, group: CustomGroup) -> Bool
```

Checks if a clipboard item is in a specific group.

**Parameters:**
- `item: ClipboardItem` - The item to check
- `group: CustomGroup` - The group to check against

**Returns:**
- `Bool` - True if the item is in the group

**Example:**
```swift
let isInWorkGroup = clipboardManager.isItemInGroup(item, group: workGroup)
```

#### Monitoring

```swift
func checkForChanges(completion: (() -> Void)? = nil)
```

Manually checks for clipboard changes.

**Parameters:**
- `completion: (() -> Void)?` - Optional completion handler

**Example:**
```swift
clipboardManager.checkForChanges {
    print("Clipboard check completed")
}
```

## Services

### ClipboardService

Handles clipboard content retrieval and setting.

```swift
class ClipboardService {
    static let shared = ClipboardService()
    
    init(pasteboard: PasteboardProtocol = SystemPasteboard())
}
```

#### Methods

```swift
func getCurrentContent() -> ClipboardContent?
```

Retrieves the current clipboard content.

**Returns:**
- `ClipboardContent?` - The current clipboard content or nil if empty

**Example:**
```swift
if let content = clipboardService.getCurrentContent() {
    switch content {
    case .text(let string):
        print("Clipboard contains text: \(string)")
    case .image(let data):
        print("Clipboard contains image: \(data.count) bytes")
    }
}
```

```swift
func copyToClipboard(_ content: ClipboardContent)
```

Copies content to the system clipboard.

**Parameters:**
- `content: ClipboardContent` - The content to copy

**Example:**
```swift
clipboardService.copyToClipboard(.text("Hello, World!"))
clipboardService.copyToClipboard(.image(imageData))
```

### ClipboardItemStorage

Handles persistence of clipboard items.

```swift
class ClipboardItemStorage {
    static var shared = ClipboardItemStorage()
}
```

#### Methods

```swift
func saveItems(_ items: [ClipboardItem])
```

Saves clipboard items to persistent storage.

**Parameters:**
- `items: [ClipboardItem]` - Array of items to save

**Example:**
```swift
ClipboardItemStorage.shared.saveItems(clipboardItems)
```

```swift
func loadItems() -> [ClipboardItem]
```

Loads clipboard items from persistent storage.

**Returns:**
- `[ClipboardItem]` - Array of loaded items

**Example:**
```swift
let savedItems = ClipboardItemStorage.shared.loadItems()
```

### CustomGroupStorage

Handles persistence of custom groups.

```swift
class CustomGroupStorage {
    static let shared = CustomGroupStorage()
}
```

#### Methods

```swift
func saveGroups(_ groups: [CustomGroup])
```

Saves custom groups to persistent storage.

**Parameters:**
- `groups: [CustomGroup]` - Array of groups to save

**Example:**
```swift
CustomGroupStorage.shared.saveGroups(customGroups)
```

```swift
func loadGroups() -> [CustomGroup]
```

Loads custom groups from persistent storage.

**Returns:**
- `[CustomGroup]` - Array of loaded groups

**Example:**
```swift
let savedGroups = CustomGroupStorage.shared.loadGroups()
```

## UI Components

### ClipboardListView

Main list view component for displaying clipboard items.

```swift
struct ClipboardListView: View {
    init(selectedItemId: Binding<UUID?>, 
         isSearchFocused: FocusState<Bool>.Binding, 
         searchText: Binding<String>, 
         selectedTab: Binding<Tab>, 
         onCopy: @escaping () -> Void)
}
```

**Parameters:**
- `selectedItemId: Binding<UUID?>` - Binding to the currently selected item ID
- `isSearchFocused: FocusState<Bool>.Binding` - Binding to search focus state
- `searchText: Binding<String>` - Binding to search text
- `selectedTab: Binding<Tab>` - Binding to the currently selected tab
- `onCopy: @escaping () -> Void` - Callback when an item is copied

**Example:**
```swift
ClipboardListView(
    selectedItemId: $selectedItemId,
    isSearchFocused: $isSearchFocused,
    searchText: $searchText,
    selectedTab: $selectedTab,
    onCopy: { showCopyToast() }
)
```

### ClipboardSearchBar

Search bar component for filtering clipboard items.

```swift
struct ClipboardSearchBar: View {
    @Binding var searchText: String
    @FocusState.Binding var isSearchFocused: Bool
}
```

**Parameters:**
- `searchText: Binding<String>` - Binding to search text
- `isSearchFocused: FocusState<Bool>.Binding` - Binding to focus state

**Example:**
```swift
ClipboardSearchBar(
    searchText: $searchText,
    isSearchFocused: $isSearchFocused
)
```

### ClipboardGroupTabs

Tab component for switching between different views.

```swift
struct ClipboardGroupTabs: View {
    let clipboardManager: ClipboardManager
    @Binding var selectedTab: Tab
}
```

**Parameters:**
- `clipboardManager: ClipboardManager` - The clipboard manager instance
- `selectedTab: Binding<Tab>` - Binding to the selected tab

**Example:**
```swift
ClipboardGroupTabs(
    clipboardManager: clipboardManager,
    selectedTab: $selectedTab
)
```

### ClipboardItemsList

List component for displaying clipboard items.

```swift
struct ClipboardItemsList: View {
    let clipboardManager: ClipboardManager
    @Binding var selectedItemId: UUID?
    let onCopy: () -> Void
    let filteredItems: [ClipboardItem]
    let selectedTab: Tab
}
```

**Parameters:**
- `clipboardManager: ClipboardManager` - The clipboard manager instance
- `selectedItemId: Binding<UUID?>` - Binding to the selected item ID
- `onCopy: () -> Void` - Copy callback
- `filteredItems: [ClipboardItem]` - Items to display
- `selectedTab: Tab` - Current tab

**Example:**
```swift
ClipboardItemsList(
    clipboardManager: clipboardManager,
    selectedItemId: $selectedItemId,
    onCopy: { showCopyToast() },
    filteredItems: filteredItems,
    selectedTab: selectedTab
)
```

### ClipboardItemRow

Individual row component for displaying a clipboard item.

```swift
struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    let onCopy: () -> Void
    let onDelete: () -> Void
    let onToggleFavorite: () -> Void
    let onAddToGroup: (CustomGroup) -> Void
    let onRemoveFromGroup: (CustomGroup) -> Void
    let customGroups: [CustomGroup]
    let selectedTab: Tab
}
```

**Parameters:**
- `item: ClipboardItem` - The clipboard item to display
- `isSelected: Bool` - Whether this item is selected
- `onCopy: () -> Void` - Copy callback
- `onDelete: () -> Void` - Delete callback
- `onToggleFavorite: () -> Void` - Toggle favorite callback
- `onAddToGroup: (CustomGroup) -> Void` - Add to group callback
- `onRemoveFromGroup: (CustomGroup) -> Void` - Remove from group callback
- `customGroups: [CustomGroup]` - Available custom groups
- `selectedTab: Tab` - Current tab

**Example:**
```swift
ClipboardItemRow(
    item: item,
    isSelected: selectedItemId == item.id,
    onCopy: { clipboardManager.copyToClipboard(item) },
    onDelete: { clipboardManager.deleteItem(item) },
    onToggleFavorite: { clipboardManager.toggleFavorite(item) },
    onAddToGroup: { group in clipboardManager.addItemToGroup(item, group: group) },
    onRemoveFromGroup: { group in clipboardManager.removeItemFromGroup(item, group: group) },
    customGroups: clipboardManager.customGroups,
    selectedTab: selectedTab
)
```

### MenuBar Components

#### MenuBarContentView

Main menu bar content view.

```swift
struct MenuBarContentView: View {
    let clipboardManager: ClipboardManager
}
```

**Parameters:**
- `clipboardManager: ClipboardManager` - The clipboard manager instance

**Example:**
```swift
MenuBarContentView(clipboardManager: clipboardManager)
```

#### LatestItemView

Displays the most recent clipboard item in the menu bar.

```swift
struct LatestItemView: View {
    let item: ClipboardItem?
    let onCopy: () -> Void
}
```

**Parameters:**
- `item: ClipboardItem?` - The latest clipboard item
- `onCopy: () -> Void` - Copy callback

**Example:**
```swift
LatestItemView(
    item: clipboardManager.clipboardItems.first,
    onCopy: { clipboardManager.copyToClipboard(item) }
)
```

#### RecentItemsView

Displays recent clipboard items in the menu bar.

```swift
struct RecentItemsView: View {
    let items: [ClipboardItem]
    let onCopy: (ClipboardItem) -> Void
}
```

**Parameters:**
- `items: [ClipboardItem]` - Recent items to display
- `onCopy: (ClipboardItem) -> Void` - Copy callback with item

**Example:**
```swift
RecentItemsView(
    items: Array(clipboardManager.clipboardItems.prefix(5)),
    onCopy: { item in clipboardManager.copyToClipboard(item) }
)
```

#### CustomGroupsView

Displays custom groups in the menu bar.

```swift
struct CustomGroupsView: View {
    let groups: [CustomGroup]
    let onSelectGroup: (CustomGroup) -> Void
}
```

**Parameters:**
- `groups: [CustomGroup]` - Custom groups to display
- `onSelectGroup: (CustomGroup) -> Void` - Group selection callback

**Example:**
```swift
CustomGroupsView(
    groups: clipboardManager.customGroups,
    onSelectGroup: { group in /* Handle group selection */ }
)
```

### Common Components

#### ToastView

Simple toast notification component.

```swift
struct ToastView: View {
    let message: String
}
```

**Parameters:**
- `message: String` - The message to display

**Example:**
```swift
ToastView(message: "Copied to clipboard!")
```

#### ImagePreviewView

Component for previewing image clipboard items.

```swift
struct ImagePreviewView: View {
    let imageData: Data
}
```

**Parameters:**
- `imageData: Data` - The image data to display

**Example:**
```swift
ImagePreviewView(imageData: imageData)
```

## Protocols

### PasteboardProtocol

Protocol for clipboard/pasteboard operations.

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

**Methods:**
- `clearContents()` - Clears all clipboard contents
- `setString(_:forType:)` - Sets a string for a specific pasteboard type
- `setData(_:forType:)` - Sets data for a specific pasteboard type
- `string(forType:)` - Retrieves a string for a specific pasteboard type
- `data(forType:)` - Retrieves data for a specific pasteboard type
- `changeCount` - Current change count of the pasteboard

### SystemPasteboard

Default implementation of PasteboardProtocol using NSPasteboard.

```swift
final class SystemPasteboard: PasteboardProtocol {
    init(pasteboard: NSPasteboard = .general)
}
```

**Parameters:**
- `pasteboard: NSPasteboard` - The NSPasteboard instance to use (default: .general)

**Example:**
```swift
let pasteboard = SystemPasteboard()
```

## Usage Examples

### Basic Setup

```swift
import SwiftUI

@main
struct MyApp: App {
    @StateObject private var clipboardManager = ClipboardManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(clipboardManager)
        }
    }
}
```

### Creating a Custom Clipboard Manager

```swift
// Custom configuration
let customManager = ClipboardManager(
    maxItems: 100,
    pasteboard: SystemPasteboard(),
    monitoringInterval: 1.0
)

// Observe changes
class MyViewModel: ObservableObject {
    @Published var clipboardItems: [ClipboardItem] = []
    private var clipboardManager = ClipboardManager()
    
    init() {
        clipboardManager.$clipboardItems
            .assign(to: &$clipboardItems)
    }
}
```

### Working with Clipboard Items

```swift
// Create clipboard items
let textItem = ClipboardItem(content: .text("Sample text"))
let imageItem = ClipboardItem(content: .image(imageData), isFavorite: true)

// Copy items to clipboard
clipboardManager.copyToClipboard(textItem)
clipboardManager.copyToClipboard(imageItem)

// Toggle favorites
clipboardManager.toggleFavorite(textItem)

// Delete items
clipboardManager.deleteItem(imageItem)

// Get favorites
let favorites = clipboardManager.favoriteItems
```

### Managing Custom Groups

```swift
// Create groups
clipboardManager.createCustomGroup(name: "Work") { group in
    print("Created work group: \(group.id)")
}

clipboardManager.createCustomGroup(name: "Personal") { group in
    print("Created personal group: \(group.id)")
}

// Add items to groups
if let workGroup = clipboardManager.customGroups.first(where: { $0.name == "Work" }) {
    clipboardManager.addItemToGroup(item, group: workGroup)
}

// Get items in a group
if let workGroup = clipboardManager.customGroups.first(where: { $0.name == "Work" }) {
    let workItems = clipboardManager.itemsInGroup(workGroup)
}

// Remove items from groups
clipboardManager.removeItemFromGroup(item, group: workGroup)

// Delete groups
clipboardManager.deleteCustomGroup(workGroup)
```

### Building Custom UI Components

```swift
struct CustomClipboardView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var selectedItemId: UUID?
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @State private var selectedTab: Tab = .all
    
    var body: some View {
        VStack {
            // Search bar
            ClipboardSearchBar(
                searchText: $searchText,
                isSearchFocused: $isSearchFocused
            )
            
            // Group tabs
            ClipboardGroupTabs(
                clipboardManager: clipboardManager,
                selectedTab: $selectedTab
            )
            
            // Items list
            ClipboardItemsList(
                clipboardManager: clipboardManager,
                selectedItemId: $selectedItemId,
                onCopy: { showCopyToast() },
                filteredItems: filteredItems,
                selectedTab: selectedTab
            )
        }
    }
    
    private var filteredItems: [ClipboardItem] {
        let items: [ClipboardItem]
        switch selectedTab {
        case .all:
            items = clipboardManager.clipboardItems
        case .favorites:
            items = clipboardManager.favoriteItems
        case .custom(let group):
            items = clipboardManager.itemsInGroup(group)
        }
        
        if searchText.isEmpty {
            return items
        }
        return items.filter { item in
            if case .text(let string) = item.content {
                return string.localizedCaseInsensitiveContains(searchText)
            }
            return false
        }
    }
    
    private func showCopyToast() {
        // Implementation for showing copy feedback
    }
}
```

### Custom Pasteboard Implementation

```swift
class MockPasteboard: PasteboardProtocol {
    private var contents: [NSPasteboard.PasteboardType: Any] = [:]
    private var currentChangeCount = 0
    
    func clearContents() {
        contents.removeAll()
        currentChangeCount += 1
    }
    
    func setString(_ string: String, forType type: NSPasteboard.PasteboardType) {
        contents[type] = string
        currentChangeCount += 1
    }
    
    func setData(_ data: Data, forType type: NSPasteboard.PasteboardType) {
        contents[type] = data
        currentChangeCount += 1
    }
    
    func string(forType type: NSPasteboard.PasteboardType) -> String? {
        return contents[type] as? String
    }
    
    func data(forType type: NSPasteboard.PasteboardType) -> Data? {
        return contents[type] as? Data
    }
    
    var changeCount: Int {
        return currentChangeCount
    }
}

// Use in testing
let mockPasteboard = MockPasteboard()
let testManager = ClipboardManager(pasteboard: mockPasteboard)
```

### Keyboard Shortcuts Integration

```swift
struct ContentView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var selectedItemId: UUID?
    
    var body: some View {
        VStack {
            // Your content here
        }
        .onKeyPress(.upArrow) {
            moveSelection(up: true)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveSelection(up: false)
            return .handled
        }
        .onKeyPress(.return) {
            copySelectedItem()
            return .handled
        }
        .onKeyPress(phases: .down) { press in
            guard press.modifiers == .command else { return .ignored }
            
            if let keyChar = press.characters.first,
               let index = Int(String(keyChar)),
               index >= 1 && index <= 9 {
                let groupIndex = index - 1
                if groupIndex < clipboardManager.customGroups.count {
                    // Switch to custom group tab
                    return .handled
                }
            }
            return .ignored
        }
    }
    
    private func moveSelection(up: Bool) {
        // Implementation for moving selection
    }
    
    private func copySelectedItem() {
        if let selectedId = selectedItemId,
           let selectedItem = clipboardManager.clipboardItems.first(where: { $0.id == selectedId }) {
            clipboardManager.copyToClipboard(selectedItem)
        }
    }
}
```

This comprehensive documentation covers all public APIs, functions, and components in the MacClipboard project. Each section includes detailed explanations, parameter descriptions, return values, and practical usage examples to help developers integrate and extend the functionality effectively.