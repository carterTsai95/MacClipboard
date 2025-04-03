import AppKit
import SwiftUI

final class SystemPasteboard: PasteboardProtocol {
    private let pasteboard: NSPasteboard
    
    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }
    
    func clearContents() {
        pasteboard.clearContents()
    }
    
    func setString(_ string: String, forType type: NSPasteboard.PasteboardType) {
        pasteboard.setString(string, forType: type)
    }
    
    func setData(_ data: Data, forType type: NSPasteboard.PasteboardType) {
        pasteboard.setData(data, forType: type)
    }
    
    func string(forType type: NSPasteboard.PasteboardType) -> String? {
        pasteboard.string(forType: type)
    }
    
    func data(forType type: NSPasteboard.PasteboardType) -> Data? {
        pasteboard.data(forType: type)
    }
    
    var changeCount: Int {
        pasteboard.changeCount
    }
}

class ClipboardService {
    static let shared = ClipboardService()
    
    private let pasteboard: PasteboardProtocol
    
    init(pasteboard: PasteboardProtocol = SystemPasteboard()) {
        self.pasteboard = pasteboard
    }
    
    func getCurrentContent() -> ClipboardContent? {
        if let imageData = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png) {
            return .image(imageData)
        } else if let text = pasteboard.string(forType: .string) {
            return .text(text)
        }
        
        return nil
    }
    
    func copyToClipboard(_ content: ClipboardContent) {
        pasteboard.clearContents()
        
        switch content {
        case .text(let string):
            pasteboard.setString(string, forType: .string)
        case .image(let data):
            pasteboard.setData(data, forType: .tiff)
        }
    }
} 