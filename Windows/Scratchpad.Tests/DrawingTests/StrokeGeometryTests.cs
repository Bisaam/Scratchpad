using Scratchpad.Drawing;
using Xunit;

namespace Scratchpad.Tests.DrawingTests;

public class StrokeGeometryTests
{
    [Fact]
    public void EmptyPolylineIsInfinitelyFar()
    {
        var distance = StrokeGeometry.MinimumDistance(new StrokePoint(0, 0), Array.Empty<StrokePoint>());
        Assert.True(double.IsPositiveInfinity(distance));
    }

    [Fact]
    public void MissesAPointFarFromAnySegment()
    {
        var polyline = new[] { new StrokePoint(0, 0), new StrokePoint(10, 0) };
        var distance = StrokeGeometry.MinimumDistance(new StrokePoint(0, 100), polyline);
        Assert.Equal(100, distance, precision: 6);
    }

    [Fact]
    public void FindsTheClosestOfMultipleSegments()
    {
        var polyline = new[] { new StrokePoint(0, 0), new StrokePoint(10, 0), new StrokePoint(10, 10) };
        var distance = StrokeGeometry.MinimumDistance(new StrokePoint(11, 5), polyline);
        Assert.Equal(1, distance, precision: 6);
    }
}
