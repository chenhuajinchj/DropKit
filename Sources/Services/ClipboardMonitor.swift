import AppKit

@Observable
class ClipboardMonitor {
    private(set) var items: [ClipboardItem] = []
    private var lastChangeCount: Int = 0
    private var timer: Timer?

    let maxItems: Int = 50

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

        // 检查 URL
        if let urlString = pasteboard.string(forType: .URL) {
            return ClipboardItem(type: .url, content: urlString)
        }

        // 检查 HTML
        if let html = pasteboard.string(forType: .html) {
            return ClipboardItem(type: .html, content: html)
        }

        // 检查纯文本
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            // 检查是否是 URL
            if let url = URL(string: text), url.scheme != nil {
                return ClipboardItem(type: .url, content: text)
            }
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

        // 限制数量
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
    }

    func copyToClipboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.type {
        case .text, .html:
            pasteboard.setString(item.content, forType: .string)
        case .url:
            pasteboard.setString(item.content, forType: .string)
            if let url = URL(string: item.content) {
                pasteboard.setString(url.absoluteString, forType: .URL)
            }
        case .file:
            let url = URL(fileURLWithPath: item.content)
            pasteboard.writeObjects([url as NSURL])
        case .image:
            break
        }
    }

    func removeItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
    }

    func clearAll() {
        items.removeAll()
    }

    deinit {
        stop()
    }
}
