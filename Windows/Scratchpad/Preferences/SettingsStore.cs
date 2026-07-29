using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace Scratchpad.Preferences;

/// The single observable source of truth for user preferences. Preferences
/// views read and write `Settings` directly (replacing the whole immutable
/// record via a `with` expression for a single-field change); every change
/// is persisted automatically. Mirrors the macOS app's `SettingsStore`.
public sealed class SettingsStore : INotifyPropertyChanged
{
    private readonly ISettingsPersistence _persistence;
    private AppSettings _settings;

    public AppSettings Settings
    {
        get => _settings;
        set
        {
            if (_settings == value) return;
            _settings = value;
            _persistence.SaveSettings(value);
            OnPropertyChanged();
        }
    }

    public SettingsStore(ISettingsPersistence? persistence = null)
    {
        _persistence = persistence ?? new JsonSettingsPersistence();
        _settings = _persistence.LoadSettings() ?? AppSettings.Default;
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    private void OnPropertyChanged([CallerMemberName] string? propertyName = null) =>
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
}
