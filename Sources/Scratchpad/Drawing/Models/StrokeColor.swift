/// A `Codable` stand-in for `NSColor`/`Color`, stored as plain component
/// doubles so drawings persist in a format with no Apple-specific types.
struct StrokeColor: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    /// The single fixed pencil color for v0.1 (SPEC.md defers multiple
    /// colors to a later version). Recorded per-stroke so future versions
    /// can introduce per-stroke color without a data migration.
    static let `default` = StrokeColor(red: 0.98, green: 0.29, blue: 0.24, alpha: 1.0)
}
