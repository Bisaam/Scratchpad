using System.Windows;

namespace Scratchpad.App;

/// Composition root: wires every dependency together on launch. `Scratchpad`
/// is a tray-only app (no main window, `ShutdownMode="OnExplicitShutdown"`
/// in App.xaml) -- mirrors the macOS app's `AppDelegate` /
/// `applicationShouldTerminateAfterLastWindowClosed == false`, since a
/// tray-only app has no "last window" that should quit it.
public partial class App : Application
{
    private AppEnvironment? _environment;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        _environment = new AppEnvironment();
    }
}
