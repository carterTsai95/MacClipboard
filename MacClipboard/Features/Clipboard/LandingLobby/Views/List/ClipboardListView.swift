import SwiftUI

struct ClipboardListView: View {
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @Binding var selectedItemId: UUID?
    @FocusState.Binding var isSearchFocused: Bool
    @Binding var searchText: String
    @Binding var selectedTab: Tab
    let onCopy: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    init(selectedItemId: Binding<UUID?>, isSearchFocused: FocusState<Bool>.Binding, searchText: Binding<String>, selectedTab: Binding<Tab>, onCopy: @escaping () -> Void) {
        self._selectedItemId = selectedItemId
        self._isSearchFocused = isSearchFocused
        self._searchText = searchText
        self._selectedTab = selectedTab
        self.onCopy = onCopy
    }
    
    var filteredItems: [ClipboardItem] {
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
            switch item.content {
            case .text(let string):
                return string.localizedCaseInsensitiveContains(searchText)
            case .image:
                return false // Images are not searchable
            }
        }
    }
    
    var body: some View {
        VStack {
            ClipboardSearchBar(searchText: $searchText, isSearchFocused: $isSearchFocused)
            
            ClipboardGroupTabs(clipboardManager: clipboardManager, selectedTab: $selectedTab)
            
            ClipboardItemsList(
                clipboardManager: clipboardManager,
                selectedItemId: $selectedItemId,
                onCopy: onCopy,
                filteredItems: filteredItems,
                selectedTab: selectedTab
            )
            .background(colorScheme == .dark ? Color.black : Color.white)
        }
        .onAppear {
            updateSelectionForTab(selectedTab)
        }
    }
    
    private func updateSelectionForTab(_ tab: Tab) {
        print("🔄 Updating selection for tab: \(tab)")
        
        let items: [ClipboardItem]
        switch tab {
        case .all:
            items = clipboardManager.clipboardItems
            print("📋 All items count: \(items.count)")
        case .favorites:
            items = clipboardManager.favoriteItems
            print("⭐️ Favorite items count: \(items.count)")
        case .custom(let group):
            items = clipboardManager.itemsInGroup(group)
            print("📁 Group '\(group.name)' items count: \(items.count)")
            print("📁 Group '\(group.name)' itemIds: \(group.itemIds)")
        }
        
        // If no items in the tab, do nothing
        guard !items.isEmpty else {
            print("❌ No items in tab, keeping current selection")
            return
        }
        
        print("🎯 Current selection ID: \(selectedItemId?.uuidString ?? "nil")")
        
        // If current selection is not in the tab, select the first item
        if let currentId = selectedItemId, !items.contains(where: { $0.id == currentId }) {
            selectedItemId = items.first?.id
            print("🔄 Selection not in tab, updating to: \(items.first?.id.uuidString ?? "nil")")
        } else if selectedItemId == nil {
            // If nothing is selected, select the first item
            selectedItemId = items.first?.id
            print("🆕 No current selection, setting to: \(items.first?.id.uuidString ?? "nil")")
        } else {
            print("✅ Keeping current selection: \(selectedItemId?.uuidString ?? "nil")")
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var clipboardManager = ClipboardManager()
        @State private var selectedItemId: UUID?
        @FocusState private var isSearchFocused: Bool
        @State private var searchText = ""
        @State private var selectedTab: Tab = .all
        
        // Create sample items directly for preview
        private let sampleItems: [ClipboardItem] = [
            ClipboardItem(content: .text("Sample text 1"))
        ]
        
        var body: some View {
            ClipboardListView(
                selectedItemId: $selectedItemId,
                isSearchFocused: $isSearchFocused,
                searchText: $searchText,
                selectedTab: $selectedTab,
                onCopy: {}
            )
            .environmentObject(clipboardManager)
            .frame(width: 600, height: 600)
            .task {
                // Use public methods to add items
                for item in sampleItems {
                    clipboardManager.copyToClipboard(item)
                }
                // Make the second item a favorite
                if let secondItem = clipboardManager.clipboardItems.dropFirst().first {
                    clipboardManager.toggleFavorite(secondItem)
                }
            }
        }
    }
    
    return PreviewWrapper()
} 
