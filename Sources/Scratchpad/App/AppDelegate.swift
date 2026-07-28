import AppKit

/// Composition root: wires every dependency together on launch and tears
/// nothing down manually (the OS owns process lifetime for a menu-bar app).
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var environment: AppEnvironment?

    func applicationDidFinishLaunching(_ notification: Notification) {
        environment = AppEnvironment()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // A menu-bar-only app has no "last window" that should quit it.
        false
    }
}
