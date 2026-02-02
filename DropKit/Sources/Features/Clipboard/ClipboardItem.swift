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
        case .text:
            return String(content.prefix(100)) + (content.count > 100 ? "..." : "")
        case .html:
            let plainText = Self.stripHTMLTags(from: content)
            return String(plainText.prefix(100)) + (plainText.count > 100 ? "..." : "")
        case .file:
            return URL(fileURLWithPath: content).lastPathComponent
        case .image:
            if content.isEmpty {
                return "图片"
            }
            let url = URL(fileURLWithPath: content)
            return url.lastPathComponent
        }
    }

    static func stripHTMLTags(from html: String) -> String {
        // 使用 NSAttributedString 解析 HTML 提取纯文本
        guard let data = html.data(using: .utf8),
              let attributedString = try? NSAttributedString(
                  data: data,
                  options: [.documentType: NSAttributedString.DocumentType.html,
                            .characterEncoding: String.Encoding.utf8.rawValue],
                  documentAttributes: nil
              ) else {
            // 降级方案：正则去除标签
            return html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        }
        return attributedString.string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var icon: String {
        switch type {
        case .text: return "doc.text"
        case .html: return "doc.richtext"
        case .image: return "photo"
        case .file: return "doc.fill"
        }
    }

    var isImageFile: Bool {
        guard type == .file || type == .image else { return false }
        if type == .image { return true }
        let ext = URL(fileURLWithPath: content).pathExtension.lowercased()
        return ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "heic", "webp"].contains(ext)
    }

    // 共享的日期格式化器，避免重复创建
    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .short
        return formatter
    }()

    var relativeTime: String {
        Self.relativeDateFormatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
