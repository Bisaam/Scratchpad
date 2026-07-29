using System.Windows.Forms;
using Scratchpad.Animations;
using Scratchpad.Drawing;
using Scratchpad.Preferences;
using Scratchpad.Rendering;
using Scratchpad.Utilities;

namespace Scratchpad.Overlay;

/// The single object that holds both `OverlayState` and access to every
/// display's `DrawingStore`, so it can mediate between them without either
/// one knowing the other exists. Its two entry points are intentionally
/// disjoint: `Toggle()` only ever mutates `OverlayState`, and `ClearAll()`
/// only ever mutates drawing stores. Mirrors the macOS app's
/// `OverlayCoordinator`.
public sealed class OverlayCoordinator
{
    public OverlayState OverlayState { get; }

    private readonly DrawingStoreFactory _drawingStoreFactory;
    private readonly IDrawingRenderer _renderer;
    private readonly IOverlayFadeAnimator _animator;
    private readonly SettingsStore _settingsStore;
    private readonly IScreenObserving _screenObserving;
    private readonly Dictionary<DisplayIdentifier, OverlayWindowController> _controllersByDisplay = new();
    private readonly IDisposable _screenChangeSubscription;

    public OverlayCoordinator(
        OverlayState overlayState,
        DrawingStoreFactory drawingStoreFactory,
        IDrawingRenderer renderer,
        IOverlayFadeAnimator animator,
        SettingsStore settingsStore,
        IScreenObserving screenObserving)
    {
        OverlayState = overlayState;
        _drawingStoreFactory = drawingStoreFactory;
        _renderer = renderer;
        _animator = animator;
        _settingsStore = settingsStore;
        _screenObserving = screenObserving;
        _screenChangeSubscription = screenObserving.ObserveScreenChanges(HandleScreenChange);
    }

    public void Toggle()
    {
        if (OverlayState.IsVisible) Hide(); else Show();
    }

    public void Show()
    {
        var duration = TimeSpan.FromSeconds(_settingsStore.Settings.AnimationDuration);
        foreach (var screen in ScreensForCurrentDisplayMode())
        {
            if (DisplayIdentifier.FromScreen(screen) is not { } display) continue;
            var controller = Controller(screen, display);
            controller.UpdateDimOpacity(_settingsStore.Settings.BackgroundDimOpacity);
            ApplyCurrentPencilStyle(display);
            controller.Show(duration);
        }
        OverlayState.SetVisible(true);
    }

    public void Hide()
    {
        var duration = TimeSpan.FromSeconds(_settingsStore.Settings.AnimationDuration);
        foreach (var controller in _controllersByDisplay.Values)
        {
            controller.Hide(duration);
        }
        OverlayState.SetVisible(false);
    }

    /// Erases every display's drawing, including displays with no
    /// currently-live overlay window (e.g. when `DisplayMode` is
    /// `CurrentDisplayOnly`). Never touches `OverlayState`.
    public void ClearAll()
    {
        foreach (var screen in _screenObserving.Screens)
        {
            if (DisplayIdentifier.FromScreen(screen) is not { } display) continue;
            if (_controllersByDisplay.TryGetValue(display, out var controller))
            {
                controller.ClearDrawing();
            }
            else
            {
                _drawingStoreFactory.Store(display).Clear();
            }
        }
    }

    private OverlayWindowController Controller(Screen screen, DisplayIdentifier display)
    {
        if (_controllersByDisplay.TryGetValue(display, out var existing))
        {
            existing.UpdateFrame(screen);
            return existing;
        }
        var controller = new OverlayWindowController(
            screen, display, _drawingStoreFactory.Store(display), _renderer, _animator);
        _controllersByDisplay[display] = controller;
        return controller;
    }

    private IReadOnlyList<Screen> ScreensForCurrentDisplayMode()
    {
        if (_settingsStore.Settings.DisplayMode == AppSettings.DisplayMode.CurrentDisplayOnly)
        {
            var cursorPosition = Cursor.Position;
            var screenUnderCursor = _screenObserving.Screens.FirstOrDefault(s => s.Bounds.Contains(cursorPosition));
            var fallback = screenUnderCursor ?? Screen.PrimaryScreen;
            return fallback is null ? Array.Empty<Screen>() : new[] { fallback };
        }
        return _screenObserving.Screens;
    }

    private void HandleScreenChange()
    {
        var currentDisplayIds = _screenObserving.Screens
            .Select(DisplayIdentifier.FromScreen)
            .Where(id => id.HasValue)
            .Select(id => id!.Value)
            .ToHashSet();

        foreach (var displayId in _controllersByDisplay.Keys.ToList())
        {
            if (currentDisplayIds.Contains(displayId)) continue;
            _controllersByDisplay[displayId].Hide(TimeSpan.Zero);
            _controllersByDisplay.Remove(displayId);
            _drawingStoreFactory.RemoveStore(displayId);
        }

        if (!OverlayState.IsVisible) return;
        foreach (var screen in ScreensForCurrentDisplayMode())
        {
            if (DisplayIdentifier.FromScreen(screen) is not { } display || _controllersByDisplay.ContainsKey(display))
            {
                continue;
            }
            var controller = Controller(screen, display);
            controller.UpdateDimOpacity(_settingsStore.Settings.BackgroundDimOpacity);
            ApplyCurrentPencilStyle(display);
            controller.Show(TimeSpan.FromSeconds(_settingsStore.Settings.AnimationDuration));
        }
    }

    /// Applied to strokes started from now on, not to strokes already
    /// drawn, so a mid-session preference change never rewrites history.
    private void ApplyCurrentPencilStyle(DisplayIdentifier display) =>
        _drawingStoreFactory.Store(display)
            .UpdateDefaultStyle(_settingsStore.Settings.StrokeColor, _settingsStore.Settings.StrokeWidth);
}
