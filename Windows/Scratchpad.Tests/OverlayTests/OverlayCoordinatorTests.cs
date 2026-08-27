using System.IO;
using System.Windows;
using System.Windows.Forms;
using Scratchpad.Animations;
using Scratchpad.Drawing;
using Scratchpad.Overlay;
using Scratchpad.Persistence;
using Scratchpad.Preferences;
using Scratchpad.Rendering;
using Scratchpad.Tests.SettingsTests;
using Scratchpad.Utilities;
using Xunit;

namespace Scratchpad.Tests.OverlayTests;

internal sealed class SpyFadeAnimator : IOverlayFadeAnimator
{
    public void FadeIn(Window window, TimeSpan duration) { }
    public void FadeOut(Window window, TimeSpan duration, Action completion) => completion();
}

internal sealed class StubScreenObserving : IScreenObserving
{
    public IReadOnlyList<Screen> Screens => Screen.AllScreens;
    public IDisposable ObserveScreenChanges(Action handler) => new NoopSubscription();

    private sealed class NoopSubscription : IDisposable
    {
        public void Dispose() { }
    }
}

/// These tests construct real `OverlayWindowController`/`OverlayWindow`
/// (WPF `Window`) instances via `Toggle()`/`Show()` -- `SpyFadeAnimator`
/// only skips the animation, mirroring the macOS app's own
/// `OverlayCoordinatorTests`, which does the same with a real `NSPanel`.
/// Never run against a real Windows/WPF test host in this session (no
/// Windows machine was available); if window construction on xUnit's
/// worker thread turns out to need an STA thread with a pumped
/// `Dispatcher`, wrap these in a dedicated STA test thread (e.g.
/// `Xunit.StaFact`) rather than assuming a bare `[Fact]` is sufficient.
public class OverlayCoordinatorTests
{
    private static (OverlayCoordinator Coordinator, OverlayState State, DrawingStoreFactory Factory) MakeCoordinator()
    {
        var overlayState = new OverlayState();
        var directory = Path.Combine(Path.GetTempPath(), $"OverlayCoordinatorTests-{Guid.NewGuid()}");
        var drawingStoreFactory = new DrawingStoreFactory(new FileDrawingRepository(directory));
        var coordinator = new OverlayCoordinator(
            overlayState,
            drawingStoreFactory,
            new PathStrokeRenderer(),
            new SpyFadeAnimator(),
            new SettingsStore(new InMemorySettingsPersistence()),
            new StubScreenObserving());
        return (coordinator, overlayState, drawingStoreFactory);
    }

    [StaFact]
    public void ToggleNeverMutatesAnyDrawingStore()
    {
        var (coordinator, _, factory) = MakeCoordinator();
        var screen = Screen.PrimaryScreen;
        if (screen is null || DisplayIdentifier.FromScreen(screen) is not { } display) return;

        var store = factory.Store(display);
        store.BeginStroke(new StrokePoint(0, 0));
        store.AppendPoint(new StrokePoint(1, 1));
        store.EndStroke();
        var strokesBeforeToggle = store.Strokes.ToList();

        coordinator.Toggle();
        coordinator.Toggle();

        Assert.Equal(strokesBeforeToggle.Select(s => s.Id), store.Strokes.Select(s => s.Id));
    }

    [StaFact]
    public void ToggleFlipsOverlayVisibility()
    {
        var (coordinator, overlayState, _) = MakeCoordinator();
        Assert.False(overlayState.IsVisible);
        coordinator.Toggle();
        Assert.True(overlayState.IsVisible);
        coordinator.Toggle();
        Assert.False(overlayState.IsVisible);
    }

    [StaFact]
    public void ClearAllNeverMutatesOverlayVisibility()
    {
        var (coordinator, overlayState, _) = MakeCoordinator();
        coordinator.Toggle();
        var visibilityBeforeClear = overlayState.IsVisible;

        coordinator.ClearAll();

        Assert.Equal(visibilityBeforeClear, overlayState.IsVisible);
    }

    [Fact]
    public void ClearAllErasesStrokesOnEveryConnectedDisplay()
    {
        var (coordinator, _, factory) = MakeCoordinator();
        var screen = Screen.PrimaryScreen;
        if (screen is null || DisplayIdentifier.FromScreen(screen) is not { } display) return;

        var store = factory.Store(display);
        store.BeginStroke(new StrokePoint(0, 0));
        store.AppendPoint(new StrokePoint(1, 1));
        store.EndStroke();

        coordinator.ClearAll();

        Assert.Empty(store.Strokes);
    }
}
