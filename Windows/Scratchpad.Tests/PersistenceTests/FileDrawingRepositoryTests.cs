using Scratchpad.Drawing;
using Scratchpad.Overlay;
using Scratchpad.Persistence;
using Xunit;

namespace Scratchpad.Tests.PersistenceTests;

public class FileDrawingRepositoryTests
{
    private static (FileDrawingRepository Repository, string Directory) MakeRepository()
    {
        var directory = Path.Combine(Path.GetTempPath(), $"ScratchpadTests-{Guid.NewGuid()}");
        return (new FileDrawingRepository(directory), directory);
    }

    [Fact]
    public void LoadingMissingDisplayReturnsEmptyDocument()
    {
        var (repository, directory) = MakeRepository();
        try
        {
            var document = repository.Load(new DisplayIdentifier("\\.\\DISPLAY1"));
            Assert.Empty(document.Strokes);
        }
        finally
        {
            if (Directory.Exists(directory)) Directory.Delete(directory, recursive: true);
        }
    }

    [Fact]
    public void SavedDocumentRoundTripsThroughLoad()
    {
        var (repository, directory) = MakeRepository();
        try
        {
            var display = new DisplayIdentifier("\\.\\DISPLAY42");
            var stroke = new Stroke { Points = { new StrokePoint(0, 0), new StrokePoint(10, 10) } };
            var document = new DrawingDocument { Strokes = { stroke } };

            repository.Save(document, display);
            var loaded = repository.Load(display);

            Assert.Single(loaded.Strokes);
            Assert.Equal(stroke.Points, loaded.Strokes[0].Points);
        }
        finally
        {
            if (Directory.Exists(directory)) Directory.Delete(directory, recursive: true);
        }
    }

    [Fact]
    public void ClearRemovesTheSavedDocument()
    {
        var (repository, directory) = MakeRepository();
        try
        {
            var display = new DisplayIdentifier("\\.\\DISPLAY7");
            repository.Save(new DrawingDocument { Strokes = { new Stroke() } }, display);

            repository.Clear(display);

            Assert.Empty(repository.Load(display).Strokes);
        }
        finally
        {
            if (Directory.Exists(directory)) Directory.Delete(directory, recursive: true);
        }
    }

    [Fact]
    public void DifferentDisplaysArePersistedIndependently()
    {
        var (repository, directory) = MakeRepository();
        try
        {
            var first = new DisplayIdentifier("\\.\\DISPLAY1");
            var second = new DisplayIdentifier("\\.\\DISPLAY2");
            var firstDocument = new DrawingDocument { Strokes = { new Stroke() } };

            repository.Save(firstDocument, first);

            Assert.Single(repository.Load(first).Strokes);
            Assert.Empty(repository.Load(second).Strokes);
        }
        finally
        {
            if (Directory.Exists(directory)) Directory.Delete(directory, recursive: true);
        }
    }
}
