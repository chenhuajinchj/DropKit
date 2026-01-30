import SwiftUI

@main
struct DropKitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()

    var body: some Scene {
        // Menu bar app with no main window initially
        Settings {
            Text("Settings placeholder")
                .frame(width: 400, height: 300)
        }
    }
}
