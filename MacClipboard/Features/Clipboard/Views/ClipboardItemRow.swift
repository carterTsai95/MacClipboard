import SwiftUI

struct ClipboardItemRow: View {
    let item: ClipboardItem
    @ObservedObject var clipboardManager: ClipboardManager
    let isLatest: Bool
    let isSelected: Bool
    let onCopy: () -> Void
    
    @State private var showingPreview = false
    @State private var isCopyHovered = false
    @State private var isDeleteHovered = false
    
    var body: some View {
        HStack {
            // Content area with selection highlight
            HStack {
                VStack(alignment: .leading) {
                    switch item.content {
                    case .text(let string):
                        Text(string)
                            .lineLimit(2)
                    case .image(let data):
                        if let nsImage = NSImage(data: data) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 40)
                                .onTapGesture {
                                    showingPreview.toggle()
                                }
                                .popover(isPresented: $showingPreview, arrowEdge: .leading) {
                                    ImagePreviewView(imageData: data)
                                        .frame(width: 600, height: 400)
                                }
                        }
                    }
                    
                    Text(item.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(6)
            
            // Action buttons outside the selection highlight
            HStack(spacing: 12) {
                Button(action: {
                    clipboardManager.copyToClipboard(item)
                    onCopy()
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(isCopyHovered ? .white : .blue)
                        .padding(4)
                        .background(isCopyHovered ? Color.blue : Color.clear)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isCopyHovered = hovering
                }
                
                Button(action: {
                    clipboardManager.deleteItem(item)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(isDeleteHovered ? .white : .red)
                        .padding(4)
                        .background(isDeleteHovered ? Color.red : Color.clear)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .disabled(isLatest)
                .opacity(isLatest ? 0.5 : 1.0)
                .onHover { hovering in
                    isDeleteHovered = hovering && !isLatest
                }
            }
            .padding(.leading, 8)
        }
    }
} 