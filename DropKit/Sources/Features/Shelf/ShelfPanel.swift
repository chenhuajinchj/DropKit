import AppKit
import SwiftUI
import Combine

class ShelfPanel: NSPanel {
    let viewModel = ShelfViewModel()
    private var clickMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

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
            self?.hidePanel()
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
            while !Task.isCancelled {
                let currentState = viewModel.viewState
                let hasItems = !viewModel.items.isEmpty

                withObservationTracking {
                    _ = viewModel.viewState
                    _ = viewModel.items.count
                } onChange: {
                    Task { @MainActor in
                        self.updatePanelSize()
                    }
                }

                // 初始更新
                updatePanelSize()

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
        orderFront(nil)
        startClickMonitor()
    }

    func hidePanel() {
        stopClickMonitor()
        orderOut(nil)
    }

    private func startClickMonitor() {
        stopClickMonitor()
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.isVisible else { return }
            let screenLocation = NSEvent.mouseLocation

            // 检查点击是否在窗口外部
            if !self.frame.contains(screenLocation) {
                // 只有悬浮窗为空时才关闭
                if self.viewModel.items.isEmpty {
                    self.hidePanel()
                }
            }
        }
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
