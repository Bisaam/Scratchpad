namespace Scratchpad.Hotkeys;

/// Registers a single system-wide keyboard shortcut and calls a handler
/// when it is pressed, regardless of which app is in the foreground.
/// Mirrors the macOS app's `HotkeyMonitoring` protocol.
public interface IHotkeyMonitoring
{
    void StartMonitoring(KeyCombo combo, Action handler);
    void StopMonitoring();
}

/// Thrown when `RegisterHotKey` fails, e.g. because another application
/// already owns that exact key combination.
public sealed class HotkeyRegistrationException : Exception
{
    public int Win32ErrorCode { get; }

    public HotkeyRegistrationException(int win32ErrorCode)
        : base($"RegisterHotKey failed with Win32 error {win32ErrorCode}.")
    {
        Win32ErrorCode = win32ErrorCode;
    }
}
