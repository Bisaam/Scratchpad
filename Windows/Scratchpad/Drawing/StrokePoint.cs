namespace Scratchpad.Drawing;

/// A plain point, kept independent of any UI-framework point type so
/// drawings persist in a format with no WPF-specific types.
public readonly record struct StrokePoint(double X, double Y)
{
    public static StrokePoint FromWindowsPoint(System.Windows.Point point) => new(point.X, point.Y);

    public System.Windows.Point ToWindowsPoint() => new(X, Y);
}
