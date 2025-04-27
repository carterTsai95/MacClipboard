import SwiftUI

struct RecentItemsView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    
    var body: some View {
        ForEach(clipboardManager.clipboardItems.dropFirst().prefix(5)) { item in
            Button(action: {
                clipboardManager.copyToClipboard(item)
            }) {
                switch item.content {
                case .text(let string):
                    Text(string)
                        .lineLimit(1)
                case .image:
                    Text("Image")
                        .lineLimit(1)
                }
            }
        }
    }
} 