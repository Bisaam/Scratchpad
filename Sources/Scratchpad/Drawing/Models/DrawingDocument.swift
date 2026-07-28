import Foundation

/// The persisted state of a single display's drawing: every stroke drawn
/// since the pad was last cleared.
struct DrawingDocument: Codable, Equatable {
    var strokes: [Stroke]
    var updatedAt: Date

    static let empty = DrawingDocument(strokes: [], updatedAt: .distantPast)
}
