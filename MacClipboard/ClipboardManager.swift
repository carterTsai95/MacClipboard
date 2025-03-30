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
        NSPasteboard.general.declareTypes([.string], owner: nil)
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    private func checkClipboard() {
        guard let string = NSPasteboard.general.string(forType: .string) else { return }
        
        // Skip if the content is in the blacklist
        if deletedItemsBlacklist.contains(string) {
            return
        }
        
        // Check if the content is already in our history
        if !clipboardItems.contains(where: { $0.content == string }) {
            let newItem = ClipboardItem(content: string)
            clipboardItems.insert(newItem, at: 0)
            
            // Keep only the most recent items
            if clipboardItems.count > maxItems {
                clipboardItems.removeLast()
            }
        }
    }
    
    func copyToClipboard(_ item: ClipboardItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.content, forType: .string)
    }
    
    func deleteItem(_ item: ClipboardItem) {
        clipboardItems.removeAll { $0.id == item.id }
        
        // Add to blacklist and remove after timeout
        deletedItemsBlacklist.insert(item.content)
        DispatchQueue.main.asyncAfter(deadline: .now() + blacklistTimeout) { [weak self] in
            self?.deletedItemsBlacklist.remove(item.content)
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