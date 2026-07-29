namespace Scratchpad.Drawing;

/// Pure point-to-polyline distance math, used to hit-test the eraser against
/// existing strokes. Kept free of WPF so it stays testable and portable,
/// like `StrokeSmoothing`. Identical algorithm to the macOS app's
/// `StrokeGeometry`.
public static class StrokeGeometry
{
    public static double MinimumDistance(StrokePoint point, IReadOnlyList<StrokePoint> polyline)
    {
        if (polyline.Count == 0) return double.PositiveInfinity;
        if (polyline.Count == 1) return Distance(point, polyline[0]);

        var closest = double.PositiveInfinity;
        for (var index = 0; index < polyline.Count - 1; index++)
        {
            var segmentDistance = DistanceToSegment(point, polyline[index], polyline[index + 1]);
            closest = Math.Min(closest, segmentDistance);
        }
        return closest;
    }

    private static double Distance(StrokePoint a, StrokePoint b) =>
        Math.Sqrt(Math.Pow(a.X - b.X, 2) + Math.Pow(a.Y - b.Y, 2));

    private static double DistanceToSegment(StrokePoint point, StrokePoint a, StrokePoint b)
    {
        var dx = b.X - a.X;
        var dy = b.Y - a.Y;
        var lengthSquared = dx * dx + dy * dy;
        if (lengthSquared <= 0) return Distance(point, a);

        var t = Math.Max(0, Math.Min(1, ((point.X - a.X) * dx + (point.Y - a.Y) * dy) / lengthSquared));
        var projection = new StrokePoint(a.X + t * dx, a.Y + t * dy);
        return Distance(point, projection);
    }
}
