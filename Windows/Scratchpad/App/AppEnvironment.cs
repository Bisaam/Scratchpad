using Scratchpad.Animations;
using Scratchpad.Drawing;
using Scratchpad.Hotkeys;
using Scratchpad.Overlay;
using Scratchpad.Persistence;
using Scratchpad.Preferences;
using Scratchpad.Rendering;
using Scratchpad.TrayIcon;
using Scratchpad.Utilities;

namespace Scratchpad.App;

/// Constructs every dependency via constructor injection and retains the
/// object graph for the lifetime of the app. The single place where
/// concrete implementations are chosen; every other type in the app depends
/// only on interfaces. Mirrors the macOS app's `AppEnvironment`.
public sealed class AppEnvironment
{
    private readonly SettingsStore _settingsStore;
    private readonly OverlayCoordinator _overlayCoordinator;
    private readonly IHotkeyMonitoring _hotkeyMonitor;
    private readonly TrayIconController _trayIconController;
    private KeyCombo? _registeredCombo;

    public AppEnvironment()
    {
        var drawingRepository = new FileDrawingRepository();
        var settingsStore = new SettingsStore();
        var drawingStoreFactory = new DrawingStoreFactory(drawingRepository);

        var overlayCoordinator = new OverlayCoordinator(
            new OverlayState(),
            drawingStoreFactory,
            new PathStrokeRenderer(),
            new WpfFadeAnimator(),
            settingsStore,
            new WinFormsScreenObserver());

        var launchAtLoginService = new RegistryLaunchAtLoginService();
        var preferencesWindowController = new PreferencesWindowController(settingsStore, launchAtLoginService);
        var trayIconController = new TrayIconController(
            overlayCoordinator,
            launchAtLoginService,
            preferencesWindowController,
            showAbout: () => new AboutWindow().Show());

        _settingsStore = settingsStore;
        _overlayCoordinator = overlayCoordinator;
        _hotkeyMonitor = new Win32GlobalHotkeyMonitor();
        _trayIconController = trayIconController;

        RegisterHotkey();
        // Reacting to a live shortcut change from Preferences means
        // re-registering the OS-level hotkey after every settings save, not
        // just shortcut changes -- `SettingsStore.Settings` has no
        // per-field change notification. `_registeredCombo` skips the
        // re-registration when the shortcut itself did not actually
        // change, since a WPF `Slider` fires `ValueChanged` continuously
        // while dragging (e.g. adjusting pencil thickness), and tearing
        // down/recreating the Win32 hotkey registration on every one of
        // those events would be wasteful and could momentarily leave the
        // hotkey unregistered.
        _settingsStore.PropertyChanged += (_, _) => RegisterHotkey();
    }

    private void RegisterHotkey()
    {
        var combo = _settingsStore.Settings.GlobalShortcut;
        if (_registeredCombo == combo) return;
        _registeredCombo = combo;
        try
        {
            _hotkeyMonitor.StartMonitoring(combo, () => _overlayCoordinator.Toggle());
        }
        catch (HotkeyRegistrationException)
        {
            // Best-effort: if the combo is already claimed by another app,
            // the user can pick a different one in Preferences. Mirrors the
            // macOS app's `try?` around the same call.
        }
    }
}
