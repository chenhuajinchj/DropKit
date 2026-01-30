import AppKit
import SwiftUI

class ShelfPanel: NSPanel {

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 400),
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
        let visualEffect = NSVisualEffectView(frame: contentView?.bounds ?? .zero)
        visualEffect.autoresizingMask = [.width, .height]
        visualEffect.blendingMode = .behindWindow
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 12
        visualEffect.layer?.masksToBounds = true

        contentView?.addSubview(visualEffect)

        // 居中显示
        center()
    }

    // 允许成为 key window（接收键盘事件）
    override var canBecomeKey: Bool { true }

    // 点击外部不自动关闭
    override var canBecomeMain: Bool { false }
}
