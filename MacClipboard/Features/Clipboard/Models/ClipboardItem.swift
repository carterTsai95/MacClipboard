import Foundation

struct ClipboardItem: Identifiable {
    let id: UUID
    let content: ClipboardContent
    let timestamp: Date
    var isFavorite: Bool
    
    init(id: UUID = UUID(), content: ClipboardContent, timestamp: Date = Date(), isFavorite: Bool = false) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.isFavorite = isFavorite
    }
}

enum ClipboardContent {
    case text(String)
    case image(Data)
} 