import SwiftUI

struct LatestItemView: View {
    let item: ClipboardItem
    @ObservedObject var clipboardManager: ClipboardManager
    
    var body: some View {
        VStack {
            switch item.content {
            case .text(let string):
                Text(string)
                    .lineLimit(2)
                    .font(.system(size: 12))
            case .image(let data):
                if let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 40)
                }
            }
            
            Button("Copy Current") {
                clipboardManager.copyToClipboard(item)
            }
            .keyboardShortcut("C", modifiers: [.command])
        }
    }
} 