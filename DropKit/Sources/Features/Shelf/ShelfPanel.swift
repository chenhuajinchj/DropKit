import AppKit
import SwiftUI
import Combine

class ShelfPanel: NSPanel {
    let viewModel = ShelfViewModel()
    private var clickMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    private var isDocked = false
    private var windowMoveObserver: Any?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        setupPanel()
        observeViewState()
        setupWindowMoveObserver()
    }

    private func setupPanel() {
        // 浮在所有窗口之上
        level = .floating

        // 可以出现在所有空间和全屏应用上
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // 透明背景（为毛玻璃效果准备）
        isOpaque = false
        backgroundColor = .clear

        // 添加窗口阴影
        hasShadow = true

        // 不显示在 Dock 和 App Switcher
        hidesOnDeactivate = false

        // 使用自定义 dropView 作为 contentView
        let dropView = ShelfDropView(frame: NSRect(x: 0, y: 0, width: 200, height: 200))
        dropView.onDrop = { [weak self] urls in
            self?.viewModel.addItems(urls: urls)
        }
        contentView = dropView

        // 添加毛玻璃背景视图
        let visualEffect = NSVisualEffectView()
        visualEffect.translatesAutoresizingMaskIntoConstraints = false
        visualEffect.blendingMode = .behindWindow
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 10
        visualEffect.layer?.masksToBounds = true

        dropView.addSubview(visualEffect)

        // visualEffect 约束到 dropView
        NSLayoutConstraint.activate([
            visualEffect.topAnchor.constraint(equalTo: dropView.topAnchor),
            visualEffect.bottomAnchor.constraint(equalTo: dropView.bottomAnchor),
            visualEffect.leadingAnchor.constraint(equalTo: dropView.leadingAnchor),
            visualEffect.trailingAnchor.constraint(equalTo: dropView.trailingAnchor)
        ])

        // 嵌入 SwiftUI 视图到毛玻璃视图内部
        let hostingView = NSHostingView(rootView: ShelfView(viewModel: viewModel, onClose: { [weak self] in
            self?.closeAndClear()
        }))
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        visualEffect.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor)
        ])

        // 居中显示
        center()
    }

    // MARK: - Dynamic Size

    private func observeViewState() {
        // 使用递归的 withObservationTracking 实现真正的事件驱动
        func observe() {
            withObservationTracking {
                _ = viewModel.viewState
                _ = viewModel.items.count
            } onChange: {
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.updatePanelSize()

                    // 文件全部拖出后自动关闭
                    if self.viewModel.items.isEmpty && self.isVisible {
                        self.hidePanel()
                    }

                    // 继续监听下一次变化
                    observe()
                }
            }
        }

        // 启动监听
        observe()
        // 初始更新
        updatePanelSize()
    }

    private func updatePanelSize() {
        let newSize: NSSize

        switch viewModel.viewState {
        case .collapsed:
            newSize = viewModel.items.isEmpty ? NSSize(width: 200, height: 200) : NSSize(width: 200, height: 240)
        case .expanded:
            newSize = NSSize(width: 400, height: 300)
        }

        // 只有尺寸变化时才更新
        guard frame.size != newSize else { return }

        // 保持窗口中心位置
        let currentCenter = NSPoint(x: frame.midX, y: frame.midY)
        let newOrigin = NSPoint(
            x: currentCenter.x - newSize.width / 2,
            y: currentCenter.y - newSize.height / 2
        )

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.animator().setFrame(NSRect(origin: newOrigin, size: newSize), display: true)
        }
    }

    // 允许成为 key window（接收键盘事件）
    override var canBecomeKey: Bool { true }

    // 点击外部不自动关闭
    override var canBecomeMain: Bool { false }

    // MARK: - Show/Hide

    func showPanel() {
        isDocked = false

        // 确保窗口有 layer
        contentView?.wantsLayer = true
        guard let layer = contentView?.layer else {
            orderFront(nil)
            startClickMonitor()
            return
        }

        let bounds = layer.bounds
        let centerX = bounds.width / 2
        let centerY = bounds.height / 2

        // 使用组合变换实现从中心缩放（不改变 anchorPoint）
        // 原理：先平移到中心 -> 缩放 -> 再平移回来
        func makeScaleTransform(_ scale: CGFloat) -> CATransform3D {
            var transform = CATransform3DIdentity
            transform = CATransform3DTranslate(transform, centerX, centerY, 0)
            transform = CATransform3DScale(transform, scale, scale, 1.0)
            transform = CATransform3DTranslate(transform, -centerX, -centerY, 0)
            return transform
        }

        // 初始缩放为 0.3
        layer.transform = makeScaleTransform(0.3)

        orderFront(nil)
        startClickMonitor()

        // 弹性动画
        let springAnimation = CASpringAnimation(keyPath: "transform")
        springAnimation.fromValue = NSValue(caTransform3D: makeScaleTransform(0.3))
        springAnimation.toValue = NSValue(caTransform3D: CATransform3DIdentity)
        springAnimation.damping = 12  // 阻尼（越小弹跳越多）
        springAnimation.stiffness = 300  // 刚度（越大越快）
        springAnimation.mass = 1.0
        springAnimation.initialVelocity = 0
        springAnimation.duration = springAnimation.settlingDuration
        springAnimation.fillMode = .forwards
        springAnimation.isRemovedOnCompletion = false

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            layer.transform = CATransform3DIdentity
            layer.removeAnimation(forKey: "springScale")
        }
        layer.add(springAnimation, forKey: "springScale")
        CATransaction.commit()
    }

    func hidePanel() {
        stopClickMonitor()
        orderOut(nil)
        // 隐藏时清空内容和缓存，为下一次使用做准备
        viewModel.clearAll()
    }

    /// 点击 X 按钮：清空内容 + 关闭窗口
    func closeAndClear() {
        viewModel.clearAll()
        hidePanel()
    }

    private func startClickMonitor() {
        stopClickMonitor()
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.isVisible else { return }
            let screenLocation = NSEvent.mouseLocation

            // 检查点击是否在窗口外部
            if !self.frame.contains(screenLocation) {
                if self.viewModel.items.isEmpty {
                    // 悬浮窗为空时关闭
                    self.hidePanel()
                } else if !self.isDocked {
                    // 有内容且未停靠时，停靠到边缘
                    self.dockToEdge()
                }
            }
        }
    }

    // MARK: - Docking

    /// 根据窗口位置智能停靠到屏幕边缘
    private func dockToEdge() {
        guard let screen = self.screen ?? NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let windowCenter = frame.midX
        let edgePadding: CGFloat = 16  // 距离屏幕边缘的间距

        // 判断窗口在屏幕左半边还是右半边
        let screenCenter = screenFrame.midX
        let dockToLeft = windowCenter < screenCenter

        // 计算目标位置（保持 Y 坐标不变，添加边距）
        let targetX: CGFloat
        if dockToLeft {
            targetX = screenFrame.minX + edgePadding
        } else {
            targetX = screenFrame.maxX - frame.width - edgePadding
        }

        let targetFrame = NSRect(x: targetX, y: frame.origin.y, width: frame.width, height: frame.height)

        // 用 setFrame 动画滑动到边缘（使用更平滑的缓动曲线）
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.1, 0.25, 1.0)  // 类似 CSS ease-out-cubic
            context.allowsImplicitAnimation = true
            self.setFrame(targetFrame, display: true, animate: true)
        }

        isDocked = true
    }

    private func stopClickMonitor() {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
    }

    deinit {
        stopClickMonitor()
        if let observer = windowMoveObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Window Position Memory

    private func setupWindowMoveObserver() {
        windowMoveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: self,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            AppSettings.shared.saveShelfPosition(self.frame.origin)
        }
    }

    /// 在记忆位置显示（用于截图/菜单栏/快捷键触发）
    func showAtSavedPositionOrCenter() {
        if let savedPosition = AppSettings.shared.getSavedShelfPosition() {
            // 验证位置是否在屏幕内
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                var origin = savedPosition

                // 确保窗口不超出屏幕边界
                origin.x = max(screenFrame.minX, min(origin.x, screenFrame.maxX - frame.width))
                origin.y = max(screenFrame.minY, min(origin.y, screenFrame.maxY - frame.height))

                setFrameOrigin(origin)
            } else {
                setFrameOrigin(savedPosition)
            }
        } else {
            // 没有保存的位置，使用屏幕中央
            center()
        }
        showPanel()
    }
}
