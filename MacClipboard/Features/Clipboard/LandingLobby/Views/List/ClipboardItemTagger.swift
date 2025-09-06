import Foundation

struct ClipboardItemTagger {
    static func tags(for content: ClipboardContent) -> [String] {
        var detectedTags = Set<String>()

        switch content {
        case .text(let string):
            // Use NSDataDetector for specific types
            if let detector = try? NSDataDetector(types:
                NSTextCheckingResult.CheckingType.link.rawValue |
                NSTextCheckingResult.CheckingType.phoneNumber.rawValue |
                NSTextCheckingResult.CheckingType.date.rawValue |
                NSTextCheckingResult.CheckingType.address.rawValue)
            {
                let matches = detector.matches(in: string, options: [], range: NSRange(location: 0, length: (string as NSString).length))
                for match in matches {
                    switch match.resultType {
                    case .link: detectedTags.insert("Link")
                    case .phoneNumber: detectedTags.insert("Number")
                    case .date: detectedTags.insert("Date/Time")
                    case .address: detectedTags.insert("Address")
                    default: break
                    }
                }
            }

            // File path detection (improved with regex)
            // Unix absolute path: starts with /
            // Unix home-relative path: starts with ~/
            // Unix dot-relative path: starts with ./
            // Windows path: Drive letter followed by :\ or :/
            let filePathPatterns = [
                #"(?m)^(~\/|\.\/|\/)[^\0\s]*"#,              // Unix-style paths
                #"(?m)^[a-zA-Z]:[\\/][^\0\s]*"#              // Windows-style paths
            ]
            for pattern in filePathPatterns {
                if let _ = string.range(of: pattern, options: .regularExpression) {
                    detectedTags.insert("File")
                    break
                }
            }

            // Code detection (look for common patterns)
            let codeKeywords = ["func ", "class ", "struct ", "enum ", "import ", "public ", "private ", "{", "}"]
            if codeKeywords.contains(where: { string.contains($0) }) {
                detectedTags.insert("Code")
            }

            // Rich text detection (basic)
            if string.contains("<html") || string.contains("<body") || string.contains("<div") || string.contains("style=") {
                detectedTags.insert("Rich Text")
            }
            if string.contains("{\"ops\":") { // Quill.js or similar
                detectedTags.insert("Rich Text")
            }

            // Numeric-only detection (could be an order ID, amount, etc.)
            let numericString = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if numericString.range(of: "^[0-9,.]+$", options: .regularExpression) != nil {
                detectedTags.insert("Number")
            }

            // If no tags detected, fallback to plain text
            if detectedTags.isEmpty {
                detectedTags.insert("Text")
            }

        case .image(_):
            detectedTags.insert("Image")
        }

        return Array(detectedTags)
    }
}
