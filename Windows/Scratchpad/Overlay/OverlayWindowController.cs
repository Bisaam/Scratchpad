using System.Runtime.InteropServices;
using System.Windows.Forms;
using System.Windows.Interop;
using Scratchpad.Animations;
using Scratchpad.Drawing;
using Scratchpad.Rendering;

namespace Scratchpad.Overlay;

/// Owns one display's overlay window, its dim backdrop, and its drawing
/// canvas. `OverlayCoordinator` is the only thing that talks to instances
/// of this class; it never reaches into `DrawingStore` itself. Mirrors the
/// macOS app's `OverlayWindowController`.
public sealed class OverlayWindowController
{
    private const int SwShowNoActivate = 4;

    [DllImport("user32.dll")]
    private static extern bool ShowWindow(nint hWnd, int nCmdShow);

    public DisplayIdentifier Display { get; }

    private readonly OverlayWindow _window;
    private readonly IOverlayFadeAnimator _animator;

    public OverlayWindowController(
        Screen screen,
        DisplayIdentifier display,
        DrawingStore drawingStore,
        IDrawingRenderer renderer,
        IOverlayFadeAnimator animator)
    {
        Display = display;
        _animator = animator;
        _window = new OverlayWindow(screen, drawingStore, renderer);
    }

    public void UpdateFrame(Screen screen) => _window.UpdateFrame(screen);

    public void UpdateDimOpacity(double opacity) => _window.DimView.DimOpacity = opacity;

    public void Show(TimeSpan duration)
    {
        // The very first `Show()` creates the window's handle and respects
        // `ShowActivated = false`; WPF does not honor `ShowActivated` on
        // subsequent shows after a `Hide()`, so every later re-show goes
        // through `ShowWindow(SW_SHOWNOACTIVATE)` directly -- the Win32
        // equivalent of the macOS app's `orderFrontRegardless()`.
        var hwnd = new WindowInteropHelper(_window).Handle;
        if (hwnd == nint.Zero)
        {
            _window.Show();
        }
        else
        {
            ShowWindow(hwnd, SwShowNoActivate);
        }
        _animator.FadeIn(_window, duration);
    }

    public void Hide(TimeSpan duration)
    {
        _animator.FadeOut(_window, duration, () => _window.Hide());
    }

    /// Erases this display's drawing. Never touches overlay visibility.
    public void ClearDrawing() => _window.DrawingSurface.ClearDrawing();
}
