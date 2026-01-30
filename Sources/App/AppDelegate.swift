import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // App initialization
        print("DropKit launched")
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
