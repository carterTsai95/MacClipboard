import SwiftUI

struct ClipboardListView: View {
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @Binding var selectedItemId: UUID?
    let onCopy: () -> Void
    
    var body: some View {
        List(selection: $selectedItemId) {
            if let latestItem = clipboardManager.clipboardItems.first {
                Section(header: Text("Current Clipboard")) {
                    ClipboardItemRow(item: latestItem, 
                                   clipboardManager: clipboardManager, 
                                   isLatest: true,
                                   isSelected: selectedItemId == latestItem.id,
                                   onCopy: onCopy)
                    .tag(latestItem.id)
                }
            }
            
            if clipboardManager.clipboardItems.count > 1 {
                Section(header: Text("History")) {
                    ForEach(Array(clipboardManager.clipboardItems.dropFirst())) { item in
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