import AppKit

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

    private(set) var items: [ClipboardItem] = []
    private var lastChangeCount: Int = 0
    private var timer: Timer?

    var searchText: String = ""
    var selectedFilter: ClipboardFilterType = .all

    let maxItems: Int = 50

    var effectiveRetentionDays: Int {
        AppSettings.shared.clipboardRetentionDays
    }

    var effectiveMaxItems: Int {
        AppSettings.shared.clipboardMaxItems
    }

    var filteredItems: [ClipboardItem] {
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

        return result
    }

    private var storageURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dropkitDir = appSupport.appendingPathComponent("DropKit", isDirectory: true)
        try? FileManager.default.createDirectory(at: dropkitDir, withIntermediateDirectories: true)
        return dropkitDir.appendingPathComponent("clipboard_history.json")
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
        // 优先检查文件
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

        // 检查图片
        if pasteboard.data(forType: .tiff) != nil || pasteboard.data(forType: .png) != nil {
            return ClipboardItem(type: .image, content: "")
        }

        return nil
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
            break
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
