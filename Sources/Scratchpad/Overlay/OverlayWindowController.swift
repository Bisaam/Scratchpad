import AppKit

/// Owns one display's overlay window, its dim backdrop, and its drawing
/// canvas. `OverlayCoordinator` is the only thing that talks to instances
/// of this class; it never reaches into `DrawingStore` itself.
final class OverlayWindowController: NSWindowController {
    let display: DisplayIdentifier

    private let dimView: DimBackgroundView
    private let canvasView: DrawingCanvasView
    private let animator: OverlayFadeAnimator

    init(
        screen: NSScreen,
        display: DisplayIdentifier,
        drawingStore: DrawingStore,
        renderer: DrawingRenderer,
        animator: OverlayFadeAnimator
    ) {
        self.display = display
        self.animator = animator
        self.dimView = DimBackgroundView()
        self.canvasView = DrawingCanvasView(store: drawingStore, renderer: renderer)

        let window = OverlayWindow(screen: screen)
        super.init(window: window)

        guard let contentView = window.contentView else { return }
        dimView.frame = contentView.bounds
        dimView.autoresizingMask = [.width, .height]
        canvasView.frame = contentView.bounds
        canvasView.autoresizingMask = [.width, .height]
        contentView.addSubview(dimView)
        contentView.addSubview(canvasView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func updateFrame(to frame: CGRect) {
        window?.setFrame(frame, display: true)
    }

    func updateDimOpacity(_ opacity: Double) {
        dimView.dimOpacity = opacity
    }

    func show(duration: TimeInterval) {
        guard let window else { return }
        window.orderFrontRegardless()
        animator.fadeIn(window, duration: duration)
    }

    func hide(duration: TimeInterval) {
        guard let window else { return }
        animator.fadeOut(window, duration: duration) {
            window.orderOut(nil)
        }
    }

    /// Erases this display's drawing. Never touches overlay visibility.
    func clearDrawing() {
        canvasView.clearDrawing()
    }
}
