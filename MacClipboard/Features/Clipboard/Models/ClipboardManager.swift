import SwiftUI

class ClipboardManager: ObservableObject {
    @Published private(set) var clipboardItems: [ClipboardItem] = [] {
        didSet {
            // Save items whenever they change
            ClipboardItemStorage.shared.saveItems(clipboardItems)
        }
    }
    @Published private(set) var customGroups: [CustomGroup] = [] {
        didSet {
            // Save groups whenever they change
            CustomGroupStorage.shared.saveGroups(customGroups)
        }
    }
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
        
        // Load saved clipboard items and custom groups
        self.clipboardItems = ClipboardItemStorage.shared.loadItems()
        self.customGroups = CustomGroupStorage.shared.loadGroups()
        
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
    
    func toggleFavorite(_ item: ClipboardItem, completion: (() -> Void)? = nil) {
        if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
            updateQueue.async { [weak self] in
                self?.toggleFavoriteStatus(at: index, completion: completion)
            }
        } else {
            completion?()
        }
    }
    
    private func toggleFavoriteStatus(at index: Int, completion: (() -> Void)? = nil) {
        var newItems = clipboardItems
        var item = newItems[index]
        item.isFavorite.toggle()
        newItems[index] = item
        
        DispatchQueue.main.async { [weak self] in
            self?.clipboardItems = newItems
            completion?()
        }
    }
    
    var favoriteItems: [ClipboardItem] {
        clipboardItems.filter { $0.isFavorite }
    }
    
    func createCustomGroup(name: String, completion: ((CustomGroup) -> Void)? = nil) {
        let newGroup = CustomGroup(name: name)
        updateQueue.async { [weak self] in
            DispatchQueue.main.async {
                self?.customGroups.append(newGroup)
                completion?(newGroup)
            }
        }
    }
    
    func deleteCustomGroup(_ group: CustomGroup) {
        updateQueue.async { [weak self] in
            DispatchQueue.main.async {
                self?.customGroups.removeAll { $0.id == group.id }
            }
        }
    }
    
    func addItemToGroup(_ item: ClipboardItem, group: CustomGroup) {
        updateQueue.async { [weak self] in
            DispatchQueue.main.async {
                if let index = self?.customGroups.firstIndex(where: { $0.id == group.id }) {
                    var updatedGroup = group
                    updatedGroup.itemIds.insert(item.id)
                    self?.customGroups[index] = updatedGroup
                }
            }
        }
    }
    
    func removeItemFromGroup(_ item: ClipboardItem, group: CustomGroup) {
        updateQueue.async { [weak self] in
            DispatchQueue.main.async {
                if let index = self?.customGroups.firstIndex(where: { $0.id == group.id }) {
                    var updatedGroup = group
                    updatedGroup.itemIds.remove(item.id)
                    self?.customGroups[index] = updatedGroup
                }
            }
        }
    }
    
    func itemsInGroup(_ group: CustomGroup) -> [ClipboardItem] {
        clipboardItems.filter { group.itemIds.contains($0.id) }
    }
    
    func isItemInGroup(_ item: ClipboardItem, group: CustomGroup) -> Bool {
        return group.itemIds.contains(item.id)
    }
    
    deinit {
        monitoringTimer?.invalidate()
    }
} 