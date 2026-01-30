import Foundation
import AppKit

enum ClipboardItemType: String, Codable {
    case text
    case html
    case image
    case file
}

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let type: ClipboardItemType
    let content: String
    let timestamp: Date
    var isFavorite: Bool

    init(type: ClipboardItemType, content: String) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.timestamp = Date()
        self.isFavorite = false
    }

    var displayText: String {
        switch type {
        case .text, .html:
            return String(content.prefix(100)) + (content.count > 100 ? "..." : "")
        case .file:
            return URL(fileURLWithPath: content).lastPathComponent
        case .image:
            return "图片"
        }
    }

    var icon: String {
        switch type {
        case .text: return "doc.text"
        case .html: return "doc.richtext"
        case .image: return "photo"
        case .file: return "doc.fill"
        }
    }

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
