import AppKit
@testable import MacClipboard

class MockPasteboard: PasteboardProtocol {
    private var contents: [NSPasteboard.PasteboardType: Any] = [:]
    private(set) var changeCount: Int = 0
    
    func clearContents() {
        contents.removeAll()
        changeCount += 1
    }
    
    func setString(_ string: String, forType type: NSPasteboard.PasteboardType) {
        contents[type] = string
        changeCount += 1
    }
    
    func setData(_ data: Data, forType type: NSPasteboard.PasteboardType) {
        contents[type] = data
        changeCount += 1
    }
    
    func string(forType type: NSPasteboard.PasteboardType) -> String? {
        return contents[type] as? String
    }
    
    func data(forType type: NSPasteboard.PasteboardType) -> Data? {
        return contents[type] as? Data
    }
} 