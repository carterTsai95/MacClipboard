import SwiftUI

struct ClipboardListView: View {
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @Binding var selectedItemId: UUID?
    @FocusState.Binding var isSearchFocused: Bool
    @Binding var searchText: String
    @Binding var selectedTab: Tab
    let onCopy: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingNewGroupSheet = false
    @State private var newGroupName = ""
    
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
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search clipboard items...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isSearchFocused)
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Tab selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    // Default tabs
                    HStack {
                        Button(action: { selectedTab = .all }) {
                            Label("All", systemImage: "list.bullet")
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(selectedTab == .all ? Color.accentColor : Color.clear)
                                .foregroundColor(selectedTab == .all ? .white : .primary)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { selectedTab = .favorites }) {
                            Label("Favorites", systemImage: "star.fill")
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(selectedTab == .favorites ? Color.accentColor : Color.clear)
                                .foregroundColor(selectedTab == .favorites ? .white : .primary)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(6)
                    
                    // Custom groups
                    if !clipboardManager.customGroups.isEmpty {
                        Divider()
                            .padding(.horizontal, 8)
                            .frame(height: 15)
                        
                        HStack {
                            ForEach(clipboardManager.customGroups) { group in
                                Button(action: { selectedTab = .custom(group) }) {
                                    Label(group.name, systemImage: "folder.fill")
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 5)
                                        .background(
                                            Group {
                                                if case .custom(let selectedGroup) = selectedTab,
                                                   selectedGroup.id == group.id {
                                                    Color.accentColor
                                                } else {
                                                    Color.clear
                                                }
                                            }
                                        )
                                        .foregroundColor(
                                            (selectedTab == .custom(group)) ? .white : .primary
                                        )
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(6)
                    }
                    
                    Button(action: {
                        showingNewGroupSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                            .padding(.leading, 8)
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showingNewGroupSheet) {
                        VStack(spacing: 20) {
                            Text("Create New Group")
                                .font(.headline)
                            
                            TextField("Group Name", text: $newGroupName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                            
                            HStack {
                                Button("Cancel") {
                                    showingNewGroupSheet = false
                                    newGroupName = ""
                                }
                                
                                Button("Create") {
                                    if !newGroupName.isEmpty {
                                        clipboardManager.createCustomGroup(name: newGroupName) { group in
                                            selectedTab = .custom(group)
                                            showingNewGroupSheet = false
                                            newGroupName = ""
                                        }
                                    }
                                }
                                .disabled(newGroupName.isEmpty)
                            }
                        }
                        .padding()
                        .frame(width: 300)
                    }
                }
                .padding(.horizontal)
            }
            
            List(selection: $selectedItemId) {
                if let latestItem = filteredItems.first {
                    Section(header: Text("Current Clipboard").foregroundColor(.secondary)) {
                        ClipboardItemRow(item: latestItem, 
                                       clipboardManager: clipboardManager, 
                                       isLatest: true,
                                       isSelected: selectedItemId == latestItem.id,
                                       onCopy: onCopy)
                        .tag(latestItem.id)
                    }
                }
                
                if filteredItems.count > 1 {
                    Section(header: Text(sectionTitle).foregroundColor(.secondary)) {
                        ForEach(Array(filteredItems.dropFirst())) { item in
                            ClipboardItemRow(item: item, 
                                           clipboardManager: clipboardManager, 
                                           isLatest: false,
                                           isSelected: selectedItemId == item.id,
                                           onCopy: onCopy)
                            .tag(item.id)
                        }
                    }
                }
            }
            .listStyle(InsetListStyle())
            .background(colorScheme == .dark ? Color.black : Color.white)
        }
        .onAppear {
            updateSelectionForTab(selectedTab)
        }
    }
    
    private var sectionTitle: String {
        switch selectedTab {
        case .all:
            return "History"
        case .favorites:
            return "Favorite Items"
        case .custom(let group):
            return group.name
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
