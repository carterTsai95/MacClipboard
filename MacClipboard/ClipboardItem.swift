import Foundation

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let content: String
    let timestamp: Date
    
    init(content: String) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
    }
} 