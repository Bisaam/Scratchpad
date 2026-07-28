/// One instruction in a smoothed stroke path. Kept as a plain, `Equatable`
/// value rather than building a `CGPath` directly so the smoothing math is
/// unit-testable without needing to introspect Core Graphics internals.
enum PathSegment: Equatable {
    case move(to: StrokePoint)
    case line(to: StrokePoint)
    case quadCurve(to: StrokePoint, control: StrokePoint)
}

/// Turns raw mouse-tracked points into a smoothed path by drawing a
/// quadratic curve through the midpoint of each consecutive pair, using the
/// shared point as the curve's control point. This is the standard
/// technique for smoothing freehand input without needing to buffer and
/// re-process the whole stroke on every new point.
enum StrokeSmoothing {
    static func segments(for points: [StrokePoint]) -> [PathSegment] {
        guard let first = points.first else { return [] }
        guard points.count > 1 else {
            // A single point (a tap, not a drag) still needs to render as a
            // dot: a zero-length line with a round cap draws one.
            return [.move(to: first), .line(to: first)]
        }

        var segments: [PathSegment] = [.move(to: first)]
        for index in 1..<(points.count - 1) {
            let current = points[index]
            let next = points[index + 1]
            let midpoint = StrokePoint(x: (current.x + next.x) / 2, y: (current.y + next.y) / 2)
            segments.append(.quadCurve(to: midpoint, control: current))
        }
        segments.append(.line(to: points[points.count - 1]))
        return segments
    }
}
