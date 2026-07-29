using Scratchpad.Drawing;

namespace Scratchpad.Rendering;

/// One instruction in a smoothed stroke path. Kept as a plain, comparable
/// value rather than building a WPF `Geometry` directly so the smoothing
/// math is unit-testable without needing a WPF dispatcher or UI thread.
public abstract record PathSegment
{
    public sealed record Move(StrokePoint To) : PathSegment;

    public sealed record Line(StrokePoint To) : PathSegment;

    public sealed record QuadCurve(StrokePoint To, StrokePoint Control) : PathSegment;
}
