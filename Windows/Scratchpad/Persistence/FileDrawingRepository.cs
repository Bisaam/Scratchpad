using System.IO;
using System.Text.Json;
using Scratchpad.Drawing;
using Scratchpad.Overlay;

namespace Scratchpad.Persistence;

/// Persists each display's drawing as its own JSON file, named by that
/// display's stable identifier, under `PersistenceLocations.DrawingsDirectory`.
/// Mirrors the macOS app's `FileDrawingRepository`.
public sealed class FileDrawingRepository : IDrawingRepository
{
    private readonly string _directory;

    public FileDrawingRepository(string? directory = null)
    {
        _directory = directory ?? PersistenceLocations.DrawingsDirectory;
    }

    public DrawingDocument Load(DisplayIdentifier display)
    {
        var path = FilePath(display);
        if (!File.Exists(path)) return DrawingDocument.Empty;
        try
        {
            var json = File.ReadAllText(path);
            return JsonSerializer.Deserialize<DrawingDocument>(json) ?? DrawingDocument.Empty;
        }
        catch (Exception ex) when (ex is IOException or JsonException or UnauthorizedAccessException)
        {
            return DrawingDocument.Empty;
        }
    }

    public void Save(DrawingDocument document, DisplayIdentifier display)
    {
        Directory.CreateDirectory(_directory);
        var json = JsonSerializer.Serialize(document);
        var path = FilePath(display);
        var tempPath = path + ".tmp";
        File.WriteAllText(tempPath, json);
        File.Move(tempPath, path, overwrite: true);
    }

    public void Clear(DisplayIdentifier display)
    {
        var path = FilePath(display);
        if (File.Exists(path))
        {
            File.Delete(path);
        }
    }

    private string FilePath(DisplayIdentifier display) =>
        Path.Combine(_directory, $"{display.FilenameComponent}.json");
}
