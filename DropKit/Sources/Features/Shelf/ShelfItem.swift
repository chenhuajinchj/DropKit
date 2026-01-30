import Foundation
import AppKit

enum FileType: String {
    case image
    case video
    case document
    case other

    var icon: String {
        switch self {
        case .image: return "photo"
        case .video: return "video"
        case .document: return "doc.fill"
        case .other: return "doc"
        }
    }
}

struct ShelfItem: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    var thumbnail: NSImage?
    var fileSize: Int64
    var dimensions: CGSize?
    var fileType: FileType

    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        self.thumbnail = nil
        self.fileSize = 0
        self.dimensions = nil
        self.fileType = .other

        // 获取文件信息
        loadFileInfo()
    }

    mutating func loadFileInfo() {
        // 获取文件大小
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int64 {
            fileSize = size
        }

        // 判断文件类型
        let ext = url.pathExtension.lowercased()
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "heic", "webp", "tiff", "bmp"]
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "webm"]
        let documentExtensions = ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "md"]

        if imageExtensions.contains(ext) {
            fileType = .image
            // 获取图片尺寸
            if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
               let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
               let width = properties[kCGImagePropertyPixelWidth as String] as? Int,
               let height = properties[kCGImagePropertyPixelHeight as String] as? Int {
                dimensions = CGSize(width: width, height: height)
            }
        } else if videoExtensions.contains(ext) {
            fileType = .video
        } else if documentExtensions.contains(ext) {
            fileType = .document
        } else {
            fileType = .other
        }
    }

    // 格式化文件大小
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    // 格式化尺寸
    var formattedDimensions: String? {
        guard let dims = dimensions else { return nil }
        return "\(Int(dims.width))x\(Int(dims.height))"
    }
}
