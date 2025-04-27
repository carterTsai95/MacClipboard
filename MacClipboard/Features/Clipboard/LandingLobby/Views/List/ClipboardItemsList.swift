import SwiftUI

struct ClipboardItemsList: View {
    @ObservedObject var clipboardManager: ClipboardManager
    @Binding var selectedItemId: UUID?
    let onCopy: () -> Void
    let filteredItems: [ClipboardItem]
    let selectedTab: Tab
    
    var body: some View {
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
}

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var clipboardManager = ClipboardManager()
        @State private var selectedItemId: UUID?
        @State private var selectedTab: Tab = .all
        
        // Create sample items directly for preview
        private let sampleItems: [ClipboardItem] = [
            ClipboardItem(content: .text("Sample text 1")),
            ClipboardItem(content: .text("Sample text 2")),
            ClipboardItem(content: .text("Sample text 3"))
        ]
        
        var body: some View {
            VStack {
                Picker("Tab", selection: $selectedTab) {
                    Text("All").tag(Tab.all)
                    Text("Favorites").tag(Tab.favorites)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                ClipboardItemsList(
                    clipboardManager: clipboardManager,
                    selectedItemId: $selectedItemId,
                    onCopy: {},
                    filteredItems: sampleItems,
                    selectedTab: selectedTab
                )
                .frame(height: 400)
                
                Text("Selected Item ID: \(selectedItemId?.uuidString ?? "None")")
                    .padding()
            }
            .frame(width: 500)
            .padding()
        }
    }
    
    return PreviewWrapper()
} 