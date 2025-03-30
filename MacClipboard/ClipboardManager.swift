import Foundation
import AppKit

class ClipboardManager: ObservableObject {
    @Published var clipboardItems: [ClipboardItem] = []
    private let maxItems = 50
    private var deletedItemsBlacklist: Set<String> = []
    private let blacklistTimeout: TimeInterval = 5.0 // 5 seconds
    
    init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        NSPasteboard.general.declareTypes([.string, .tiff, .png], owner: nil)
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    private func checkClipboard() {
        // Check for text content
        if let string = NSPasteboard.general.string(forType: .string) {
            // Skip if the content is in the blacklist
            if deletedItemsBlacklist.contains(string) {
                return
            }
            
            // Check if the content is already in our history
            if !clipboardItems.contains(where: { 
                if case .text(let content) = $0.content {
                    return content == string
                }
                return false
            }) {
                let newItem = ClipboardItem(content: .text(string))
                clipboardItems.insert(newItem, at: 0)
                trimHistory()
            }
            return
        }
        
        // Check for image content
        if let imageData = NSPasteboard.general.data(forType: .tiff) ?? NSPasteboard.general.data(forType: .png) {
            // Check if the image is already in our history
            if !clipboardItems.contains(where: {
                if case .image(let data) = $0.content {
                    return data == imageData
                }
                return false
            }) {
                let newItem = ClipboardItem(content: .image(imageData))
                clipboardItems.insert(newItem, at: 0)
                trimHistory()
            }
        }
    }
    
    private func trimHistory() {
        if clipboardItems.count > maxItems {
            clipboardItems.removeLast()
        }
    }
    
    func copyToClipboard(_ item: ClipboardItem) {
        NSPasteboard.general.clearContents()
        switch item.content {
        case .text(let string):
            NSPasteboard.general.setString(string, forType: .string)
        case .image(let data):
            NSPasteboard.general.setData(data, forType: .tiff)
        }
    }
    
    func deleteItem(_ item: ClipboardItem) {
        clipboardItems.removeAll { $0.id == item.id }
        
        // Add to blacklist if it's text content
        if case .text(let string) = item.content {
            deletedItemsBlacklist.insert(string)
            DispatchQueue.main.asyncAfter(deadline: .now() + blacklistTimeout) { [weak self] in
                self?.deletedItemsBlacklist.remove(string)
            }
        }
    }
    
    func clearHistory() {
        // Keep the current clipboard item if it exists
        if clipboardItems.count > 1 {
            let currentItem = clipboardItems[0]
            clipboardItems = [currentItem]
        }
    }
} 