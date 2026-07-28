import SwiftUI

@main
struct ScratchpadApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        _ = DevSmokeTest.runIfRequested()
    }

    var body: some Scene {
        // Scratchpad is a menu-bar-only (LSUIElement) app: the overlay, status
        // bar item, and preferences window are all managed directly by
        // AppDelegate/AppEnvironment. SwiftUI requires at least one Scene, so
        // this empty Settings scene exists only to satisfy that requirement
        // and is never populated or shown.
        Settings {
            EmptyView()
        }
    }
}
