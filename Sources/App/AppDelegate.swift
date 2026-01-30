import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var shelfPanel: ShelfPanel?
    let dragMonitor = DragMonitor()
    let shakeDetector = ShakeDetector()
    let menuBarController = MenuBarController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("DropKit launched")

        // 创建悬浮窗（默认隐藏）
        shelfPanel = ShelfPanel()

        setupDragAndShake()
        setupMenuBar()
    }

    private func setupMenuBar() {
        menuBarController.onShowShelf = { [weak self] in
            self?.shelfPanel?.center()
            self?.shelfPanel?.showPanel()
        }

        menuBarController.onShowSettings = {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }

        menuBarController.onQuit = {
            NSApp.terminate(nil)
        }

        menuBarController.setup()
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
        print("DropKit terminating")
    }
}
