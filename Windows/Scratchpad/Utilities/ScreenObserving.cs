using System.Windows.Forms;
using Microsoft.Win32;

namespace Scratchpad.Utilities;

/// Wraps `Screen.AllScreens` and monitor-configuration-change notifications
/// behind an interface, so `OverlayCoordinator`'s multi-monitor logic is
/// testable without real displays. Mirrors the macOS app's `ScreenObserving`.
public interface IScreenObserving
{
    IReadOnlyList<Screen> Screens { get; }

    /// Returns a subscription; disposing it stops observing.
    IDisposable ObserveScreenChanges(Action handler);
}

public sealed class WinFormsScreenObserver : IScreenObserving
{
    public IReadOnlyList<Screen> Screens => Screen.AllScreens;

    public IDisposable ObserveScreenChanges(Action handler)
    {
        void OnDisplaySettingsChanged(object? sender, EventArgs e) => handler();
        SystemEvents.DisplaySettingsChanged += OnDisplaySettingsChanged;
        return new Unsubscriber(() => SystemEvents.DisplaySettingsChanged -= OnDisplaySettingsChanged);
    }

    private sealed class Unsubscriber : IDisposable
    {
        private readonly Action _unsubscribe;
        public Unsubscriber(Action unsubscribe) => _unsubscribe = unsubscribe;
        public void Dispose() => _unsubscribe();
    }
}
