using System.Text.Json.Serialization;
using Scratchpad.Drawing;
using Scratchpad.Hotkeys;

namespace Scratchpad.Preferences;

/// All user-configurable preferences, persisted as a single unit by
/// `SettingsStore`. Every field has a sensible default in `Default` so no
/// configurable value is ever hardcoded at a call site.
public sealed record AppSettings
{
    public required KeyCombo GlobalShortcut { get; init; }
    public required double AnimationDuration { get; init; }
    public required double BackgroundDimOpacity { get; init; }
    public required DisplayMode DisplayMode { get; init; }
    public required StrokeColor StrokeColor { get; init; }
    public required double StrokeWidth { get; init; }

    /// Which screens the overlay appears on when toggled.
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public enum DisplayMode
    {
        AllDisplays,
        CurrentDisplayOnly,
    }

    /// Suggested dim-opacity presets shown in Preferences (SPEC.md: 0/15/30/50%).
    public static readonly IReadOnlyList<double> DimOpacityPresets = new[] { 0.0, 0.15, 0.30, 0.50 };

    /// The valid range for the pencil thickness slider in Preferences.
    public static readonly (double Min, double Max) StrokeWidthRange = (1, 20);

    public static readonly AppSettings Default = new()
    {
        GlobalShortcut = KeyCombo.Default,
        AnimationDuration = 0.25,
        BackgroundDimOpacity = 0.30,
        DisplayMode = DisplayMode.AllDisplays,
        StrokeColor = StrokeColor.Default,
        StrokeWidth = Stroke.DefaultLineWidth,
    };
}
