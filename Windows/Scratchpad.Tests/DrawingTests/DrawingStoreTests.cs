using Scratchpad.Drawing;
using Scratchpad.Overlay;
using Scratchpad.Persistence;
using Xunit;

namespace Scratchpad.Tests.DrawingTests;

internal sealed class MockDrawingRepository : IDrawingRepository
{
    public Dictionary<DisplayIdentifier, DrawingDocument> DocumentsByDisplay { get; } = new();
    public int SaveCount { get; private set; }

    public DrawingDocument Load(DisplayIdentifier display) =>
        DocumentsByDisplay.TryGetValue(display, out var document) ? document : DrawingDocument.Empty;

    public void Save(DrawingDocument document, DisplayIdentifier display)
    {
        SaveCount++;
        DocumentsByDisplay[display] = document;
    }

    public void Clear(DisplayIdentifier display) => DocumentsByDisplay.Remove(display);
}

public class DrawingStoreTests
{
    private static readonly DisplayIdentifier Display = new("\\.\\DISPLAY-TEST");

    [Fact]
    public void LoadsPersistedStrokesOnInit()
    {
        var repository = new MockDrawingRepository();
        var stroke = new Stroke { Points = { new StrokePoint(0, 0) } };
        repository.DocumentsByDisplay[Display] = new DrawingDocument { Strokes = { stroke } };

        var store = new DrawingStore(Display, repository);

        Assert.Single(store.Strokes);
        Assert.Equal(stroke.Id, store.Strokes[0].Id);
    }

    [Fact]
    public void BeginAppendEndBuildsACompletedStroke()
    {
        var store = new DrawingStore(Display, new MockDrawingRepository());

        store.BeginStroke(new StrokePoint(0, 0));
        store.AppendPoint(new StrokePoint(5, 5));
        store.AppendPoint(new StrokePoint(10, 10));
        store.EndStroke();

        Assert.Single(store.Strokes);
        Assert.Equal(
            new[] { new StrokePoint(0, 0), new StrokePoint(5, 5), new StrokePoint(10, 10) },
            store.Strokes[0].Points);
        Assert.Null(store.StrokeInProgress);
    }

    [Fact]
    public void EndStrokeWithoutBeginDoesNothing()
    {
        var store = new DrawingStore(Display, new MockDrawingRepository());
        store.EndStroke();
        Assert.Empty(store.Strokes);
    }

    [Fact]
    public void ClearRemovesAllStrokesAndAnyInProgressStroke()
    {
        var store = new DrawingStore(Display, new MockDrawingRepository());
        store.BeginStroke(new StrokePoint(0, 0));
        store.AppendPoint(new StrokePoint(1, 1));
        store.EndStroke();
        store.BeginStroke(new StrokePoint(2, 2));

        store.Clear();

        Assert.Empty(store.Strokes);
        Assert.Null(store.StrokeInProgress);
    }

    [Fact]
    public void RemoveStrokesTouchingErasesTheWholeStrokeItTouches()
    {
        var store = new DrawingStore(Display, new MockDrawingRepository());
        store.BeginStroke(new StrokePoint(0, 0));
        store.AppendPoint(new StrokePoint(10, 0));
        store.EndStroke();

        var erasedIds = store.RemoveStrokes(new StrokePoint(5, 0), tolerance: 2);

        Assert.Single(erasedIds);
        Assert.Empty(store.Strokes);
    }

    [Fact]
    public void RemoveStrokesMissesAPointFarFromAnyStroke()
    {
        var store = new DrawingStore(Display, new MockDrawingRepository());
        store.BeginStroke(new StrokePoint(0, 0));
        store.AppendPoint(new StrokePoint(10, 0));
        store.EndStroke();

        var erasedIds = store.RemoveStrokes(new StrokePoint(0, 100), tolerance: 2);

        Assert.Empty(erasedIds);
        Assert.Single(store.Strokes);
    }
}
