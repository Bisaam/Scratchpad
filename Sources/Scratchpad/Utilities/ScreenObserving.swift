import AppKit

/// Wraps `NSScreen.screens` and screen-configuration-change notifications
/// behind a protocol, so `OverlayCoordinator`'s multi-monitor logic is
/// testable without real displays.
@MainActor
protocol ScreenObserving {
    var screens: [NSScreen] { get }

    @discardableResult
    func observeScreenChanges(_ handler: @escaping @MainActor () -> Void) -> AnyObject
}

final class NSScreenObserver: ScreenObserving {
    var screens: [NSScreen] {
        NSScreen.screens
    }

    @discardableResult
    func observeScreenChanges(_ handler: @escaping @MainActor () -> Void) -> AnyObject {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { _ in
            // `queue: .main` guarantees this runs on the main thread, but
            // the closure type NotificationCenter expects is not itself
            // statically isolated, so assert what we already know to be true.
            MainActor.assumeIsolated { handler() }
        }
    }
}
