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

    // 缩略图加载任务引用，key = "\(uuid)-\(kind)"，允许同一 item 的大小图并行加载
    private var thumbnailTasks: [String: Task<Void, Never>] = [:]

    // 最大文件数限制，防止内存溢出
    private let maxItems = 100

    // 缩略图规格：grid / collapsed / 拖拽用大图；list 用小图
    enum ThumbnailKind {
        case large   // 200×200，给 grid、collapsed、拖拽
        case small   // 64×64，给 list

        var size: CGSize {
            switch self {
            case .large: return CGSize(width: 200, height: 200)
            case .small: return CGSize(width: 64, height: 64)
            }
        }
    }

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
        items.insert(item, at: 0)  // 新文件插入到开头，最新的显示在最前
        // 不再立即生成缩略图；由 cell.onAppear 按需触发 ensureThumbnail。
        // 但 fileSize/dimensions 仍需尽快加载，首次显示时立即可用。
        loadFileInfo(for: item.id)

        // 超出限制时移除最早的项（现在是数组末尾）
        while items.count > maxItems {
            let removed = items.removeLast()
            removeFromCache(removed)
        }
    }

    func addItems(urls: [URL]) {
        for url in urls {
            addItem(url: url)
        }
    }

    func removeItem(_ item: ShelfItem) {
        // 取消缩略图加载任务（大图 + 小图）
        cancelAllThumbnailTasks(for: item.id)
        // 从缓存中移除
        removeFromCache(item)
        items.removeAll { $0.id == item.id }
        // 如果清空了，回到收起状态
        if items.isEmpty {
            viewState = .collapsed
        }
    }

    private func cancelAllThumbnailTasks(for itemId: UUID) {
        for kind in [ThumbnailKind.large, .small] {
            let key = thumbnailTaskKey(itemId: itemId, kind: kind)
            thumbnailTasks[key]?.cancel()
            thumbnailTasks.removeValue(forKey: key)
        }
        // 文件信息任务
        thumbnailTasks["\(itemId)-info"]?.cancel()
        thumbnailTasks.removeValue(forKey: "\(itemId)-info")
    }

    private func thumbnailTaskKey(itemId: UUID, kind: ThumbnailKind) -> String {
        "\(itemId)-\(kind == .large ? "L" : "S")"
    }

    func removeItems(byUrls urls: [URL]) {
        let urlSet = Set(urls)
        let itemsToRemove = items.filter { urlSet.contains($0.url) }
        for item in itemsToRemove {
            removeFromCache(item)
        }
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

    private func removeFromCache(_ item: ShelfItem) {
        let isSwiftUIDragCache = item.url.path.contains("com.apple.SwiftUI.Drag")
        if isSwiftUIDragCache {
            fileNames.remove(item.url.lastPathComponent)
        } else if let cachedId = item.cachedFileIdentifier {
            fileIdentifiers.remove(cachedId)
        }
    }

    func clearAll() {
        // 取消所有缩略图加载任务
        for task in thumbnailTasks.values {
            task.cancel()
        }
        thumbnailTasks.removeAll()
        items.removeAll()
        fileIdentifiers.removeAll()
        fileNames.removeAll()
        viewState = .collapsed
    }

    func deleteSelected() {
        let idsToRemove = selectedItemIds
        for id in idsToRemove {
            cancelAllThumbnailTasks(for: id)
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

    // MARK: - Statistics

    var totalSize: Int64 {
        items.reduce(0) { $0 + $1.fileSize }
    }

    private static let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    var formattedTotalSize: String {
        Self.byteCountFormatter.string(fromByteCount: totalSize)
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

    /// 确保指定 item 在指定规格上的缩略图已生成（由 cell.onAppear 调用）。
    /// 如果已有对应规格的缩略图，或任务正在进行中，则跳过。
    func ensureThumbnail(for itemId: UUID, kind: ThumbnailKind) {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else { return }
        let item = items[index]

        // 已有对应规格的缩略图，跳过
        switch kind {
        case .large where item.thumbnail != nil: return
        case .small where item.listThumbnail != nil: return
        default: break
        }

        let taskKey = thumbnailTaskKey(itemId: itemId, kind: kind)
        if thumbnailTasks[taskKey] != nil { return }  // 已有进行中任务

        let url = item.url
        let size = kind.size
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0

        let task = Task {
            let thumbnail = await Self.generateThumbnail(for: url, size: size, scale: scale)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let currentIndex = self.items.firstIndex(where: { $0.id == itemId }) else { return }
                switch kind {
                case .large:
                    self.items[currentIndex].thumbnail = thumbnail
                case .small:
                    self.items[currentIndex].listThumbnail = thumbnail
                }
                self.thumbnailTasks.removeValue(forKey: taskKey)
            }
        }
        thumbnailTasks[taskKey] = task
    }

    /// cell.onDisappear 调用：取消某个 item 某个规格的待办任务。
    /// 已生成的缩略图仍保留在 item 上，不清除（避免来回滚动反复生成）。
    func cancelThumbnailTask(for itemId: UUID, kind: ThumbnailKind) {
        let taskKey = thumbnailTaskKey(itemId: itemId, kind: kind)
        thumbnailTasks[taskKey]?.cancel()
        thumbnailTasks.removeValue(forKey: taskKey)
    }

    /// addItem 时触发，异步拉取文件大小/尺寸；缩略图不在这里生成。
    private func loadFileInfo(for itemId: UUID) {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else { return }
        let item = items[index]
        let taskKey = "\(itemId)-info"
        thumbnailTasks[taskKey]?.cancel()

        let task = Task {
            let fileInfo = await ShelfItem.loadFileInfo(for: item.url, fileType: item.fileType)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if let currentIndex = self.items.firstIndex(where: { $0.id == itemId }) {
                    self.items[currentIndex].fileSize = fileInfo.fileSize
                    self.items[currentIndex].dimensions = fileInfo.dimensions
                }
                self.thumbnailTasks.removeValue(forKey: taskKey)
            }
        }
        thumbnailTasks[taskKey] = task
    }

    private static func generateThumbnail(for url: URL, size: CGSize, scale: CGFloat) async -> NSImage? {
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: size,
            scale: scale,
            representationTypes: .thumbnail
        )

        do {
            let thumbnail = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
            return NSImage(cgImage: thumbnail.cgImage, size: size)
        } catch {
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

}
