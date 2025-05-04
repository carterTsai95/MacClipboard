import Foundation

class ClipboardItemStorage {
    static let shared = ClipboardItemStorage()
    
    private let fileManager = FileManager.default
    private let storageURL: URL
    
    private init() {
        // Get the application support directory
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupportURL.appendingPathComponent("MacClipboard")
        
        // Create the directory if it doesn't exist
        try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        
        // Set the storage URL for clipboard items
        storageURL = appDirectory.appendingPathComponent("clipboard_items.json")
    }
    
    func saveItems(_ items: [ClipboardItem]) {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: storageURL)
        } catch {
            print("Failed to save clipboard items: \(error)")
        }
    }
    
    func loadItems() -> [ClipboardItem] {
        guard fileManager.fileExists(atPath: storageURL.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: storageURL)
            return try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            print("Failed to load clipboard items: \(error)")
            return []
        }
    }
} 