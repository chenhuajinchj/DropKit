import Foundation
import AppKit

enum ClipboardItemType: String, Codable {
    case text
    case html
    case image
    case file
    case url
}

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let type: ClipboardItemType
    let content: String
    let timestamp: Date

    init(type: ClipboardItemType, content: String) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.timestamp = Date()
    }

    var displayText: String {
        switch type {
        case .text, .html:
            return content.prefix(100) + (content.count > 100 ? "..." : "")
        case .url:
            return content
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
        case .url: return "link"
        }
    }
}
