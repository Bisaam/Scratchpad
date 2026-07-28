import Observation

/// Whether the overlay is currently shown, and nothing else. Deliberately
/// minimal: no drawing data lives here, and no fading-in-progress
/// bookkeeping either (that is a private implementation detail of
/// `OverlayWindowController`). Keeping this to a single fact is what makes
/// overlay visibility and drawing content genuinely independent, per
/// CLAUDE.md's requirement that they never be coupled.
@Observable
final class OverlayState {
    private(set) var isVisible: Bool = false

    func setVisible(_ visible: Bool) {
        isVisible = visible
    }
}
