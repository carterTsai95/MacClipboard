import Foundation

struct ClipboardItem: Identifiable {
    let id: UUID
    let content: ClipboardContent
    let timestamp: Date
    
    init(id: UUID = UUID(), content: ClipboardContent, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
    }
}

enum ClipboardContent {
    case text(String)
    case image(Data)
} 