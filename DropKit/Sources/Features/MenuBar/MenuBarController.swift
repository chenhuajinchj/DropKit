import AppKit
import Carbon.HIToolbox

class MenuBarController {
    private var statusItem: NSStatusItem?
    private var globalKeyMonitor: Any?

    var onShowShelf: (() -> Void)?
    var onShowClipboardHistory: (() -> Void)?
    var onShowSettings: (() -> Void)?
    var onQuit: (() -> Void)?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "tray.fill", accessibilityDescription: "DropKit")
        }

        setupMenu()
        setupGlobalHotkeys()
    }

    private func setupMenu() {
        let menu = NSMenu()

        // 显示悬浮窗
        let showShelfItem = NSMenuItem(title: "显示悬浮窗", action: #selector(showShelf), keyEquivalent: "s")
        showShelfItem.keyEquivalentModifierMask = [.command, .shift]
        showShelfItem.target = self
        menu.addItem(showShelfItem)

        // 剪切板历史
        let clipboardItem = NSMenuItem(title: "剪切板历史", action: #selector(showClipboardHistory), keyEquivalent: "v")
        clipboardItem.keyEquivalentModifierMask = [.command, .shift]
        clipboardItem.target = self
        menu.addItem(clipboardItem)

        menu.addItem(NSMenuItem.separator())

        // 设置
        let settingsItem = NSMenuItem(title: "设置...", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        // 关于
        let aboutItem = NSMenuItem(title: "关于 DropKit", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        // 退出
        let quitItem = NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func showShelf() {
        onShowShelf?()
    }

    @objc private func showClipboardHistory() {
        onShowClipboardHistory?()
    }

    @objc private func showSettings() {
        onShowSettings?()
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func quit() {
        onQuit?()
    }

    // MARK: - Global Hotkeys

    private func setupGlobalHotkeys() {
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleGlobalKeyEvent(event)
        }
    }

    private func handleGlobalKeyEvent(_ event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // ⌘⇧S - 显示悬浮窗
        if modifiers == [.command, .shift] && event.keyCode == UInt16(kVK_ANSI_S) {
            onShowShelf?()
        }

        // ⌘⇧V - 剪切板历史
        if modifiers == [.command, .shift] && event.keyCode == UInt16(kVK_ANSI_V) {
            onShowClipboardHistory?()
        }
    }

    deinit {
        if let monitor = globalKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
