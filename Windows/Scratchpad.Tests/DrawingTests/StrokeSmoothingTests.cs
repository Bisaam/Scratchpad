using Scratchpad.Drawing;
using Scratchpad.Rendering;
using Xunit;

namespace Scratchpad.Tests.DrawingTests;

public class StrokeSmoothingTests
{
    [Fact]
    public void NoPointsProducesNoSegments()
    {
        Assert.Empty(StrokeSmoothing.Segments(Array.Empty<StrokePoint>()));
    }

    [Fact]
    public void SinglePointProducesADot()
    {
        var point = new StrokePoint(1, 2);
        var segments = StrokeSmoothing.Segments(new[] { point });
        Assert.Equal(new PathSegment[] { new PathSegment.Move(point), new PathSegment.Line(point) }, segments);
    }

    [Fact]
    public void TwoPointsProduceAStraightLine()
    {
        var a = new StrokePoint(0, 0);
        var b = new StrokePoint(10, 10);
        var segments = StrokeSmoothing.Segments(new[] { a, b });
        Assert.Equal(new PathSegment[] { new PathSegment.Move(a), new PathSegment.Line(b) }, segments);
    }

    [Fact]
    public void ThreePointsProduceOneSmoothedCurveThenALineToTheEnd()
    {
        var a = new StrokePoint(0, 0);
        var b = new StrokePoint(10, 0);
        var c = new StrokePoint(20, 10);
        var segments = StrokeSmoothing.Segments(new[] { a, b, c });

        var expectedMidpoint = new StrokePoint(15, 5);
        Assert.Equal(
            new PathSegment[] { new PathSegment.Move(a), new PathSegment.QuadCurve(expectedMidpoint, b), new PathSegment.Line(c) },
            segments);
    }

    [Fact]
    public void FourPointsProduceTwoSmoothedCurvesThenALineToTheEnd()
    {
        var points = new[]
        {
            new StrokePoint(0, 0),
            new StrokePoint(10, 0),
            new StrokePoint(20, 0),
            new StrokePoint(30, 0),
        };
        var segments = StrokeSmoothing.Segments(points);

        Assert.Equal(4, segments.Count);
        Assert.Equal(new PathSegment.Move(points[0]), segments[0]);
        Assert.Equal(new PathSegment.Line(points[3]), segments[^1]);
    }
}
