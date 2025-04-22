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
        let items = selectedTab == .all ? clipboardManager.clipboardItems : clipboardManager.favoriteItems
        
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
            Picker("View", selection: $selectedTab) {
                Label("All", systemImage: "list.bullet")
                    .tag(Tab.all)
                Label("Favorites", systemImage: "star.fill")
                    .tag(Tab.favorites)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: selectedTab) { newTab in
                updateSelectionForTab(newTab)
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
                    Section(header: Text(selectedTab == .all ? "History" : "Favorite Items").foregroundColor(.secondary)) {
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
    
    private func updateSelectionForTab(_ tab: Tab) {
        // If we're switching to favorites tab and no favorite item is selected
        if tab == .favorites {
            let favoriteItems = clipboardManager.favoriteItems
            
            // If no favorite items, do nothing
            guard !favoriteItems.isEmpty else { return }
            
            // If current selection is not in favorites, select the first favorite
            if let currentId = selectedItemId, !favoriteItems.contains(where: { $0.id == currentId }) {
                selectedItemId = favoriteItems.first?.id
            } else if selectedItemId == nil {
                // If nothing is selected, select the first favorite
                selectedItemId = favoriteItems.first?.id
            }
        }
    }
} 