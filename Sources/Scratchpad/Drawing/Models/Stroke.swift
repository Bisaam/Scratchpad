import Foundation

/// One continuous freehand pencil stroke, from mouse-down to mouse-up.
struct Stroke: Codable, Identifiable, Hashable {
    var id: UUID
    var points: [StrokePoint]
    var color: StrokeColor
    var lineWidth: Double

    /// The single fixed brush width for v0.1 (SPEC.md defers brush sizes to
    /// a later version). Recorded per-stroke so future versions can
    /// introduce per-stroke width without a data migration.
    static let defaultLineWidth: Double = 4.0

    init(
        id: UUID = UUID(),
        points: [StrokePoint] = [],
        color: StrokeColor = .default,
        lineWidth: Double = Stroke.defaultLineWidth
    ) {
        self.id = id
        self.points = points
        self.color = color
        self.lineWidth = lineWidth
    }
}
