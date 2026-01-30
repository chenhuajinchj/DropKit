import SwiftUI

@Observable
class AppState {
    // Global app state will be managed here
    var isShelfVisible = false

    init() {
        print("AppState initialized")
    }
}
