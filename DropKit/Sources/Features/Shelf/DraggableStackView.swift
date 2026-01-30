import AppKit
import SwiftUI

/// 支持多文件拖拽的 NSView 包装器
class DraggableStackNSView: NSView, NSDraggingSource {
    var urls: [URL] = []
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
        let size = NSSize(width: 100, height: 100)
        let image = NSImage(size: size)
        image.lockFocus()

        // 绘制简单的文件图标
        let iconRect = NSRect(x: 10, y: 10, width: 80, height: 80)
        NSColor.controlBackgroundColor.setFill()
        let path = NSBezierPath(roundedRect: iconRect, xRadius: 8, yRadius: 8)
        path.fill()

        // 绘制文件数量
        let countString = "\(urls.count)"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: NSColor.labelColor
        ]
        let textSize = countString.size(withAttributes: attributes)
        let textPoint = NSPoint(
            x: iconRect.midX - textSize.width / 2,
            y: iconRect.midY - textSize.height / 2
        )
        countString.draw(at: textPoint, withAttributes: attributes)

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
    let onTap: () -> Void
    let onFilesMovedOut: (([URL]) -> Void)?
    let content: () -> AnyView

    init(urls: [URL], onTap: @escaping () -> Void, onFilesMovedOut: (([URL]) -> Void)? = nil, content: @escaping () -> AnyView) {
        self.urls = urls
        self.onTap = onTap
        self.onFilesMovedOut = onFilesMovedOut
        self.content = content
    }

    func makeNSView(context: Context) -> DraggableStackNSView {
        let view = DraggableStackNSView()
        view.urls = urls
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
        nsView.onTap = onTap
        nsView.onFilesMovedOut = onFilesMovedOut

        // 更新 SwiftUI 内容
        if let hostingView = nsView.subviews.first as? NSHostingView<AnyView> {
            hostingView.rootView = content()
        }
    }
}
