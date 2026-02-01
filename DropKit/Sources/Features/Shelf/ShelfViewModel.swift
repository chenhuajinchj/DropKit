import Foundation
import AppKit
import QuickLookThumbnailing

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

    // 多选状态
    var selectedItemIds: Set<UUID> = []
    private var lastSelectedId: UUID?

    // 用于快速查重的缓存
    private var fileIdentifiers = Set<String>()
    private var fileNames = Set<String>()  // 用于 SwiftUI 临时文件

    // 最大文件数限制，防止内存溢出
    private let maxItems = 100

    // MARK: - Item Management

    func addItem(url: URL) {
        // 检查是否是 SwiftUI 拖拽产生的临时文件
        let isSwiftUIDragCache = url.path.contains("com.apple.SwiftUI.Drag")

        if isSwiftUIDragCache {
            // 临时文件用文件名比较
            let fileName = url.lastPathComponent
            // 检查 fileNames 缓存
            if fileNames.contains(fileName) {
                return
            }
            // 检查 items 中是否已有相同文件名的文件（原始文件）
            if items.contains(where: { $0.url.lastPathComponent == fileName }) {
                return
            }
            fileNames.insert(fileName)
        } else {
            // 先用路径检查是否已存在（最可靠的方式）
            let standardPath = url.standardizedFileURL.path
            if items.contains(where: { $0.url.standardizedFileURL.path == standardPath }) {
                return
            }

            // 再用 fileResourceIdentifier 加入缓存（用于后续快速查重）
            if let fileID = try? url.resourceValues(forKeys: [.fileResourceIdentifierKey]).fileResourceIdentifier {
                let idString = "\(fileID)"
                if fileIdentifiers.contains(idString) {
                    return
                }
                fileIdentifiers.insert(idString)
            }
        }

        let item = ShelfItem(url: url)
        items.append(item)
        loadThumbnail(for: items.count - 1)

        // 超出限制时移除最早的项
        while items.count > maxItems {
            let removed = items.removeFirst()
            removeFromCache(removed)
        }
    }

    func addItems(urls: [URL]) {
        for url in urls {
            addItem(url: url)
        }
    }

    func removeItem(_ item: ShelfItem) {
        // 从缓存中移除
        removeFromCache(item)
        items.removeAll { $0.id == item.id }
        // 如果清空了，回到收起状态
        if items.isEmpty {
            viewState = .collapsed
        }
    }

    func removeItems(byUrls urls: [URL]) {
        for url in urls {
            removeFromCache(url)
        }
        let urlSet = Set(urls)
        items.removeAll { urlSet.contains($0.url) }
        if items.isEmpty {
            viewState = .collapsed
        }
    }

    func removeItem(at index: Int) {
        guard items.indices.contains(index) else { return }
        removeFromCache(items[index])
        items.remove(at: index)
        if items.isEmpty {
            viewState = .collapsed
        }
    }

    private func removeFromCache(_ url: URL) {
        let isSwiftUIDragCache = url.path.contains("com.apple.SwiftUI.Drag")
        if isSwiftUIDragCache {
            fileNames.remove(url.lastPathComponent)
        } else if let fileID = try? url.resourceValues(forKeys: [.fileResourceIdentifierKey]).fileResourceIdentifier {
            fileIdentifiers.remove("\(fileID)")
        }
    }

    /// 使用缓存的标识符移除，避免重复 I/O
    private func removeFromCache(_ item: ShelfItem) {
        let isSwiftUIDragCache = item.url.path.contains("com.apple.SwiftUI.Drag")
        if isSwiftUIDragCache {
            fileNames.remove(item.url.lastPathComponent)
        } else if let cachedId = item.cachedFileIdentifier {
            fileIdentifiers.remove(cachedId)
        }
    }

    func clearAll() {
        items.removeAll()
        fileIdentifiers.removeAll()
        fileNames.removeAll()
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
        let itemId = item.id

        Task {
            // 并行加载缩略图和文件信息
            async let thumbnailTask = generateThumbnail(for: item.url)
            async let fileInfoTask = ShelfItem.loadFileInfo(for: item.url, fileType: item.fileType)

            let thumbnail = await thumbnailTask
            let fileInfo = await fileInfoTask

            await MainActor.run {
                // 确保 item 还在且位置正确
                if let currentIndex = self.items.firstIndex(where: { $0.id == itemId }) {
                    self.items[currentIndex].thumbnail = thumbnail
                    self.items[currentIndex].fileSize = fileInfo.fileSize
                    self.items[currentIndex].dimensions = fileInfo.dimensions
                }
            }
        }
    }

    private func generateThumbnail(for url: URL) async -> NSImage? {
        let size = CGSize(width: 120, height: 120)

        // 使用新的 QLThumbnailGenerator API
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: size,
            scale: NSScreen.main?.backingScaleFactor ?? 2.0,
            representationTypes: .thumbnail
        )

        do {
            let thumbnail = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
            return NSImage(cgImage: thumbnail.cgImage, size: size)
        } catch {
            // 回退到系统图标
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            icon.size = size
            return icon
        }
    }

    // MARK: - Finder Integration

    func showInFinder(_ item: ShelfItem) {
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }

    // MARK: - Selection Management

    func isSelected(_ item: ShelfItem) -> Bool {
        selectedItemIds.contains(item.id)
    }

    var selectedItems: [ShelfItem] {
        items.filter { selectedItemIds.contains($0.id) }
    }

    var selectedUrls: [URL] {
        selectedItems.map { $0.url }
    }

    var selectedThumbnails: [NSImage?] {
        selectedItems.map { $0.thumbnail }
    }

    func toggleSelection(_ itemId: UUID, modifierFlags: NSEvent.ModifierFlags) {
        if modifierFlags.contains(.command) {
            // Cmd+点击：切换单个选中状态
            if selectedItemIds.contains(itemId) {
                selectedItemIds.remove(itemId)
            } else {
                selectedItemIds.insert(itemId)
            }
            lastSelectedId = itemId
        } else if modifierFlags.contains(.shift), let lastId = lastSelectedId {
            // Shift+点击：范围选中
            if let lastIndex = items.firstIndex(where: { $0.id == lastId }),
               let currentIndex = items.firstIndex(where: { $0.id == itemId }) {
                let range = min(lastIndex, currentIndex)...max(lastIndex, currentIndex)
                for i in range {
                    selectedItemIds.insert(items[i].id)
                }
            }
        } else {
            // 普通点击：单选
            selectedItemIds.removeAll()
            selectedItemIds.insert(itemId)
            lastSelectedId = itemId
        }
    }

    func selectAll() {
        selectedItemIds = Set(items.map { $0.id })
        lastSelectedId = items.last?.id
    }

    func deselectAll() {
        selectedItemIds.removeAll()
        lastSelectedId = nil
    }

    func deleteSelected() {
        let idsToRemove = selectedItemIds
        for id in idsToRemove {
            if let item = items.first(where: { $0.id == id }) {
                removeFromCache(item)
            }
        }
        items.removeAll { idsToRemove.contains($0.id) }
        selectedItemIds.removeAll()
        lastSelectedId = nil
        if items.isEmpty {
            viewState = .collapsed
        }
    }
}
