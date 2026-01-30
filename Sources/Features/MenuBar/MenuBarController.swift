import AppKit

class MenuBarController {
    private var statusItem: NSStatusItem?

    var onShowShelf: (() -> Void)?
    var onShowSettings: (() -> Void)?
    var onQuit: (() -> Void)?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "tray.fill", accessibilityDescription: "DropKit")
        }

        setupMenu()
    }

    private func setupMenu() {
        let menu = NSMenu()

        // 显示悬浮窗
        let showShelfItem = NSMenuItem(title: "显示悬浮窗", action: #selector(showShelf), keyEquivalent: "s")
        showShelfItem.keyEquivalentModifierMask = [.command, .shift]
        showShelfItem.target = self
        menu.addItem(showShelfItem)

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

    @objc private func showSettings() {
        onShowSettings?()
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func quit() {
        onQuit?()
    }
}
