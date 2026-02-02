import AppKit
import UniformTypeIdentifiers

enum ClipboardFilterType: String, CaseIterable {
    case all = "全部"
    case text = "文本"
    case image = "图片"
    case file = "文件"
    case favorites = "收藏"
}

@Observable
class ClipboardMonitor {
    static let shared = ClipboardMonitor()

    private(set) var items: [ClipboardItem] = [] {
        didSet { _filteredItemsCache = nil }
    }
    private var lastChangeCount: Int = 0
    private var timer: Timer?

    var searchText: String = "" {
        didSet { _filteredItemsCache = nil }
    }
    var selectedFilter: ClipboardFilterType = .all {
        didSet { _filteredItemsCache = nil }
    }

    // filteredItems 缓存
    private var _filteredItemsCache: [ClipboardItem]?

    let maxItems: Int = 50

    var effectiveRetentionDays: Int {
        AppSettings.shared.clipboardRetentionDays
    }

    var effectiveMaxItems: Int {
        AppSettings.shared.clipboardMaxItems
    }

    var filteredItems: [ClipboardItem] {
        if let cache = _filteredItemsCache {
            return cache
        }

        var result = items

        switch selectedFilter {
        case .all: break
        case .text: result = result.filter { $0.type == .text || $0.type == .html }
        case .image: result = result.filter { $0.type == .image }
        case .file: result = result.filter { $0.type == .file }
        case .favorites: result = result.filter { $0.isFavorite }
        }

        if !searchText.isEmpty {
            result = result.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
        }

        _filteredItemsCache = result
        return result
    }

    private var storageURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dropkitDir = appSupport.appendingPathComponent("DropKit", isDirectory: true)
        try? FileManager.default.createDirectory(at: dropkitDir, withIntermediateDirectories: true)
        return dropkitDir.appendingPathComponent("clipboard_history.json")
    }

    private var imagesDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let imagesDir = appSupport.appendingPathComponent("DropKit/ClipboardImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        return imagesDir
    }

    init() {
        loadItems()
    }

    func start() {
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        if let item = readClipboardItem(from: pasteboard) {
            addItem(item)
        }
    }

    private func readClipboardItem(from pasteboard: NSPasteboard) -> ClipboardItem? {
        // 优先检查图片（截图等场景）
        if let imageData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff) {
            if let imagePath = saveImageToFile(imageData) {
                return ClipboardItem(type: .image, content: imagePath)
            }
        }

        // 检查文件
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let url = urls.first, url.isFileURL {
            return ClipboardItem(type: .file, content: url.path)
        }

        // 检查 HTML
        if let html = pasteboard.string(forType: .html) {
            return ClipboardItem(type: .html, content: html)
        }

        // 检查纯文本（包括 URL，统一作为文本处理）
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            return ClipboardItem(type: .text, content: text)
        }

        return nil
    }

    private func saveImageToFile(_ data: Data) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let uuid = UUID().uuidString.prefix(8)
        let filename = "\(timestamp)_\(uuid).png"
        let fileURL = imagesDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)

            // 在后台从文件生成缩略图（不传递 data，避免内存持有）
            generateThumbnail(for: fileURL)

            return fileURL.path
        } catch {
            #if DEBUG
            print("Failed to save clipboard image: \(error)")
            #endif
            return nil
        }
    }

    private func generateThumbnail(for imageURL: URL) {
        Task.detached(priority: .utility) {
            let thumbSize = CGSize(width: 80, height: 80)
            let scale = 2.0
            let maxPixelSize = Int(max(thumbSize.width, thumbSize.height) * scale)

            // 使用 CGImageSource 的缩略图功能，避免加载完整图像到内存
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                kCGImageSourceShouldCacheImmediately: false
            ]

            guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
                  let thumbnailCGImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
                return
            }

            let thumbFilename = imageURL.deletingPathExtension().lastPathComponent + "_thumb.png"
            let thumbURL = imageURL.deletingLastPathComponent().appendingPathComponent(thumbFilename)

            guard let destination = CGImageDestinationCreateWithURL(
                thumbURL as CFURL,
                UTType.png.identifier as CFString,
                1,
                nil
            ) else { return }

            CGImageDestinationAddImage(destination, thumbnailCGImage, nil)
            CGImageDestinationFinalize(destination)
        }
    }

    private func addItem(_ item: ClipboardItem) {
        // 避免重复
        if let lastItem = items.first, lastItem.content == item.content && lastItem.type == item.type {
            return
        }

        items.insert(item, at: 0)
        cleanupExpiredItems()
        saveItems()
    }

    private func cleanupExpiredItems() {
        // 按天数清理（收藏的不删除）
        let days = effectiveRetentionDays
        if days > 0 {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
            items.removeAll { $0.timestamp < cutoffDate && !$0.isFavorite }
        }

        // 按条数清理（收藏的不删除）
        let maxItems = effectiveMaxItems
        if maxItems > 0 && items.count > maxItems {
            // 保留收藏的 + 最新的非收藏项
            let favorites = items.filter { $0.isFavorite }
            var nonFavorites = items.filter { !$0.isFavorite }
            let allowedNonFavorites = max(0, maxItems - favorites.count)
            nonFavorites = Array(nonFavorites.prefix(allowedNonFavorites))
            items = (favorites + nonFavorites).sorted { $0.timestamp > $1.timestamp }
        }

        // 清理孤立的图片文件
        cleanupOrphanedImages()
    }

    private func cleanupOrphanedImages() {
        let validPaths = Set(items.filter { $0.type == .image }.map { $0.content })

        guard let files = try? FileManager.default.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: nil) else {
            return
        }

        for file in files {
            let path = file.path
            // 检查是否是孤立的原图或缩略图
            let isThumb = path.contains("_thumb.png")
            let originalPath = isThumb ? path.replacingOccurrences(of: "_thumb.png", with: ".png") : path

            if !validPaths.contains(originalPath) {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    func copyToClipboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.type {
        case .text, .html:
            pasteboard.setString(item.content, forType: .string)
        case .file:
            let url = URL(fileURLWithPath: item.content)
            pasteboard.writeObjects([url as NSURL])
        case .image:
            if !item.content.isEmpty,
               let imageData = try? Data(contentsOf: URL(fileURLWithPath: item.content)),
               let image = NSImage(data: imageData) {
                pasteboard.writeObjects([image])
            }
        }
    }

    func toggleFavorite(_ item: ClipboardItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isFavorite.toggle()
            saveItems()
        }
    }

    func removeItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }

    func clearAll() {
        items.removeAll()
        saveItems()
    }

    // MARK: - Persistence

    private func loadItems() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            items = try JSONDecoder().decode([ClipboardItem].self, from: data)
            cleanupExpiredItems()
        } catch {
            #if DEBUG
            print("Failed to load clipboard history: \(error)")
            #endif
        }
    }

    private func saveItems() {
        let itemsToSave = items  // 捕获当前状态
        let url = storageURL
        Task.detached(priority: .utility) {
            do {
                let data = try JSONEncoder().encode(itemsToSave)
                try data.write(to: url, options: .atomic)
            } catch {
                #if DEBUG
                print("Failed to save clipboard history: \(error)")
                #endif
            }
        }
    }

    deinit {
        stop()
    }
}
