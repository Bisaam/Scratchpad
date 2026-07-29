using Scratchpad.Drawing;

namespace Scratchpad.Rendering;

/// Turns raw mouse-tracked points into a smoothed path by drawing a
/// quadratic curve through the midpoint of each consecutive pair, using the
/// shared point as the curve's control point. This is the standard
/// technique for smoothing freehand input without needing to buffer and
/// re-process the whole stroke on every new point. Identical algorithm to
/// the macOS app's `StrokeSmoothing`.
public static class StrokeSmoothing
{
    public static IReadOnlyList<PathSegment> Segments(IReadOnlyList<StrokePoint> points)
    {
        if (points.Count == 0) return Array.Empty<PathSegment>();

        var first = points[0];
        if (points.Count == 1)
        {
            // A single point (a tap, not a drag) still needs to render as a
            // dot: a zero-length line with a round cap draws one.
            return new PathSegment[] { new PathSegment.Move(first), new PathSegment.Line(first) };
        }

        var segments = new List<PathSegment> { new PathSegment.Move(first) };
        for (var index = 1; index < points.Count - 1; index++)
        {
            var current = points[index];
            var next = points[index + 1];
            var midpoint = new StrokePoint((current.X + next.X) / 2, (current.Y + next.Y) / 2);
            segments.Add(new PathSegment.QuadCurve(midpoint, current));
        }
        segments.Add(new PathSegment.Line(points[^1]));
        return segments;
    }
}
