import AppKit
import CoreGraphics

/// The fullscreen, transparent, always-on-top window shown on one display.
///
/// Uses `.nonactivatingPanel` and refuses key/main status so the overlay
/// never steals keyboard focus from whatever app was frontmost -- it only
/// needs mouse events for drawing. `.fullScreenAuxiliary` alongside
/// `.canJoinAllSpaces` is required for the window to stay above another
/// app's fullscreen Space, not just the current one.
///
/// The window level sits one below the system Dock's, so the overlay
/// stays above every regular app window but the Dock and menu bar (which
/// sit even higher) remain visible and clickable on top of it -- entering
/// drawing mode should not hide them.
final class OverlayWindow: NSPanel {
    init(screen: NSScreen) {
        // NSWindow determines which screen it belongs to from
        // `contentRect`'s origin, so passing `screen.frame` here is enough;
        // the `screen:` convenience initializer is not a designated
        // initializer and cannot be called from a subclass.
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isReleasedWhenClosed = false
        ignoresMouseEvents = false
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.dockWindow)) - 1)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        alphaValue = 0
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
