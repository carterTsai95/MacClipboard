import Foundation

struct CustomGroup: Identifiable, Codable {
    let id: UUID
    var name: String
    var itemIds: Set<UUID>
    
    init(id: UUID = UUID(), name: String, itemIds: Set<UUID> = []) {
        self.id = id
        self.name = name
        self.itemIds = itemIds
    }
} 