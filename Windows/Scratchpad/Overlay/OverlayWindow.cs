using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Forms;
using System.Windows.Interop;
using System.Windows.Media;
using Scratchpad.Drawing;
using Scratchpad.Rendering;

namespace Scratchpad.Overlay;

/// The fullscreen, transparent, always-on-top window shown on one display.
///
/// `ShowActivated = false` plus the `WS_EX_TOOLWINDOW` extended style (set
/// in `OnSourceInitialized`) keep the overlay from ever taking keyboard
/// focus or appearing in Alt-Tab/the taskbar -- the Windows equivalent of
/// the macOS app's `.nonactivatingPanel` + `canBecomeKey == false`, for the
/// same reason: drawing should never steal focus from whatever app was in
/// the foreground.
///
/// The frame is the target monitor's *working area*, not its full bounds --
/// deliberately excludes the taskbar's screen-edge strip. This is not just
/// cosmetic: a borderless, topmost window that exactly covers a monitor's
/// full bounds is also what Windows' shell uses to detect "an app wants
/// fullscreen," which can auto-hide the taskbar as a side effect --
/// mirroring exactly the problem the macOS app hit with the Dock (see
/// JOURNAL.md), solved there by keeping the overlay's window level below
/// the Dock's. Excluding the taskbar's strip from the frame here avoids
/// the Windows analog of that problem entirely, rather than fixing it after
/// the fact.
public sealed class OverlayWindow : Window
{
    private const int GwlExStyle = -20;
    private const int WsExToolWindow = 0x00000080;

    [DllImport("user32.dll")]
    private static extern int GetWindowLong(nint hWnd, int nIndex);

    [DllImport("user32.dll")]
    private static extern int SetWindowLong(nint hWnd, int nIndex, int dwNewLong);

    [DllImport("user32.dll")]
    private static extern bool MoveWindow(nint hWnd, int x, int y, int width, int height, bool repaint);

    public BackgroundDimView DimView { get; } = new();
    public DrawingCanvas DrawingSurface { get; }

    private Screen _screen;

    public OverlayWindow(Screen screen, DrawingStore drawingStore, IDrawingRenderer renderer)
    {
        _screen = screen;
        DrawingSurface = new DrawingCanvas(drawingStore, renderer);

        WindowStyle = WindowStyle.None;
        AllowsTransparency = true;
        Background = Brushes.Transparent;
        ResizeMode = ResizeMode.NoResize;
        ShowInTaskbar = false;
        ShowActivated = false;
        Topmost = true;
        Opacity = 0;

        var grid = new Grid();
        grid.Children.Add(DimView);
        grid.Children.Add(DrawingSurface);
        Content = grid;
    }

    protected override void OnSourceInitialized(EventArgs e)
    {
        base.OnSourceInitialized(e);
        var hwnd = new WindowInteropHelper(this).Handle;
        var currentStyle = GetWindowLong(hwnd, GwlExStyle);
        SetWindowLong(hwnd, GwlExStyle, currentStyle | WsExToolWindow);
        ApplyFrame();
    }

    /// Repositions the window onto (possibly a new) screen. Safe to call
    /// both before and after the window's handle exists.
    public void UpdateFrame(Screen screen)
    {
        _screen = screen;
        if (new WindowInteropHelper(this).Handle != nint.Zero)
        {
            ApplyFrame();
        }
    }

    private void ApplyFrame()
    {
        var hwnd = new WindowInteropHelper(this).Handle;
        var area = _screen.WorkingArea;
        MoveWindow(hwnd, area.Left, area.Top, area.Width, area.Height, true);
    }
}
