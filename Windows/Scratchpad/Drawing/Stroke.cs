namespace Scratchpad.Drawing;

/// One continuous freehand pencil stroke, from mouse-down to mouse-up. A
/// class rather than a struct because `DrawingStore` appends points to the
/// in-progress stroke in place while dragging.
public sealed class Stroke
{
    /// The single fixed brush width for v0.1 (SPEC.md defers brush sizes to
    /// a later version). Recorded per-stroke so future versions can
    /// introduce per-stroke width without a data migration.
    public const double DefaultLineWidth = 4.0;

    public Guid Id { get; init; } = Guid.NewGuid();
    public List<StrokePoint> Points { get; init; } = new();
    public StrokeColor Color { get; init; } = StrokeColor.Default;
    public double LineWidth { get; init; } = DefaultLineWidth;
}
