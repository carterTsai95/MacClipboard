import SwiftUI

class ClipboardManager: ObservableObject {
    @Published private(set) var clipboardItems: [ClipboardItem] = []
    private var changeCount: Int
    private let maxItems: Int
    private let pasteboard: PasteboardProtocol
    private let clipboardService: ClipboardService
    private var monitoringTimer: Timer?
    private let monitoringInterval: TimeInterval
    private let updateQueue = DispatchQueue(label: "com.macclipboard.update", qos: .userInitiated)
    
    init(maxItems: Int = 50, 
         pasteboard: PasteboardProtocol = SystemPasteboard(),
         monitoringInterval: TimeInterval = 0.5) {
        self.maxItems = maxItems
        self.pasteboard = pasteboard
        self.changeCount = pasteboard.changeCount
        self.clipboardService = ClipboardService(pasteboard: pasteboard)
        self.monitoringInterval = monitoringInterval
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }
    
    func forceCheckForChanges() {
        checkForChanges()
    }
    
    private func checkForChanges() {
        guard pasteboard.changeCount != changeCount else { return }
        
        changeCount = pasteboard.changeCount
        
        if let content = clipboardService.getCurrentContent() {
            addItem(content: content)
        }
    }
    
    private func addItem(content: ClipboardContent) {
        // Don't add if it's the same as the most recent item
        if let lastItem = clipboardItems.first {
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
        updateQueue.async { [weak self] in
            self?.updateItems(with: newItem)
        }
    }
    
    private func updateItems(with newItem: ClipboardItem) {
        var newItems = clipboardItems
        newItems.insert(newItem, at: 0)
        
        // Remove oldest items if we exceed maxItems
        if newItems.count > maxItems {
            newItems.removeLast(newItems.count - maxItems)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.clipboardItems = newItems
        }
    }
    
    func copyToClipboard(_ item: ClipboardItem) {
        clipboardService.copyToClipboard(item.content)
        
        // Move the item to the top of the list
        if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
            updateQueue.async { [weak self] in
                self?.moveItemToTop(at: index)
            }
        }
    }
    
    private func moveItemToTop(at index: Int) {
        var newItems = clipboardItems
        let item = newItems.remove(at: index)
        newItems.insert(item, at: 0)
        
        DispatchQueue.main.async { [weak self] in
            self?.clipboardItems = newItems
        }
    }
    
    func deleteItem(_ item: ClipboardItem) {
        if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
            updateQueue.async { [weak self] in
                self?.removeItem(at: index)
            }
        }
    }
    
    private func removeItem(at index: Int) {
        var newItems = clipboardItems
        newItems.remove(at: index)
        
        DispatchQueue.main.async { [weak self] in
            self?.clipboardItems = newItems
        }
    }
    
    func clearHistory() {
        // Keep only the most recent item
        if clipboardItems.count > 1 {
            updateQueue.async { [weak self] in
                self?.removeAllExceptFirst()
            }
        }
    }
    
    private func removeAllExceptFirst() {
        var newItems = clipboardItems
        newItems.removeSubrange(1..<newItems.count)
        
        DispatchQueue.main.async { [weak self] in
            self?.clipboardItems = newItems
        }
    }
    
    deinit {
        monitoringTimer?.invalidate()
    }
} 