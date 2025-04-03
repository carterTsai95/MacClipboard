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
    
    func checkForChanges(completion: (() -> Void)? = nil) {
        guard pasteboard.changeCount != changeCount else {
            completion?()
            return
        }
        
        changeCount = pasteboard.changeCount
        
        if let content = clipboardService.getCurrentContent() {
            addItem(content: content, completion: completion)
        } else {
            completion?()
        }
    }
    
    private func addItem(content: ClipboardContent, completion: (() -> Void)? = nil) {
        // Don't add if it's the same as the most recent item
        if let lastItem = clipboardItems.first {
            switch (lastItem.content, content) {
            case (.text(let oldText), .text(let newText)) where oldText == newText:
                completion?()
                return
            case (.image(let oldData), .image(let newData)) where oldData == newData:
                completion?()
                return
            default:
                break
            }
        }
        
        let newItem = ClipboardItem(content: content)
        updateQueue.async { [weak self] in
            self?.updateItems(with: newItem, completion: completion)
        }
    }
    
    private func updateItems(with newItem: ClipboardItem, completion: (() -> Void)? = nil) {
        var newItems = clipboardItems
        newItems.insert(newItem, at: 0)
        
        // Remove oldest items if we exceed maxItems
        if newItems.count > maxItems {
            newItems.removeLast(newItems.count - maxItems)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.clipboardItems = newItems
            completion?()
        }
    }
    
    func copyToClipboard(_ item: ClipboardItem, completion: (() -> Void)? = nil) {
        clipboardService.copyToClipboard(item.content)
        
        // Move the item to the top of the list
        if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
            updateQueue.async { [weak self] in
                self?.moveItemToTop(at: index, completion: completion)
            }
        } else {
            completion?()
        }
    }
    
    private func moveItemToTop(at index: Int, completion: (() -> Void)? = nil) {
        var newItems = clipboardItems
        let item = newItems.remove(at: index)
        newItems.insert(item, at: 0)
        
        DispatchQueue.main.async { [weak self] in
            self?.clipboardItems = newItems
            completion?()
        }
    }
    
    func deleteItem(_ item: ClipboardItem, completion: (() -> Void)? = nil) {
        if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
            updateQueue.async { [weak self] in
                self?.removeItem(at: index, completion: completion)
            }
        } else {
            completion?()
        }
    }
    
    private func removeItem(at index: Int, completion: (() -> Void)? = nil) {
        var newItems = clipboardItems
        newItems.remove(at: index)
        
        DispatchQueue.main.async { [weak self] in
            self?.clipboardItems = newItems
            completion?()
        }
    }
    
    func clearHistory(completion: (() -> Void)? = nil) {
        // Keep only the most recent item
        if clipboardItems.count > 1 {
            updateQueue.async { [weak self] in
                self?.removeAllExceptFirst(completion: completion)
            }
        } else {
            completion?()
        }
    }
    
    private func removeAllExceptFirst(completion: (() -> Void)? = nil) {
        var newItems = clipboardItems
        newItems.removeSubrange(1..<newItems.count)
        
        DispatchQueue.main.async { [weak self] in
            self?.clipboardItems = newItems
            completion?()
        }
    }
    
    deinit {
        monitoringTimer?.invalidate()
    }
} 