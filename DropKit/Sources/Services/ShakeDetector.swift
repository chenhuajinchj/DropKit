import AppKit

@Observable
class ShakeDetector {
    private(set) var shakeDetected = false

    private var monitor: Any?
    private var lastX: CGFloat = 0
    private var lastDirection: Int = 0  // -1: left, 1: right, 0: none
    private var directionChanges: [Date] = []

    // 配置参数（从 AppSettings 读取）
    var minShakes: Int { AppSettings.shared.shakeMinShakes }
    var timeWindow: TimeInterval { AppSettings.shared.shakeTimeWindow }
    var minMovement: CGFloat { CGFloat(AppSettings.shared.shakeMinMovement) }

    var onShake: (() -> Void)?

    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged]) { [weak self] event in
            self?.handleMouseMove(event)
        }
    }

    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        reset()
    }

    func reset() {
        lastX = 0
        lastDirection = 0
        directionChanges.removeAll()
        shakeDetected = false
    }

    private func handleMouseMove(_ event: NSEvent) {
        let currentX = NSEvent.mouseLocation.x
        let deltaX = currentX - lastX

        // 忽略小幅度移动
        guard abs(deltaX) > minMovement else { return }

        let currentDirection = deltaX > 0 ? 1 : -1

        // 检测方向变化
        if lastDirection != 0 && currentDirection != lastDirection {
            let now = Date()
            directionChanges.append(now)

            // 清理过期的方向变化记录
            directionChanges = directionChanges.filter { now.timeIntervalSince($0) < timeWindow }

            // 检测是否达到摇晃阈值
            if directionChanges.count >= minShakes && !shakeDetected {
                shakeDetected = true
                onShake?()
            }
        }

        lastX = currentX
        lastDirection = currentDirection
    }

    deinit {
        stop()
    }
}
