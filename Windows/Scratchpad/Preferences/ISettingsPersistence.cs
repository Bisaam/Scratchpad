namespace Scratchpad.Preferences;

/// Reads and writes the raw `AppSettings` blob. Kept separate from
/// `SettingsStore` so tests can substitute an in-memory implementation
/// without touching the real filesystem. Mirrors the macOS app's
/// `SettingsPersisting`.
public interface ISettingsPersistence
{
    AppSettings? LoadSettings();
    void SaveSettings(AppSettings settings);
}
