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
    var cachedFileIdentifier: String?  // 缓存文件标识符，避免重复 I/O

    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        self.thumbnail = nil
        self.fileSize = 0
        self.dimensions = nil
        // 快速判断文件类型（仅基于扩展名，不读取文件）
        self.fileType = Self.determineFileType(from: url)
        // 缓存文件标识符（用于查重和移除缓存）
        if let fileID = try? url.resourceValues(forKeys: [.fileResourceIdentifierKey]).fileResourceIdentifier {
            self.cachedFileIdentifier = "\(fileID)"
        } else {
            self.cachedFileIdentifier = nil
        }
    }

    /// 仅基于扩展名判断文件类型（同步，快速）
    private static func determineFileType(from url: URL) -> FileType {
        let ext = url.pathExtension.lowercased()
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "heic", "webp", "tiff", "bmp"]
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "webm"]
        let documentExtensions = ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "md"]

        if imageExtensions.contains(ext) {
            return .image
        } else if videoExtensions.contains(ext) {
            return .video
        } else if documentExtensions.contains(ext) {
            return .document
        } else {
            return .other
        }
    }

    /// 异步加载文件详细信息（文件大小、图片尺寸），在后台线程执行 I/O
    static func loadFileInfo(for url: URL, fileType: FileType) async -> (fileSize: Int64, dimensions: CGSize?) {
        await Task.detached(priority: .utility) {
            var fileSize: Int64 = 0
            var dimensions: CGSize? = nil

            // 获取文件大小
            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? Int64 {
                fileSize = size
            }

            // 获取图片尺寸（仅图片类型）
            if fileType == .image {
                if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
                   let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
                   let width = properties[kCGImagePropertyPixelWidth as String] as? Int,
                   let height = properties[kCGImagePropertyPixelHeight as String] as? Int {
                    dimensions = CGSize(width: width, height: height)
                }
            }

            return (fileSize, dimensions)
        }.value
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
