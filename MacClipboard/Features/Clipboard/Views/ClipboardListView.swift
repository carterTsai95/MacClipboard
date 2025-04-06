import SwiftUI

struct ClipboardListView: View {
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @Binding var selectedItemId: UUID?
    @FocusState.Binding var isSearchFocused: Bool
    @Binding var searchText: String
    let onCopy: () -> Void
    
    init(selectedItemId: Binding<UUID?>, isSearchFocused: FocusState<Bool>.Binding, searchText: Binding<String>, onCopy: @escaping () -> Void) {
        self._selectedItemId = selectedItemId
        self._isSearchFocused = isSearchFocused
        self._searchText = searchText
        self.onCopy = onCopy
    }
    
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardManager.clipboardItems
        }
        return clipboardManager.clipboardItems.filter { item in
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
            
            List(selection: $selectedItemId) {
                if let latestItem = filteredItems.first {
                    Section(header: Text("Current Clipboard")) {
                        ClipboardItemRow(item: latestItem, 
                                       clipboardManager: clipboardManager, 
                                       isLatest: true,
                                       isSelected: selectedItemId == latestItem.id,
                                       onCopy: onCopy)
                        .tag(latestItem.id)
                    }
                }
                
                if filteredItems.count > 1 {
                    Section(header: Text("History")) {
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
        }
    }
} 