using Scratchpad.Drawing;

namespace Scratchpad.Preferences;

/// Bridges `StrokeColor` (a plain, portable RGBA value with no WPF-only
/// types) to `System.Drawing.Color`/`System.Windows.Media.Color`, for use
/// in the Preferences window's color picker button. This conversion lives
/// here, at the UI edge, rather than on `StrokeColor` itself, so the
/// drawing model stays framework-agnostic -- mirrors the macOS app's
/// `StrokeColor+SwiftUI.swift`.
public static class StrokeColorExtensions
{
    public static System.Drawing.Color ToDrawingColor(this StrokeColor color) => System.Drawing.Color.FromArgb(
        ToByte(color.Alpha), ToByte(color.Red), ToByte(color.Green), ToByte(color.Blue));

    public static StrokeColor ToStrokeColor(this System.Drawing.Color color) =>
        new(color.R / 255.0, color.G / 255.0, color.B / 255.0, color.A / 255.0);

    public static System.Windows.Media.Color ToMediaColor(this StrokeColor color) => System.Windows.Media.Color.FromArgb(
        ToByte(color.Alpha), ToByte(color.Red), ToByte(color.Green), ToByte(color.Blue));

    private static byte ToByte(double component) => (byte)Math.Clamp(Math.Round(component * 255), 0, 255);
}
