import AppKit

protocol GlobalEventMonitoring {
    func addGlobalMonitor(matching mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> Void) -> Any?
    func removeMonitor(_ monitor: Any)
}

struct AppKitGlobalEventMonitor: GlobalEventMonitoring {
    func addGlobalMonitor(matching mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> Void) -> Any? {
        NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    }

    func removeMonitor(_ monitor: Any) {
        NSEvent.removeMonitor(monitor)
    }
}

@Observable
class DragMonitor {
    private(set) var isDragging = false

    private var dragMonitor: Any?
    private var upMonitor: Any?
    private let permissionChecker: () -> Bool
    private let eventMonitor: any GlobalEventMonitoring

    var onDragStart: (() -> Void)?
    var onDragEnd: (() -> Void)?

    init(
        permissionChecker: @escaping () -> Bool = PermissionChecker.checkAccessibilityPermission,
        eventMonitor: any GlobalEventMonitoring = AppKitGlobalEventMonitor()
    ) {
        self.permissionChecker = permissionChecker
        self.eventMonitor = eventMonitor
    }

    @discardableResult
    func start() -> Bool {
        guard permissionChecker() else { return false }
        guard dragMonitor == nil, upMonitor == nil else { return true }

        guard let dragMonitor = eventMonitor.addGlobalMonitor(matching: .leftMouseDragged, handler: { [weak self] _ in
            guard let self = self, !self.isDragging else { return }
            self.isDragging = true
            self.onDragStart?()
        }) else { return false }

        guard let upMonitor = eventMonitor.addGlobalMonitor(matching: .leftMouseUp, handler: { [weak self] _ in
            guard let self = self, self.isDragging else { return }
            self.isDragging = false
            self.onDragEnd?()
        }) else {
            eventMonitor.removeMonitor(dragMonitor)
            return false
        }

        self.dragMonitor = dragMonitor
        self.upMonitor = upMonitor
        return true
    }

    func stop() {
        if let monitor = dragMonitor {
            eventMonitor.removeMonitor(monitor)
            dragMonitor = nil
        }
        if let monitor = upMonitor {
            eventMonitor.removeMonitor(monitor)
            upMonitor = nil
        }
        isDragging = false
    }

    deinit {
        stop()
    }
}
