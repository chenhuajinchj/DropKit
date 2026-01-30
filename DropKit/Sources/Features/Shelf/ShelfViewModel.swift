import Foundation
import AppKit

enum ShelfViewState {
    case collapsed
    case expanded
}

enum DisplayMode {
    case grid
    case list
}

@Observable
class ShelfViewModel {
    var items: [ShelfItem] = []
    var viewState: ShelfViewState = .collapsed
    var displayMode: DisplayMode = .grid

    // MARK: - Item Management

    func addItem(url: URL) {
        var item = ShelfItem(url: url)
        items.append(item)
        loadThumbnail(for: items.count - 1)
    }

    func addItems(urls: [URL]) {
        for url in urls {
            addItem(url: url)
        }
    }

    func removeItem(_ item: ShelfItem) {
        items.removeAll { $0.id == item.id }
        // 如果清空了，回到收起状态
        if items.isEmpty {
            viewState = .collapsed
        }
    }

    func removeItem(at index: Int) {
        guard items.indices.contains(index) else { return }
        items.remove(at: index)
        if items.isEmpty {
            viewState = .collapsed
        }
    }

    func clearAll() {
        items.removeAll()
        viewState = .collapsed
    }

    // MARK: - Statistics

    var totalSize: Int64 {
        items.reduce(0) { $0 + $1.fileSize }
    }

    var formattedTotalSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }

    var itemCountDescription: String {
        let imageCount = items.filter { $0.fileType == .image }.count
        let videoCount = items.filter { $0.fileType == .video }.count
        let docCount = items.filter { $0.fileType == .document }.count
        let otherCount = items.filter { $0.fileType == .other }.count

        var parts: [String] = []
        if imageCount > 0 { parts.append("\(imageCount)张图片") }
        if videoCount > 0 { parts.append("\(videoCount)个视频") }
        if docCount > 0 { parts.append("\(docCount)个文档") }
        if otherCount > 0 { parts.append("\(otherCount)个文件") }

        if parts.isEmpty {
            return "无文件"
        } else if parts.count == 1 {
            return parts[0]
        } else {
            return "\(items.count)个文件"
        }
    }

    // MARK: - View State

    func expand() {
        guard !items.isEmpty else { return }
        viewState = .expanded
    }

    func collapse() {
        viewState = .collapsed
    }

    func toggleDisplayMode() {
        displayMode = displayMode == .grid ? .list : .grid
    }

    // MARK: - Thumbnail Loading

    private func loadThumbnail(for index: Int) {
        guard items.indices.contains(index) else { return }
        let item = items[index]

        Task {
            let thumbnail = await generateThumbnail(for: item.url)
            await MainActor.run {
                if self.items.indices.contains(index) && self.items[index].id == item.id {
                    self.items[index].thumbnail = thumbnail
                }
            }
        }
    }

    private func generateThumbnail(for url: URL) async -> NSImage? {
        let size = CGSize(width: 120, height: 120)

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let thumbnail = NSWorkspace.shared.icon(forFile: url.path)
                thumbnail.size = size

                // 对于图片文件，尝试生成实际缩略图
                let ext = url.pathExtension.lowercased()
                let imageExtensions = ["jpg", "jpeg", "png", "gif", "heic", "webp", "tiff", "bmp"]

                if imageExtensions.contains(ext),
                   let image = NSImage(contentsOf: url) {
                    let resized = self.resizeImage(image, to: size)
                    continuation.resume(returning: resized)
                } else {
                    continuation.resume(returning: thumbnail)
                }
            }
        }
    }

    private func resizeImage(_ image: NSImage, to size: CGSize) -> NSImage {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }

    // MARK: - Finder Integration

    func showInFinder(_ item: ShelfItem) {
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }
}
