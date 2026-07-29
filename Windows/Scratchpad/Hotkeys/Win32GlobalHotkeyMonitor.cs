using System.Runtime.InteropServices;
using System.Windows.Interop;

namespace Scratchpad.Hotkeys;

/// Registers the global shortcut via Win32's `RegisterHotKey`, the
/// system-wide-shortcut equivalent of the macOS app's
/// `CarbonGlobalHotkeyMonitor` (which uses Carbon's `RegisterEventHotKey`
/// for the same reason: no Accessibility-style permission prompt, fires
/// regardless of which app is in the foreground).
///
/// `RegisterHotKey` requires a window handle to post `WM_HOTKEY` messages
/// to, so this creates an invisible message-only `HwndSource`
/// (`HWND_MESSAGE` parent) purely to receive that message -- it is never
/// shown and never participates in the visible window/taskbar list.
public sealed class Win32GlobalHotkeyMonitor : IHotkeyMonitoring, IDisposable
{
    private const int WmHotKey = 0x0312;
    private const int HotkeyId = 0xC0DE;
    private static readonly nint HwndMessage = -3;

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool RegisterHotKey(nint hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool UnregisterHotKey(nint hWnd, int id);

    private HwndSource? _hwndSource;
    private Action? _handler;
    private bool _isRegistered;

    public void StartMonitoring(KeyCombo combo, Action handler)
    {
        StopMonitoring();
        _handler = handler;

        _hwndSource = new HwndSource(new HwndSourceParameters("ScratchpadHotkeyWindow")
        {
            ParentWindow = HwndMessage,
            WindowStyle = 0,
        });
        _hwndSource.AddHook(WndProc);

        if (!RegisterHotKey(_hwndSource.Handle, HotkeyId, (uint)combo.Modifiers, combo.VirtualKeyCode))
        {
            var errorCode = Marshal.GetLastWin32Error();
            StopMonitoring();
            throw new HotkeyRegistrationException(errorCode);
        }
        _isRegistered = true;
    }

    public void StopMonitoring()
    {
        if (_isRegistered && _hwndSource is not null)
        {
            UnregisterHotKey(_hwndSource.Handle, HotkeyId);
            _isRegistered = false;
        }
        if (_hwndSource is not null)
        {
            _hwndSource.RemoveHook(WndProc);
            _hwndSource.Dispose();
            _hwndSource = null;
        }
        _handler = null;
    }

    private nint WndProc(nint hwnd, int msg, nint wParam, nint lParam, ref bool handled)
    {
        if (msg == WmHotKey && unchecked((int)wParam) == HotkeyId)
        {
            _handler?.Invoke();
            handled = true;
        }
        return 0;
    }

    public void Dispose() => StopMonitoring();
}
