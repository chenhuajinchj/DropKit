import AppKit
import SwiftUI

/// 支持多文件拖拽的 NSView 包装器
class DraggableStackNSView: NSView, NSDraggingSource {
    var urls: [URL] = []
    var thumbnails: [NSImage?] = []
    var onTap: (() -> Void)?
    var onFilesMovedOut: (([URL]) -> Void)?
    private var isDragging = false
    private var mouseDownLocation: NSPoint?
    private var draggedUrls: [URL] = []

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        mouseDownLocation = event.locationInWindow
        isDragging = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard !isDragging, !urls.isEmpty else { return }

        // 检查是否移动了足够距离才开始拖拽
        if let startLocation = mouseDownLocation {
            let currentLocation = event.locationInWindow
            let distance = hypot(currentLocation.x - startLocation.x, currentLocation.y - startLocation.y)
            if distance < 5 { return }
        }

        isDragging = true
        startDragging(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        if !isDragging {
            onTap?()
        }
        isDragging = false
        mouseDownLocation = nil
    }

    // MARK: - Dragging Source

    private func startDragging(with event: NSEvent) {
        // 记录正在拖拽的 URLs
        draggedUrls = urls

        // 为每个文件创建单独的拖拽项
        var draggingItems: [NSDraggingItem] = []

        for url in urls {
            let draggingItem = NSDraggingItem(pasteboardWriter: url as NSURL)

            // 设置拖拽图像
            let dragImage = createDragImage()
            let imageSize = dragImage.size
            let imageRect = NSRect(
                x: bounds.midX - imageSize.width / 2,
                y: bounds.midY - imageSize.height / 2,
                width: imageSize.width,
                height: imageSize.height
            )
            draggingItem.setDraggingFrame(imageRect, contents: dragImage)
            draggingItems.append(draggingItem)
        }

        // 开始拖拽会话
        beginDraggingSession(with: draggingItems, event: event, source: self)
    }

    private func createDragImage() -> NSImage {
        let size = NSSize(width: 80, height: 80)
        let image = NSImage(size: size)
        image.lockFocus()

        // 获取缩略图或系统图标
        let thumbnail: NSImage
        if let firstThumb = thumbnails.first ?? nil {
            thumbnail = firstThumb
        } else if let firstUrl = urls.first {
            thumbnail = NSWorkspace.shared.icon(forFile: firstUrl.path)
        } else {
            thumbnail = NSImage(systemSymbolName: "doc", accessibilityDescription: nil) ?? NSImage()
        }

        // 绘制缩略图
        let iconRect = NSRect(x: 0, y: 0, width: 80, height: 80)
        thumbnail.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1.0)

        image.unlockFocus()
        return image
    }

    // MARK: - NSDraggingSource

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return context == .outsideApplication ? [.copy, .move] : .copy
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        isDragging = false

        // 如果是移动操作，通知外部移除这些文件
        if operation == .move {
            let urlsToCheck = draggedUrls
            // 延迟检查，确保文件系统操作完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                // 检查文件是否真的被移动了（原路径不存在）
                let movedUrls = urlsToCheck.filter { !FileManager.default.fileExists(atPath: $0.path) }
                if !movedUrls.isEmpty {
                    self?.onFilesMovedOut?(movedUrls)
                }
            }
        }

        draggedUrls = []
    }
}

/// SwiftUI 包装器
struct DraggableStackView: NSViewRepresentable {
    let urls: [URL]
    let thumbnails: [NSImage?]
    let onTap: () -> Void
    let onFilesMovedOut: (([URL]) -> Void)?
    let content: () -> AnyView

    init(urls: [URL], thumbnails: [NSImage?], onTap: @escaping () -> Void, onFilesMovedOut: (([URL]) -> Void)? = nil, content: @escaping () -> AnyView) {
        self.urls = urls
        self.thumbnails = thumbnails
        self.onTap = onTap
        self.onFilesMovedOut = onFilesMovedOut
        self.content = content
    }

    func makeNSView(context: Context) -> DraggableStackNSView {
        let view = DraggableStackNSView()
        view.urls = urls
        view.thumbnails = thumbnails
        view.onTap = onTap
        view.onFilesMovedOut = onFilesMovedOut

        // 添加 SwiftUI 内容作为子视图
        let hostingView = NSHostingView(rootView: content())
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: view.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        return view
    }

    func updateNSView(_ nsView: DraggableStackNSView, context: Context) {
        nsView.urls = urls
        nsView.thumbnails = thumbnails
        nsView.onTap = onTap
        nsView.onFilesMovedOut = onFilesMovedOut

        // 更新 SwiftUI 内容
        if let hostingView = nsView.subviews.first as? NSHostingView<AnyView> {
            hostingView.rootView = content()
        }
    }
}

