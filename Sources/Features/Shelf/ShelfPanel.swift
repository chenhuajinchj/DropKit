import AppKit
import SwiftUI

class ShelfPanel: NSPanel {

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 180, height: 220),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        setupPanel()
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

        // 添加毛玻璃背景视图
        let visualEffect = NSVisualEffectView()
        visualEffect.translatesAutoresizingMaskIntoConstraints = false
        visualEffect.blendingMode = .behindWindow
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 12
        visualEffect.layer?.masksToBounds = true

        contentView?.addSubview(visualEffect)

        // visualEffect 约束到 contentView
        if let contentView = contentView {
            NSLayoutConstraint.activate([
                visualEffect.topAnchor.constraint(equalTo: contentView.topAnchor),
                visualEffect.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                visualEffect.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                visualEffect.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
            ])
        }

        // 嵌入 SwiftUI 视图到毛玻璃视图内部
        let hostingView = NSHostingView(rootView: ShelfView())
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

    // 允许成为 key window（接收键盘事件）
    override var canBecomeKey: Bool { true }

    // 点击外部不自动关闭
    override var canBecomeMain: Bool { false }
}
