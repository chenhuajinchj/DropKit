import AppKit

class ShelfDropView: NSView {
    var onDrop: (([URL]) -> Void)?
    var onDragStateChanged: ((Bool) -> Void)?

    private var isDraggingOver = false {
        didSet {
            onDragStateChanged?(isDraggingOver)
            updateHighlight()
        }
    }

    private var highlightLayer: CALayer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        registerForDraggedTypes([.fileURL])
        wantsLayer = true
    }

    // MARK: - Window Dragging

    override var mouseDownCanMoveWindow: Bool { false }

    override func mouseDown(with event: NSEvent) {
        // 允许通过拖拽移动窗口
        window?.performDrag(with: event)
    }

    // MARK: - Drop Highlight

    private func updateHighlight() {
        if isDraggingOver {
            if highlightLayer == nil {
                let highlight = CALayer()
                highlight.frame = bounds
                highlight.borderColor = NSColor.controlAccentColor.cgColor
                highlight.borderWidth = 3
                highlight.cornerRadius = 12
                highlight.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.1).cgColor
                layer?.addSublayer(highlight)
                highlightLayer = highlight
            }
            highlightLayer?.frame = bounds
        } else {
            highlightLayer?.removeFromSuperlayer()
            highlightLayer = nil
        }
    }

    override func layout() {
        super.layout()
        highlightLayer?.frame = bounds
    }

    // MARK: - Drag Operations

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        isDraggingOver = true
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        isDraggingOver = false
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        isDraggingOver = false
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isDraggingOver = false
        let pasteboard = sender.draggingPasteboard
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return false
        }
        onDrop?(urls)
        return true
    }
}
