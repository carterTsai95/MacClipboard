import Foundation

enum Tab: Equatable, Hashable {
    case all
    case favorites
    case custom(CustomGroup)
    
    static func == (lhs: Tab, rhs: Tab) -> Bool {
        switch (lhs, rhs) {
        case (.all, .all), (.favorites, .favorites):
            return true
        case (.custom(let group1), .custom(let group2)):
            return group1.id == group2.id
        default:
            return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .all:
            hasher.combine(0)
        case .favorites:
            hasher.combine(1)
        case .custom(let group):
            hasher.combine(2)
            hasher.combine(group.id)
        }
    }
} 