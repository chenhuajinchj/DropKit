import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var shelfPanel: ShelfPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("DropKit launched")

        // 创建悬浮窗
        shelfPanel = ShelfPanel()
        shelfPanel?.orderFront(nil)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Handle reopen if needed
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup
        print("DropKit terminating")
    }
}
