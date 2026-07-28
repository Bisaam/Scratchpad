import QuartzCore

/// Renders strokes as layers on a host `CALayer`, keeping the drawing
/// canvas's event handling (`DrawingCanvasView`) separate from how a stroke
/// actually becomes pixels. A future Windows port re-implements this
/// protocol against its own rendering surface; `StrokeSmoothing`, the only
/// part of the math involved, is already platform-agnostic.
protocol DrawingRenderer {
    /// Adds a new layer for a completed stroke and returns it, so the caller
    /// can keep updating it while the stroke is still in progress.
    @discardableResult
    func addLayer(for stroke: Stroke, to canvasLayer: CALayer) -> CAShapeLayer

    /// Re-renders an existing stroke's layer, called repeatedly while the
    /// user is still dragging.
    func updateLayer(_ layer: CAShapeLayer, for stroke: Stroke)

    /// Removes every stroke layer, for "Clear Pad".
    func removeAllLayers(from canvasLayer: CALayer)
}
