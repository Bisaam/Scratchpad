import AppKit

/// Shows the standard "About Scratchpad" panel from the status bar menu.
@MainActor
protocol AboutPanelPresenting {
    func present()
}

final class AboutPanelPresenter: AboutPanelPresenting {
    func present() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [:])
    }
}
