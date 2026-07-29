using Scratchpad.TrayIcon;

namespace Scratchpad.Preferences;

/// Keeps a single `PreferencesWindow` instance alive for the app's whole
/// lifetime, intercepting the user's close button to hide rather than
/// destroy it -- otherwise every "Preferences…" click after the first would
/// need to reconstruct the window. Mirrors the macOS app's
/// `PreferencesWindowController` (an `NSWindowController` naturally keeps
/// its window alive the same way).
public sealed class PreferencesWindowController
{
    private readonly PreferencesWindow _window;

    public PreferencesWindowController(SettingsStore settingsStore, ILaunchAtLoginService launchAtLoginService)
    {
        _window = new PreferencesWindow(settingsStore, launchAtLoginService);
        _window.Closing += (_, e) =>
        {
            e.Cancel = true;
            _window.Hide();
        };
    }

    public void Show()
    {
        _window.Show();
        _window.Activate();
    }
}
