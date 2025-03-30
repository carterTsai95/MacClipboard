import Foundation
import AppKit

enum ClipboardContent: Codable {
    case text(String)
    case image(Data)
    
    var description: String {
        switch self {
        case .text(let string):
            return string
        case .image:
            return "Image"
        }
    }
}

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let content: ClipboardContent
    let timestamp: Date
    
    init(content: ClipboardContent) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
    }
} 