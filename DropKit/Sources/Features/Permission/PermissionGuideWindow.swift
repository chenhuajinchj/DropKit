import AppKit
import SwiftUI

/// 权限引导窗口
class PermissionGuideWindow: NSWindow {
    var onPermissionGranted: (() -> Void)?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        self.title = "DropKit 需要权限"
        self.center()
        self.isReleasedWhenClosed = false

        // 设置内容视图
        let guideView = PermissionGuideView(onPermissionGranted: { [weak self] in
            self?.close()
            self?.onPermissionGranted?()
        })
        self.contentView = NSHostingView(rootView: guideView)
    }

    func showWindow() {
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
