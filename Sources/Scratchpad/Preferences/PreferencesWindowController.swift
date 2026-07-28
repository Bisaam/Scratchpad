import AppKit
import SwiftUI

/// AppKit shell hosting the SwiftUI `PreferencesView`. The window itself is
/// plain `NSWindowController` management; only its content is SwiftUI.
final class PreferencesWindowController: NSWindowController {
    init(settingsStore: SettingsStore, launchAtLoginService: LaunchAtLoginService) {
        let hostingController = NSHostingController(
            rootView: PreferencesView(settingsStore: settingsStore, launchAtLoginService: launchAtLoginService)
        )
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Scratchpad Preferences"
        window.styleMask = [.titled, .closable]
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func show() {
        window?.center()
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
