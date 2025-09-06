import Foundation

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let content: ClipboardContent
    let timestamp: Date
    var isFavorite: Bool
    var tag: [String]  // Changed from String to [String]

    init(id: UUID = UUID(), content: ClipboardContent, timestamp: Date = Date(), isFavorite: Bool = false, tag: [String] = []) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.isFavorite = isFavorite
        self.tag = tag
    }

    enum CodingKeys: String, CodingKey {
        case id, content, timestamp, isFavorite, tag
    }

    // Custom encode/decode to handle [String] tag (array) properly
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(ClipboardContent.self, forKey: .content)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        tag = try container.decodeIfPresent([String].self, forKey: .tag) ?? []  // decode array, default empty array
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encode(tag, forKey: .tag)  // encode array of strings
    }
}

enum ClipboardContent: Codable {
    case text(String)
    case image(Data)

    private enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "text":
            let value = try container.decode(String.self, forKey: .value)
            self = .text(value)
        case "image":
            let value = try container.decode(Data.self, forKey: .value)
            self = .image(value)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .text(let string):
            try container.encode("text", forKey: .type)
            try container.encode(string, forKey: .value)
        case .image(let data):
            try container.encode("image", forKey: .type)
            try container.encode(data, forKey: .value)
        }
    }
} 
