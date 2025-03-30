import SwiftUI

class ClipboardManager: ObservableObject {
    @Published private(set) var clipboardItems: [ClipboardItem] = []
    private var changeCount: Int
    private let maxItems: Int
    
    init(maxItems: Int = 50) {
        self.maxItems = maxItems
        self.changeCount = NSPasteboard.general.changeCount
        startMonitoring()
    }
    
    private func startMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }
    
    private func checkForChanges() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != changeCount else { return }
        
        changeCount = pasteboard.changeCount
        
        if let content = ClipboardService.shared.getCurrentContent() {
            addItem(content: content)
        }
    }
    
    private func addItem(content: ClipboardContent) {
        DispatchQueue.main.async {
            // Don't add if it's the same as the most recent item
            if let lastItem = self.clipboardItems.first {
                switch (lastItem.content, content) {
                case (.text(let oldText), .text(let newText)) where oldText == newText:
                    return
                case (.image(let oldData), .image(let newData)) where oldData == newData:
                    return
                default:
                    break
                }
            }
            
            let newItem = ClipboardItem(content: content)
            self.clipboardItems.insert(newItem, at: 0)
            
            // Remove oldest items if we exceed maxItems
            if self.clipboardItems.count > self.maxItems {
                self.clipboardItems.removeLast(self.clipboardItems.count - self.maxItems)
            }
        }
    }
    
    func copyToClipboard(_ item: ClipboardItem) {
        ClipboardService.shared.copyToClipboard(item.content)
        
        // Move the item to the top of the list
        if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
            let item = clipboardItems.remove(at: index)
            clipboardItems.insert(item, at: 0)
        }
    }
    
    func deleteItem(_ item: ClipboardItem) {
        if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
            clipboardItems.remove(at: index)
        }
    }
    
    func clearHistory() {
        // Keep only the most recent item
        if clipboardItems.count > 1 {
            clipboardItems.removeSubrange(1..<clipboardItems.count)
        }
    }
} 