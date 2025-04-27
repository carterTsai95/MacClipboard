import SwiftUI

struct CustomGroupsView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    
    var body: some View {
        Menu("Custom Groups") {
            ForEach(Array(clipboardManager.customGroups.enumerated()), id: \.element.id) { index, group in
                Menu(group.name) { groupContent(for: group) }
            }
        }
    }
    
    @ViewBuilder
    private func groupContent(for group: CustomGroup) -> some View {
        let items = clipboardManager.itemsInGroup(group)
        if items.isEmpty {
            Text("No items")
                .foregroundColor(.secondary)
        } else {
            ForEach(items.prefix(5)) { item in
                Button(action: {
                    clipboardManager.copyToClipboard(item)
                }) {
                    switch item.content {
                    case .text(let string):
                        Text(string).lineLimit(1)
                    case .image:
                        Text("Image").lineLimit(1)
                    }
                }
            }
        }
    }
} 