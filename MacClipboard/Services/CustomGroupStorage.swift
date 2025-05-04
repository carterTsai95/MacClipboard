import Foundation

class CustomGroupStorage {
    static let shared = CustomGroupStorage()
    
    private let fileManager = FileManager.default
    private let storageURL: URL
    
    private init() {
        // Get the application support directory
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupportURL.appendingPathComponent("MacClipboard")
        
        // Create the directory if it doesn't exist
        try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        
        // Set the storage URL for custom groups
        storageURL = appDirectory.appendingPathComponent("custom_groups.json")
    }
    
    func saveGroups(_ groups: [CustomGroup]) {
        do {
            let data = try JSONEncoder().encode(groups)
            try data.write(to: storageURL)
        } catch {
            print("Failed to save custom groups: \(error)")
        }
    }
    
    func loadGroups() -> [CustomGroup] {
        guard fileManager.fileExists(atPath: storageURL.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: storageURL)
            return try JSONDecoder().decode([CustomGroup].self, from: data)
        } catch {
            print("Failed to load custom groups: \(error)")
            return []
        }
    }
} 