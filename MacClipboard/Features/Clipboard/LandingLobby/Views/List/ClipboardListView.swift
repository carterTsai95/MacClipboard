import SwiftUI

struct ClipboardListView: View {
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @Binding var selectedItemId: UUID?
    @FocusState.Binding var isSearchFocused: Bool
    @Binding var searchText: String
    @Binding var selectedTab: Tab
    let onCopy: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedTag: String? = nil
    
    init(selectedItemId: Binding<UUID?>, isSearchFocused: FocusState<Bool>.Binding, searchText: Binding<String>, selectedTab: Binding<Tab>, onCopy: @escaping () -> Void) {
        self._selectedItemId = selectedItemId
        self._isSearchFocused = isSearchFocused
        self._searchText = searchText
        self._selectedTab = selectedTab
        self.onCopy = onCopy
    }
    
    private func color(for tag: String) -> Color {
        let colors: [Color] = [
            .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink, .brown, .gray
        ]
        let hash = tag.unicodeScalars.reduce(0, { $0 + UInt32($1.value) })
        let colorIndex = Int(hash) % colors.count
        return colors[colorIndex].opacity(0.3)
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
        
        var result = items
        
        if !searchText.isEmpty {
            result = result.filter { item in
                switch item.content {
                case .text(let string):
                    return string.localizedCaseInsensitiveContains(searchText)
                case .image:
                    return false // Images are not searchable
                }
            }
        }
        
        if let tag = selectedTag {
            result = result.filter { $0.tag.contains(tag) }
        }
        
        return result
    }
    
    private var allTags: [String] {
        // Collect unique tags from items visible after tab filter (before search & tag filter)
        let items: [ClipboardItem]
        switch selectedTab {
        case .all:
            items = clipboardManager.clipboardItems
        case .favorites:
            items = clipboardManager.favoriteItems
        case .custom(let group):
            items = clipboardManager.itemsInGroup(group)
        }
        
        let tags = Set(items.flatMap { $0.tag })
        return tags.sorted()
    }
    
    var body: some View {
        VStack {
            ClipboardSearchBar(searchText: $searchText, isSearchFocused: $isSearchFocused)
            
            ClipboardGroupTabs(clipboardManager: clipboardManager, selectedTab: $selectedTab)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button(action: { selectedTag = nil }) {
                        Text("All")
                            .font(.caption)
                            .fontWeight(selectedTag == nil ? .bold : .regular)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedTag == nil ? Color.accentColor : Color.secondary.opacity(0.2))
                            .foregroundColor(selectedTag == nil ? .white : .primary)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    ForEach(allTags, id: \.self) { tag in
                        Button(action: { selectedTag = tag }) {
                            Text(tag)
                                .modifier(TagStyleModifier(color: color(for: tag)))
                                .fontWeight(selectedTag == tag ? .bold : .regular)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            
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
            ClipboardItem(content: .text("Sample text 1"), tag: ["Work"]),
            ClipboardItem(content: .text("Sample text 2"), tag: ["Personal"]),
            ClipboardItem(content: .text("Sample text 3"), tag: ["Work"]),
            ClipboardItem(content: .text("Sample text 4"), tag: ["Ideas"]),
            ClipboardItem(content: .text("Sample text 5"), tag: [])
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

