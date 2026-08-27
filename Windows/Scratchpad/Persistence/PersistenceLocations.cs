using System.IO;

namespace Scratchpad.Persistence;

/// Centralizes every on-disk path Scratchpad writes to, so no other file
/// hardcodes a path fragment. Mirrors the macOS app's `PersistenceLocations`,
/// using `%LOCALAPPDATA%` (the Windows analog of `~/Library/Application
/// Support`) as the base.
public static class PersistenceLocations
{
    public static string ApplicationDataDirectory =>
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Scratchpad");

    public static string DrawingsDirectory => Path.Combine(ApplicationDataDirectory, "Drawings");

    public static string SettingsFilePath => Path.Combine(ApplicationDataDirectory, "settings.json");
}