// MARK: - 单文件拖拽 NSView（支持多选）

/// 支持单文件/多文件拖拽的 NSView 包装器（用于展开视图中的 Grid/List Item）
class DraggableItemNSView: NSView, NSDraggingSource {
    var url: URL?
    var thumbnail: NSImage?
    var getSelectedUrls: (() -> [URL])?
    var isSelected: (() -> Bool)?
    var onDragEnd: (([URL]) -> Void)?
    private var isDragging = false
    private var mouseDownLocation: NSPoint?
    private var draggedUrls: [URL] = []

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        mouseDownLocation = event.locationInWindow
        isDragging = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard !isDragging, let url = url else { return }

        if let startLocation = mouseDownLocation {
            let currentLocation = event.locationInWindow
            let distance = hypot(currentLocation.x - startLocation.x, currentLocation.y - startLocation.y)
            if distance < 5 { return }
        }

        isDragging = true
        startDragging(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        isDragging = false
        mouseDownLocation = nil
    }

    // MARK: - Dragging Source

    private func startDragging(with event: NSEvent) {
        guard let url = url else { return }

        // 判断要拖拽的 URLs
        let urlsToDrag: [URL]
        if let isSelected = isSelected, isSelected(), let getSelectedUrls = getSelectedUrls {
            // 如果当前项被选中，拖拽所有选中的文件
            urlsToDrag = getSelectedUrls()
        } else {
            // 如果当前项未被选中，只拖拽当前文件
            urlsToDrag = [url]
        }

        draggedUrls = urlsToDrag

        // 为每个文件创建拖拽项
        var draggingItems: [NSDraggingItem] = []
        for (index, dragUrl) in urlsToDrag.enumerated() {
            let draggingItem = NSDraggingItem(pasteboardWriter: dragUrl as NSURL)
            // 设置拖拽图像（第一个用缩略图，其他用文件图标）
            let image = (index == 0 && thumbnail != nil) ? thumbnail! : NSWorkspace.shared.icon(forFile: dragUrl.path)
            let imageSize = NSSize(width: 60, height: 60)
            draggingItem.setDraggingFrame(
                NSRect(origin: NSPoint(x: CGFloat(index) * 10, y: CGFloat(index) * -10), size: imageSize),
                contents: image
            )
            draggingItems.append(draggingItem)
        }

        beginDraggingSession(with: draggingItems, event: event, source: self)
    }

    // MARK: - NSDraggingSource

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return context == .outsideApplication ? [.copy, .move] : .copy
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        isDragging = false

        // 如果是移动操作，通知外部移除这些文件
        if operation == .move {
            let urlsToCheck = draggedUrls
            // 延迟检查，确保文件系统操作完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                // 检查文件是否真的被移动了（原路径不存在）
                let movedUrls = urlsToCheck.filter { !FileManager.default.fileExists(atPath: $0.path) }
                if !movedUrls.isEmpty {
                    self?.onDragEnd?(movedUrls)
                }
            }
        }

        draggedUrls = []
    }
}

/// 单文件/多文件拖拽的 SwiftUI 包装器
struct DraggableItemView<Content: View>: NSViewRepresentable {
    let url: URL
    let thumbnail: NSImage?
    let getSelectedUrls: () -> [URL]
    let isSelected: () -> Bool
    let onDragEnd: ([URL]) -> Void
    let content: () -> Content

    init(
        url: URL,
        thumbnail: NSImage? = nil,
        getSelectedUrls: @escaping () -> [URL] = { [] },
        isSelected: @escaping () -> Bool = { false },
        onDragEnd: @escaping ([URL]) -> Void = { _ in },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.url = url
        self.thumbnail = thumbnail
        self.getSelectedUrls = getSelectedUrls
        self.isSelected = isSelected
        self.onDragEnd = onDragEnd
        self.content = content
    }

    func makeNSView(context: Context) -> DraggableItemNSView {
        let view = DraggableItemNSView()
        view.url = url
        view.thumbnail = thumbnail
        view.getSelectedUrls = getSelectedUrls
        view.isSelected = isSelected
        view.onDragEnd = onDragEnd

        let hostingView = NSHostingView(rootView: content())
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: view.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        return view
    }

    func updateNSView(_ nsView: DraggableItemNSView, context: Context) {
        nsView.url = url
        nsView.thumbnail = thumbnail
        nsView.getSelectedUrls = getSelectedUrls
        nsView.isSelected = isSelected
        nsView.onDragEnd = onDragEnd

        if let hostingView = nsView.subviews.first as? NSHostingView<Content> {
            hostingView.rootView = content()
        }
    }
}
