import Foundation

/// All user-configurable preferences, persisted as a single unit by
/// `SettingsStore`. Every field has a sensible default in `defaultValue` so
/// no configurable value is ever hardcoded at a call site.
struct AppSettings: Codable, Equatable {
    var globalShortcut: KeyCombo
    var animationDuration: TimeInterval
    var backgroundDimOpacity: Double
    var displayMode: DisplayMode
    var strokeColor: StrokeColor
    var strokeWidth: Double

    /// Which screens the overlay appears on when toggled.
    ///
    /// SPEC.md is internally inconsistent about which of these is the "v1"
    /// default (its Multi-Monitor section names `.allDisplays` as the
    /// initial behavior; its Preferences list names "current display" as
    /// primary and "all displays" as future). Resolved by shipping both as a
    /// live preference now, defaulting to `.allDisplays` per the
    /// Multi-Monitor section.
    enum DisplayMode: String, Codable {
        case allDisplays
        case currentDisplayOnly
    }

    /// Suggested dim-opacity presets shown in Preferences (SPEC.md: 0/15/30/50%).
    static let dimOpacityPresets: [Double] = [0.0, 0.15, 0.30, 0.50]

    /// The valid range for the pencil thickness slider in Preferences.
    static let strokeWidthRange: ClosedRange<Double> = 1...20

    static let defaultValue = AppSettings(
        globalShortcut: .default,
        animationDuration: 0.25,
        backgroundDimOpacity: 0.30,
        displayMode: .allDisplays,
        strokeColor: .default,
        strokeWidth: Stroke.defaultLineWidth
    )
}
