import AppKit

@Observable
class DragMonitor {
    private(set) var isDragging = false

    private var dragMonitor: Any?
    private var upMonitor: Any?

    var onDragStart: (() -> Void)?
    var onDragEnd: (() -> Void)?

    func start() {
        // 监听拖拽事件
        dragMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] _ in
            guard let self = self, !self.isDragging else { return }
            self.isDragging = true
            self.onDragStart?()
        }

        // 监听鼠标释放事件
        upMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] _ in
            guard let self = self, self.isDragging else { return }
            self.isDragging = false
            self.onDragEnd?()
        }
    }

    func stop() {
        if let monitor = dragMonitor {
            NSEvent.removeMonitor(monitor)
            dragMonitor = nil
        }
        if let monitor = upMonitor {
            NSEvent.removeMonitor(monitor)
            upMonitor = nil
        }
        isDragging = false
    }

    deinit {
        stop()
    }
}
