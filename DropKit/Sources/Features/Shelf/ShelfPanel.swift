import AppKit
import SwiftUI
import Combine

class ShelfPanel: NSPanel {
    let viewModel = ShelfViewModel()
    private var clickMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    private var isDocked = false

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        setupPanel()
        observeViewState()
    }

    private func setupPanel() {
        // 浮在所有窗口之上
        level = .floating

        // 可以出现在所有空间和全屏应用上
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // 透明背景（为毛玻璃效果准备）
        isOpaque = false
        backgroundColor = .clear

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
        visualEffect.layer?.cornerRadius = 12
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
        // 使用 withObservationTracking 监听 viewModel 变化
        Task { @MainActor in
            var previousItemCount = viewModel.items.count

            while !Task.isCancelled {
                withObservationTracking {
                    _ = viewModel.viewState
                    _ = viewModel.items.count
                } onChange: {
                    Task { @MainActor in
                        self.updatePanelSize()

                        // 文件全部拖出后自动关闭
                        if self.viewModel.items.isEmpty && self.isVisible {
                            self.hidePanel()
                        }
                    }
                }

                // 初始更新
                updatePanelSize()
                previousItemCount = viewModel.items.count

                // 等待变化
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            }
        }
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
        orderFront(nil)
        startClickMonitor()
    }

    func hidePanel() {
        stopClickMonitor()
        orderOut(nil)
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

        // 判断窗口在屏幕左半边还是右半边
        let screenCenter = screenFrame.midX
        let dockToLeft = windowCenter < screenCenter

        // 计算目标位置（保持 Y 坐标不变）
        let targetX: CGFloat
        if dockToLeft {
            targetX = screenFrame.minX
        } else {
            targetX = screenFrame.maxX - frame.width
        }

        let targetOrigin = NSPoint(x: targetX, y: frame.origin.y)

        // 用动画滑动到边缘
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().setFrameOrigin(targetOrigin)
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
    }
}
