import CoreGraphics
import Foundation
import Observation

/// Owns the strokes for a single display: the freehand drawing business
/// logic, with no knowledge of whether or how it is currently rendered, and
/// no knowledge of whether the overlay is visible. Overlay visibility and
/// drawing content are deliberately independent (see OverlayState).
@Observable
final class DrawingStore {
    private(set) var strokes: [Stroke]
    private(set) var strokeInProgress: Stroke?

    private let display: DisplayIdentifier
    private let repository: DrawingRepository
    private var defaultColor: StrokeColor
    private var defaultLineWidth: Double
    private let saveDebounceInterval: TimeInterval
    private var pendingSave: DispatchWorkItem?

    init(
        display: DisplayIdentifier,
        repository: DrawingRepository,
        defaultColor: StrokeColor = .default,
        defaultLineWidth: Double = Stroke.defaultLineWidth,
        saveDebounceInterval: TimeInterval = 0.5
    ) {
        self.display = display
        self.repository = repository
        self.defaultColor = defaultColor
        self.defaultLineWidth = defaultLineWidth
        self.saveDebounceInterval = saveDebounceInterval
        self.strokes = repository.load(for: display).strokes
    }

    /// Applied to strokes started from now on, not to strokes already
    /// drawn -- so changing the pencil color/thickness in Preferences never
    /// rewrites history, only affects what you draw next.
    func updateDefaultStyle(color: StrokeColor, lineWidth: Double) {
        defaultColor = color
        defaultLineWidth = lineWidth
    }

    func beginStroke(at point: CGPoint) {
        strokeInProgress = Stroke(
            points: [StrokePoint(point)],
            color: defaultColor,
            lineWidth: defaultLineWidth
        )
    }

    func appendPoint(_ point: CGPoint) {
        strokeInProgress?.points.append(StrokePoint(point))
    }

    func endStroke() {
        defer { strokeInProgress = nil }
        guard let stroke = strokeInProgress, !stroke.points.isEmpty else { return }
        strokes.append(stroke)
        scheduleSave()
    }

    func clear() {
        strokes.removeAll()
        strokeInProgress = nil
        scheduleSave()
    }

    /// Removes every *whole* stroke passing within `tolerance` of `point`
    /// (plus that stroke's own half-width, so thicker strokes are easier to
    /// touch), and returns their ids so the caller can remove the matching
    /// rendered layers. There is no partial/pixel erasing in v0.1.
    @discardableResult
    func removeStrokes(touching point: CGPoint, tolerance: Double) -> [Stroke.ID] {
        let matches = strokes.filter { stroke in
            StrokeGeometry.minimumDistance(from: point, toPolylineThrough: stroke.points) <= tolerance + stroke.lineWidth / 2
        }
        guard !matches.isEmpty else { return [] }

        let matchedIDs = Set(matches.map(\.id))
        strokes.removeAll { matchedIDs.contains($0.id) }
        scheduleSave()
        return matches.map(\.id)
    }

    /// Debounced so a long stroke with hundreds of points, or "Clear Pad"
    /// hit repeatedly, does not write to disk more than a few times a
    /// second -- there is no need for every mutation to hit the filesystem.
    private func scheduleSave() {
        pendingSave?.cancel()
        let strokesToSave = strokes
        let workItem = DispatchWorkItem { [repository, display] in
            try? repository.save(DrawingDocument(strokes: strokesToSave, updatedAt: Date()), for: display)
        }
        pendingSave = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + saveDebounceInterval, execute: workItem)
    }
}
