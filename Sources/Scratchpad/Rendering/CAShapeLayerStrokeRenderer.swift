import QuartzCore

/// Renders each stroke as its own `CAShapeLayer`. Once a stroke is complete
/// its layer is GPU-composited and essentially free to keep on screen;
/// while a stroke is in progress only that one layer's path is mutated,
/// rather than invalidating and redrawing the whole canvas every frame.
final class CAShapeLayerStrokeRenderer: DrawingRenderer {

    @discardableResult
    func addLayer(for stroke: Stroke, to canvasLayer: CALayer) -> CAShapeLayer {
        let layer = CAShapeLayer()
        configure(layer, for: stroke)
        canvasLayer.addSublayer(layer)
        return layer
    }

    func updateLayer(_ layer: CAShapeLayer, for stroke: Stroke) {
        configure(layer, for: stroke)
    }

    func removeAllLayers(from canvasLayer: CALayer) {
        canvasLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
    }

    private func configure(_ layer: CAShapeLayer, for stroke: Stroke) {
        layer.path = path(for: stroke.points)
        layer.strokeColor = cgColor(for: stroke.color)
        layer.fillColor = nil
        layer.lineWidth = stroke.lineWidth
        layer.lineCap = .round
        layer.lineJoin = .round
        // Strokes are drawn once and rarely change after being finalized;
        // disabling implicit animations avoids a fade-in on every point
        // appended while the user is still dragging.
        layer.actions = ["path": NSNull()]
    }

    private func path(for points: [StrokePoint]) -> CGPath {
        let path = CGMutablePath()
        for segment in StrokeSmoothing.segments(for: points) {
            switch segment {
            case .move(let point):
                path.move(to: point.cgPoint)
            case .line(let point):
                path.addLine(to: point.cgPoint)
            case .quadCurve(let point, let control):
                path.addQuadCurve(to: point.cgPoint, control: control.cgPoint)
            }
        }
        return path
    }

    private func cgColor(for color: StrokeColor) -> CGColor {
        CGColor(red: color.red, green: color.green, blue: color.blue, alpha: color.alpha)
    }
}
