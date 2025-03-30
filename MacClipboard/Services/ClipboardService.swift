import AppKit
import SwiftUI

class ClipboardService {
    static let shared = ClipboardService()
    
    private init() {}
    
    func getCurrentContent() -> ClipboardContent? {
        let pasteboard = NSPasteboard.general
        
        if let imageData = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png) {
            return .image(imageData)
        } else if let text = pasteboard.string(forType: .string) {
            return .text(text)
        }
        
        return nil
    }
    
    func copyToClipboard(_ content: ClipboardContent) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch content {
        case .text(let string):
            pasteboard.setString(string, forType: .string)
        case .image(let data):
            pasteboard.setData(data, forType: .tiff)
        }
    }
} 