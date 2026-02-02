import AppKit
import KeyboardShortcuts

class AppDelegate: NSObject, NSApplicationDelegate {
    var shelfPanel: ShelfPanel?
    var clipboardHistoryPanel: ClipboardHistoryPanel?
    var permissionGuideWindow: PermissionGuideWindow?
    let dragMonitor = DragMonitor()
    let shakeDetector = ShakeDetector()
    let clipboardMonitor = ClipboardMonitor.shared
    let menuBarController = MenuBarController()
    let settingsWindowController = SettingsWindowController()
    let folderMonitor = FolderMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 菜单栏必须无条件设置，确保用户始终可以访问设置和退出
        setupMenuBar()

        #if DEBUG
        // 开发模式：跳过权限检查，直接启动
        setupApp()
        #else
        // 正式发布：检查辅助功能权限
        if PermissionChecker.checkAccessibilityPermission() {
            setupApp()
        } else {
            showPermissionGuide()
        }
        #endif
    }

    private func setupApp() {
        // 创建悬浮窗（默认隐藏）
        shelfPanel = ShelfPanel()

        // 创建剪切板历史面板
        clipboardHistoryPanel = ClipboardHistoryPanel(monitor: clipboardMonitor)

        // 启动剪切板监听
        clipboardMonitor.start()

        setupDragAndShake()
        setupKeyboardShortcuts()
        setupFolderMonitor()
    }

    private func showPermissionGuide() {
        permissionGuideWindow = PermissionGuideWindow()
        permissionGuideWindow?.onPermissionGranted = { [weak self] in
            self?.permissionGuideWindow = nil
            self?.setupApp()
        }
        permissionGuideWindow?.showWindow()
    }

    private func setupMenuBar() {
        menuBarController.onShowShelf = { [weak self] in
            self?.shelfPanel?.showAtSavedPositionOrCenter()
        }

        menuBarController.onShowClipboardHistory = { [weak self] in
            self?.clipboardHistoryPanel?.showPanel()
        }

        menuBarController.onShowSettings = { [weak self] in
            self?.settingsWindowController.showSettings()
        }

        menuBarController.onQuit = {
            NSApp.terminate(nil)
        }

        menuBarController.setup()
    }

    private func setupKeyboardShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .showShelf) { [weak self] in
            self?.shelfPanel?.showAtSavedPositionOrCenter()
        }

        KeyboardShortcuts.onKeyUp(for: .showClipboardHistory) { [weak self] in
            self?.clipboardHistoryPanel?.showPanel()
        }

        KeyboardShortcuts.onKeyUp(for: .showSettings) { [weak self] in
            self?.settingsWindowController.showSettings()
        }
    }

    private func setupDragAndShake() {
        // 拖拽开始时启动摇晃检测
        dragMonitor.onDragStart = { [weak self] in
            self?.shakeDetector.reset()
            self?.shakeDetector.start()
        }

        // 拖拽结束时停止摇晃检测
        dragMonitor.onDragEnd = { [weak self] in
            self?.shakeDetector.stop()
        }

        // 检测到摇晃时显示悬浮窗
        shakeDetector.onShake = { [weak self] in
            self?.showShelfAtMouse()
        }

        // 启动拖拽监听
        dragMonitor.start()
    }

    private func setupFolderMonitor() {
        let settings = AppSettings.shared

        // 设置新文件回调
        folderMonitor.onNewFile = { [weak self] url in
            self?.handleNewFile(url)
        }

        // 启动监听（如果已启用且有路径）
        updateFolderMonitoring()

        // 监听设置变化
        observeSettingsChanges()
    }

    private func updateFolderMonitoring() {
        let settings = AppSettings.shared

        if settings.folderMonitorEnabled, let path = settings.watchedFolderPath, !path.isEmpty {
            folderMonitor.start(path: path)
        } else {
            folderMonitor.stop()
        }
    }

    private func observeSettingsChanges() {
        let settings = AppSettings.shared

        // 使用 withObservationTracking 监听设置变化
        func observe() {
            withObservationTracking {
                _ = settings.folderMonitorEnabled
                _ = settings.watchedFolderPath
            } onChange: { [weak self] in
                DispatchQueue.main.async {
                    self?.updateFolderMonitoring()
                    observe()
                }
            }
        }
        observe()
    }

    private func handleNewFile(_ url: URL) {
        let settings = AppSettings.shared

        // 添加到悬浮窗
        shelfPanel?.viewModel.addItem(url: url)

        // 自动复制到剪切板
        if settings.autoCopyToClipboard {
            copyFileToClipboard(url)
        }

        // 自动显示悬浮窗
        if settings.autoShowShelfOnNewFile {
            shelfPanel?.showAtSavedPositionOrCenter()
        }
    }

    private func copyFileToClipboard(_ url: URL) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([url as NSURL])
    }

    private func showShelfAtMouse() {
        guard let panel = shelfPanel,
              let screen = NSScreen.main else { return }

        let mouseLocation = NSEvent.mouseLocation
        let panelSize = panel.frame.size
        let screenFrame = screen.visibleFrame
        let spacing: CGFloat = 160

        var originX = mouseLocation.x - panelSize.width / 2
        var originY: CGFloat

        // 判断鼠标在屏幕上半部分还是下半部分
        let screenMidY = screenFrame.minY + screenFrame.height / 2

        if mouseLocation.y > screenMidY {
            // 鼠标在上半部分，窗口显示在下方
            originY = mouseLocation.y - panelSize.height - spacing
        } else {
            // 鼠标在下半部分，窗口显示在上方
            originY = mouseLocation.y + spacing
        }

        // 确保窗口不超出屏幕边界
        originX = max(screenFrame.minX, min(originX, screenFrame.maxX - panelSize.width))
        originY = max(screenFrame.minY, min(originY, screenFrame.maxY - panelSize.height))

        panel.setFrameOrigin(NSPoint(x: originX, y: originY))
        panel.showPanel()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        dragMonitor.stop()
        shakeDetector.stop()
        clipboardMonitor.stop()
        folderMonitor.stop()
    }
}
