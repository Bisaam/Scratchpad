namespace Scratchpad.Drawing;

/// A stand-in for a UI-framework color, stored as plain component doubles so
/// drawings persist in a format with no WPF-specific types -- mirrors the
/// macOS app's `StrokeColor`, which does the same for `NSColor`.
public readonly record struct StrokeColor(double Red, double Green, double Blue, double Alpha)
{
    /// The single fixed pencil color for v0.1 (SPEC.md defers multiple
    /// colors to a later version). Recorded per-stroke so future versions
    /// can introduce per-stroke color without a data migration.
    public static readonly StrokeColor Default = new(0.98, 0.29, 0.24, 1.0);
}
