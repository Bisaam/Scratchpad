namespace Scratchpad.Drawing;

/// The persisted state of a single display's drawing: every stroke drawn
/// since the pad was last cleared.
public sealed class DrawingDocument
{
    public List<Stroke> Strokes { get; init; } = new();
    public DateTimeOffset UpdatedAt { get; init; } = DateTimeOffset.MinValue;

    public static DrawingDocument Empty => new();
}
