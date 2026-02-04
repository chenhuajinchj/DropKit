import AppKit
import SwiftUI

/// 支持第一次点击就能操作的 NSView
private class FirstClickContentView: NSView {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}

class ClipboardHistoryPanel: NSPanel {
    let monitor: ClipboardMonitor
    private var clickMonitor: Any?

    init(monitor: ClipboardMonitor) {
        self.monitor = monitor
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 400),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        setupPanel()
    }

    private func setupPanel() {
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isOpaque = false
        backgroundColor = .clear
        hidesOnDeactivate = false

        // 毛玻璃背景
        let visualEffect = NSVisualEffectView()
        visualEffect.translatesAutoresizingMaskIntoConstraints = false
        visualEffect.blendingMode = .behindWindow
        visualEffect.material = .menu
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 10
        visualEffect.layer?.masksToBounds = true

        contentView = FirstClickContentView(frame: NSRect(x: 0, y: 0, width: 300, height: 400))
        contentView?.addSubview(visualEffect)

        NSLayoutConstraint.activate([
            visualEffect.topAnchor.constraint(equalTo: contentView!.topAnchor),
            visualEffect.bottomAnchor.constraint(equalTo: contentView!.bottomAnchor),
            visualEffect.leadingAnchor.constraint(equalTo: contentView!.leadingAnchor),
            visualEffect.trailingAnchor.constraint(equalTo: contentView!.trailingAnchor)
        ])

        // SwiftUI 视图
        let hostingView = NSHostingView(rootView: ClipboardHistoryView(monitor: monitor, onClose: { [weak self] in
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

        center()
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func showPanel() {
        center()
        makeKeyAndOrderFront(nil)
        startClickMonitor()
    }

    func hidePanel() {
        stopClickMonitor()
        orderOut(nil)
    }

    private func startClickMonitor() {
        stopClickMonitor()
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self, self.isVisible else { return }
            if !self.frame.contains(NSEvent.mouseLocation) {
                self.hidePanel()
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
