import AppKit

/// The menu bar icon and its menu (SPEC.md: "Menu bar icon only. No Dock
/// icon by default."). Built on raw `NSStatusItem`/`NSMenu` rather than
/// SwiftUI's `MenuBarExtra` for precise control over the dynamic
/// Show/Hide label and the Launch at Login checkbox state.
@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let overlayCoordinator: OverlayCoordinator
    private let launchAtLoginService: LaunchAtLoginService
    private let preferencesWindowController: PreferencesWindowController
    private let aboutPanelPresenter: AboutPanelPresenting

    private let toggleOverlayItem = NSMenuItem()
    private let launchAtLoginItem = NSMenuItem()

    init(
        overlayCoordinator: OverlayCoordinator,
        launchAtLoginService: LaunchAtLoginService,
        preferencesWindowController: PreferencesWindowController,
        aboutPanelPresenter: AboutPanelPresenting
    ) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.overlayCoordinator = overlayCoordinator
        self.launchAtLoginService = launchAtLoginService
        self.preferencesWindowController = preferencesWindowController
        self.aboutPanelPresenter = aboutPanelPresenter
        super.init()
        configureStatusItem()
    }

    private func configureStatusItem() {
        statusItem.button?.image = NSImage(
            systemSymbolName: "pencil.tip.crop.circle",
            accessibilityDescription: "Scratchpad"
        )

        let menu = NSMenu()
        menu.delegate = self

        toggleOverlayItem.target = self
        toggleOverlayItem.action = #selector(toggleOverlay)
        menu.addItem(toggleOverlayItem)

        let clearItem = NSMenuItem(title: "Clear Pad", action: #selector(clearPad), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)

        menu.addItem(.separator())

        let preferencesItem = NSMenuItem(
            title: "Preferences…",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        preferencesItem.target = self
        menu.addItem(preferencesItem)

        launchAtLoginItem.title = "Launch at Login"
        launchAtLoginItem.target = self
        launchAtLoginItem.action = #selector(toggleLaunchAtLogin)
        menu.addItem(launchAtLoginItem)

        menu.addItem(.separator())

        let aboutItem = NSMenuItem(title: "About Scratchpad", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        let quitItem = NSMenuItem(title: "Quit Scratchpad", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    /// Refreshes state that can change outside the menu (overlay visibility,
    /// login item status) right before the menu is shown, rather than
    /// polling on a timer.
    func menuWillOpen(_ menu: NSMenu) {
        toggleOverlayItem.title = overlayCoordinator.overlayState.isVisible ? "Hide Scratchpad" : "Show Scratchpad"
        launchAtLoginItem.state = launchAtLoginService.isEnabled ? .on : .off
    }

    @objc private func toggleOverlay() {
        overlayCoordinator.toggle()
    }

    @objc private func clearPad() {
        overlayCoordinator.clearAll()
    }

    @objc private func openPreferences() {
        preferencesWindowController.show()
    }

    @objc private func toggleLaunchAtLogin() {
        try? launchAtLoginService.setEnabled(!launchAtLoginService.isEnabled)
    }

    @objc private func showAbout() {
        aboutPanelPresenter.present()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
