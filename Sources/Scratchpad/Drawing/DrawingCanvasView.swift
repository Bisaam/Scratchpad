import AppKit

/// The freehand drawing surface: tracks mouse events and turns them into
/// `DrawingStore` mutations, delegating the actual pixels to a
/// `DrawingRenderer`. Held directly in the overlay window's content view,
/// not wrapped in SwiftUI, so 60fps freehand input never goes through a
/// SwiftUI view-diffing pass.
final class DrawingCanvasView: NSView {
    /// How close the eraser needs to pass to a stroke's path (in addition to
    /// that stroke's own half-width) to erase it.
    private static let eraserHitTestTolerance: Double = 8

    private let store: DrawingStore
    private let renderer: DrawingRenderer
    private var inProgressLayer: CAShapeLayer?
    private var layersByStrokeID: [Stroke.ID: CAShapeLayer] = [:]

    init(store: DrawingStore, renderer: DrawingRenderer) {
        self.store = store
        self.renderer = renderer
        super.init(frame: .zero)
        wantsLayer = true
        renderExistingStrokes()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var acceptsFirstResponder: Bool { false }

    override func resetCursorRects() {
        discardCursorRects()
        addCursorRect(bounds, cursor: PencilCursor.cursor)
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        store.beginStroke(at: point)
        guard let layer, let stroke = store.strokeInProgress else { return }
        inProgressLayer = renderer.addLayer(for: stroke, to: layer)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let inProgressLayer, let stroke = updatedStrokeInProgress(with: event) else { return }
        renderer.updateLayer(inProgressLayer, for: stroke)
    }

    override func mouseUp(with event: NSEvent) {
        if let inProgressLayer, let stroke = updatedStrokeInProgress(with: event) {
            renderer.updateLayer(inProgressLayer, for: stroke)
            layersByStrokeID[stroke.id] = inProgressLayer
        }
        store.endStroke()
        inProgressLayer = nil
    }

    /// Holding right-click and dragging over a line erases that whole
    /// stroke -- there is no partial/pixel erasing in v0.1.
    override func rightMouseDown(with event: NSEvent) {
        eraseStrokes(at: convert(event.locationInWindow, from: nil))
    }

    override func rightMouseDragged(with event: NSEvent) {
        eraseStrokes(at: convert(event.locationInWindow, from: nil))
    }

    /// Erases every stroke, both the persisted list and whatever is
    /// currently on screen. Overlay visibility is untouched by this call.
    func clearDrawing() {
        store.clear()
        if let layer {
            renderer.removeAllLayers(from: layer)
        }
        layersByStrokeID.removeAll()
    }

    private func eraseStrokes(at point: CGPoint) {
        let erasedIDs = store.removeStrokes(touching: point, tolerance: Self.eraserHitTestTolerance)
        for id in erasedIDs {
            layersByStrokeID.removeValue(forKey: id)?.removeFromSuperlayer()
        }
    }

    private func updatedStrokeInProgress(with event: NSEvent) -> Stroke? {
        let point = convert(event.locationInWindow, from: nil)
        store.appendPoint(point)
        return store.strokeInProgress
    }

    private func renderExistingStrokes() {
        guard let layer else { return }
        for stroke in store.strokes {
            layersByStrokeID[stroke.id] = renderer.addLayer(for: stroke, to: layer)
        }
    }
}
