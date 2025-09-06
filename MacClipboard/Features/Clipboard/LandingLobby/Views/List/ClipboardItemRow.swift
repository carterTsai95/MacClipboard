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
    @State private var isFavoriteHovered = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack {
                // Content area with selection highlight
                HStack {
                    VStack(alignment: .leading) {
                        switch item.content {
                        case .text(let string):
                            Text(string)
                                .lineLimit(2)
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
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
                        
                        if !item.tag.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(item.tag, id: \.self) { tag in
                                    Text(tag)
                                        .modifier(TagStyleModifier(color: color(for: tag)))
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
                .background(isSelected ? Color.accentColor.opacity(colorScheme == .dark ? 0.3 : 0.2) : Color.clear)
                .cornerRadius(6)
                .contextMenu {
                    if !clipboardManager.customGroups.isEmpty {
                        Menu("Add to Group") {
                            ForEach(clipboardManager.customGroups) { group in
                                let isInGroup = clipboardManager.isItemInGroup(item, group: group)
                                Button(action: {
                                    if isInGroup {
                                        clipboardManager.removeItemFromGroup(item, group: group)
                                    } else {
                                        clipboardManager.addItemToGroup(item, group: group)
                                    }
                                }) {
                                    Label(group.name, systemImage: "folder.fill")
                                    if isInGroup {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        
                        Divider()
                    }
                    
                    Button(action: {
                        clipboardManager.toggleFavorite(item)
                    }) {
                        Label(item.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                              systemImage: item.isFavorite ? "star.slash" : "star")
                    }
                }
                
                // Action buttons outside the selection highlight
                HStack(spacing: 12) {
                    Button(action: {
                        clipboardManager.toggleFavorite(item)
                    }) {
                        Image(systemName: item.isFavorite ? "star.fill" : "star")
                            .foregroundColor(isFavoriteHovered ? .yellow : (item.isFavorite ? .yellow : .secondary))
                            .padding(4)
                            .background(isFavoriteHovered ? Color.yellow.opacity(0.2) : Color.clear)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        isFavoriteHovered = hovering
                    }
                    
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
    
    private func color(for tag: String) -> Color {
        // Predefined colors to cycle through
        let colors: [Color] = [
            .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink, .brown, .gray
        ]
        // Hash tag string and map to colors array index
        let hash = tag.unicodeScalars.reduce(0, { $0 + UInt32($1.value) })
        let colorIndex = Int(hash) % colors.count
        return colors[colorIndex].opacity(0.3)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var clipboardManager = ClipboardManager()
        @State private var isSelected = false
        
        // Create sample items directly for preview
        private let sampleItem1 = ClipboardItem(content: .text("This is a sample text item for preview"), tag: ["Work", "Important"])
        private let sampleItem2 = ClipboardItem(content: .text("This is another sample text item"), tag: ["Personal", "Urgent"])
        
        var body: some View {
            VStack(spacing: 20) {
                ClipboardItemRow(
                    item: sampleItem1,
                    clipboardManager: clipboardManager,
                    isLatest: true,
                    isSelected: isSelected,
                    onCopy: {}
                )
                .frame(height: 80)
                
                ClipboardItemRow(
                    item: sampleItem2,
                    clipboardManager: clipboardManager,
                    isLatest: false,
                    isSelected: !isSelected,
                    onCopy: {}
                )
                .frame(height: 80)
                
                Toggle("Toggle Selection", isOn: $isSelected)
                    .padding()
                
                Button("Toggle Favorite") {
                    // Use the public toggleFavorite method instead of addItem
                    clipboardManager.toggleFavorite(sampleItem1)
                }
                .padding()
            }
            .frame(width: 500)
            .padding()
        }
    }
    
    return PreviewWrapper()
}

struct TagStyleModifier: ViewModifier {
    var color: Color
    func body(content: Content) -> some View {
        content
            .font(.caption2)
            .padding(.vertical, 2)
            .padding(.horizontal, 8)
            .fontWeight(.regular)
            .background(color)
            .clipShape(Capsule())
    }
}
