import AppKit

@Observable
class ShakeDetector {
    private(set) var shakeDetected = false

    private var monitor: Any?
    private var lastX: CGFloat = 0
    private var lastDirection: Int = 0  // -1: left, 1: right, 0: none
    private var directionChanges: [Date] = []

    // 性能优化：数组大小上限，防止长时间拖拽时无限增长
    private let maxDirectionChanges = 20

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

            // 优化：只在数组较大时才清理，减少高频过滤开销
            if directionChanges.count > maxDirectionChanges {
                // 只保留时间窗口内的记录
                directionChanges = directionChanges.filter { now.timeIntervalSince($0) < timeWindow }
            }

            // 检测是否达到摇晃阈值（惰性计算有效记录数）
            if !shakeDetected {
                let validCount = directionChanges.count > maxDirectionChanges
                    ? directionChanges.count  // 刚清理过，都是有效的
                    : directionChanges.filter { now.timeIntervalSince($0) < timeWindow }.count

                if validCount >= minShakes {
                    shakeDetected = true
                    onShake?()
                }
            }
        }

        lastX = currentX
        lastDirection = currentDirection
    }

    deinit {
        stop()
    }
}
