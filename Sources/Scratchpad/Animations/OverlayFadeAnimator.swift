import AppKit

/// Fades an `NSWindow` in or out. A protocol so `OverlayWindowController`
/// can be tested without a real animation running.
@MainActor
protocol OverlayFadeAnimator {
    func fadeIn(_ window: NSWindow, duration: TimeInterval)
    func fadeOut(_ window: NSWindow, duration: TimeInterval, completion: @escaping @MainActor () -> Void)
}

/// Animates via `NSAnimationContext`, matching the subtle ease-in/ease-out
/// timing AppKit uses for its own window and view animations.
final class NSAnimationContextFadeAnimator: OverlayFadeAnimator {
    func fadeIn(_ window: NSWindow, duration: TimeInterval) {
        window.alphaValue = 0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 1
        }
    }

    func fadeOut(_ window: NSWindow, duration: TimeInterval, completion: @escaping @MainActor () -> Void) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 0
        } completionHandler: {
            // NSAnimationContext runs its completion handler on the main
            // thread, but the closure type it expects is not itself
            // statically isolated, so assert what we already know to be true.
            MainActor.assumeIsolated { completion() }
        }
    }
}
