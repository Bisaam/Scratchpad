using System.Drawing;
using System.Windows.Forms;
using Scratchpad.Overlay;
using Scratchpad.Preferences;

namespace Scratchpad.TrayIcon;

/// The system tray icon and its context menu (SPEC.md: "Menu bar icon only.
/// No Dock icon by default." -- the Windows analog is a tray icon with no
/// taskbar button, already arranged by `OverlayWindow`'s `ShowInTaskbar =
/// false`/`WS_EX_TOOLWINDOW`). Built on `NotifyIcon`/`ContextMenuStrip`
/// (WinForms; WPF has no tray icon API of its own), mirroring the macOS
/// app's `StatusBarController`, which is built directly on
/// `NSStatusItem`/`NSMenu` for the same reason: precise control over the
/// dynamic Show/Hide label and the Launch at Login checkmark state.
public sealed class TrayIconController : IDisposable
{
    private readonly NotifyIcon _notifyIcon;
    private readonly OverlayCoordinator _overlayCoordinator;
    private readonly ILaunchAtLoginService _launchAtLoginService;
    private readonly PreferencesWindowController _preferencesWindowController;
    private readonly Action _showAbout;

    private readonly ToolStripMenuItem _toggleOverlayItem = new();
    private readonly ToolStripMenuItem _launchAtLoginItem = new("Launch at Login");

    public TrayIconController(
        OverlayCoordinator overlayCoordinator,
        ILaunchAtLoginService launchAtLoginService,
        PreferencesWindowController preferencesWindowController,
        Action showAbout)
    {
        _overlayCoordinator = overlayCoordinator;
        _launchAtLoginService = launchAtLoginService;
        _preferencesWindowController = preferencesWindowController;
        _showAbout = showAbout;

        _notifyIcon = new NotifyIcon
        {
            Icon = LoadTrayIcon(),
            Visible = true,
            Text = "Scratchpad",
        };

        var menu = new ContextMenuStrip();
        menu.Opening += (_, _) => RefreshMenuState();

        _toggleOverlayItem.Click += (_, _) => _overlayCoordinator.Toggle();
        menu.Items.Add(_toggleOverlayItem);

        var clearItem = new ToolStripMenuItem("Clear Pad");
        clearItem.Click += (_, _) => _overlayCoordinator.ClearAll();
        menu.Items.Add(clearItem);

        menu.Items.Add(new ToolStripSeparator());

        var preferencesItem = new ToolStripMenuItem("Preferences…");
        preferencesItem.Click += (_, _) => _preferencesWindowController.Show();
        menu.Items.Add(preferencesItem);

        _launchAtLoginItem.Click += (_, _) => ToggleLaunchAtLogin();
        menu.Items.Add(_launchAtLoginItem);

        menu.Items.Add(new ToolStripSeparator());

        var aboutItem = new ToolStripMenuItem("About Scratchpad");
        aboutItem.Click += (_, _) => _showAbout();
        menu.Items.Add(aboutItem);

        var quitItem = new ToolStripMenuItem("Quit Scratchpad");
        quitItem.Click += (_, _) => System.Windows.Application.Current.Shutdown();
        menu.Items.Add(quitItem);

        _notifyIcon.ContextMenuStrip = menu;
        _notifyIcon.DoubleClick += (_, _) => _overlayCoordinator.Toggle();
    }

    /// Refreshes state that can change outside the menu (overlay visibility,
    /// login item status) right before the menu is shown, rather than
    /// polling on a timer.
    private void RefreshMenuState()
    {
        _toggleOverlayItem.Text = _overlayCoordinator.OverlayState.IsVisible ? "Hide Scratchpad" : "Show Scratchpad";
        _launchAtLoginItem.Checked = _launchAtLoginService.IsEnabled;
    }

    private void ToggleLaunchAtLogin()
    {
        try
        {
            _launchAtLoginService.SetEnabled(!_launchAtLoginService.IsEnabled);
        }
        catch (Exception)
        {
            // Best-effort, same as the macOS app's `try?`.
        }
    }

    private static Icon LoadTrayIcon()
    {
        var path = Path.Combine(AppContext.BaseDirectory, "Resources", "AppIcon.png");
        using var bitmap = new Bitmap(path);
        using var resized = new Bitmap(bitmap, new Size(32, 32));
        // `Icon.FromHandle` does not take ownership of the HICON; it is
        // intentionally never destroyed here. One tray icon is created once
        // per process lifetime, so this is a one-time, process-lifetime
        // leak (freed by the OS on exit) rather than a growing one -- the
        // same tradeoff most NotifyIcon-from-bitmap examples make to avoid
        // needing a `DestroyIcon` P/Invoke for a single icon.
        return Icon.FromHandle(resized.GetHicon());
    }

    public void Dispose()
    {
        _notifyIcon.Visible = false;
        _notifyIcon.Dispose();
    }
}
