import CoreGraphics

/// A `Codable` stand-in for `CGPoint`, which does not itself conform to
/// `Codable`. Kept as plain `Double` fields so drawings persist in a format
/// with no Apple-specific types, per the project's Windows-portability goal.
struct StrokePoint: Codable, Hashable {
    var x: Double
    var y: Double

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    init(_ point: CGPoint) {
        self.x = point.x
        self.y = point.y
    }

    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}
