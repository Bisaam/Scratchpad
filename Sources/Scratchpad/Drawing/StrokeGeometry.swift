import CoreGraphics

/// Pure point-to-polyline distance math, used to hit-test the eraser
/// against existing strokes. Kept free of AppKit so it stays testable and
/// portable, like `StrokeSmoothing`.
enum StrokeGeometry {
    static func minimumDistance(from point: CGPoint, toPolylineThrough points: [StrokePoint]) -> Double {
        guard let first = points.first else { return .infinity }
        guard points.count > 1 else { return distance(point, first.cgPoint) }

        var closest = Double.infinity
        for index in 0..<(points.count - 1) {
            let segmentDistance = distance(point, toSegmentFrom: points[index].cgPoint, to: points[index + 1].cgPoint)
            closest = min(closest, segmentDistance)
        }
        return closest
    }

    private static func distance(_ a: CGPoint, _ b: CGPoint) -> Double {
        Double(hypot(a.x - b.x, a.y - b.y))
    }

    private static func distance(_ point: CGPoint, toSegmentFrom a: CGPoint, to b: CGPoint) -> Double {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let lengthSquared = dx * dx + dy * dy
        guard lengthSquared > 0 else { return distance(point, a) }

        let t = max(0, min(1, ((point.x - a.x) * dx + (point.y - a.y) * dy) / lengthSquared))
        let projection = CGPoint(x: a.x + t * dx, y: a.y + t * dy)
        return distance(point, projection)
    }
}
