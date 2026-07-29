using System.Text.Json;

namespace Scratchpad.Preferences;

/// Stores `AppSettings` as a single JSON file under
/// `PersistenceLocations.SettingsFilePath`, rather than one registry value
/// per field, so adding a preference never requires touching a list of key
/// names scattered across the app. The macOS app stores the same JSON blob
/// in `UserDefaults` instead of a file; a plain file was chosen here so
/// Preferences and Drawings persistence both live under the same
/// `%LOCALAPPDATA%\Scratchpad` directory rather than splitting settings off
/// into the registry.
public sealed class JsonSettingsPersistence : ISettingsPersistence
{
    private readonly string _filePath;

    public JsonSettingsPersistence(string? filePath = null)
    {
        _filePath = filePath ?? Persistence.PersistenceLocations.SettingsFilePath;
    }

    public AppSettings? LoadSettings()
    {
        if (!File.Exists(_filePath)) return null;
        try
        {
            var json = File.ReadAllText(_filePath);
            return JsonSerializer.Deserialize<AppSettings>(json);
        }
        catch (Exception ex) when (ex is IOException or JsonException or UnauthorizedAccessException)
        {
            return null;
        }
    }

    public void SaveSettings(AppSettings settings)
    {
        var directory = Path.GetDirectoryName(_filePath);
        if (!string.IsNullOrEmpty(directory))
        {
            Directory.CreateDirectory(directory);
        }
        var json = JsonSerializer.Serialize(settings);
        var tempPath = _filePath + ".tmp";
        File.WriteAllText(tempPath, json);
        File.Move(tempPath, _filePath, overwrite: true);
    }
}
