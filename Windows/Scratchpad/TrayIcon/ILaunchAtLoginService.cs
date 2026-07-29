using Microsoft.Win32;

namespace Scratchpad.TrayIcon;

/// Registers Scratchpad as a login item. Mirrors the macOS app's
/// `LaunchAtLoginService`.
public interface ILaunchAtLoginService
{
    bool IsEnabled { get; }
    void SetEnabled(bool enabled);
}

/// Uses the current user's Run registry key -- the standard,
/// permission-prompt-free way for a per-user desktop app to launch at
/// login, and the closest Windows analog to the macOS app's
/// `SMAppService`-backed implementation.
public sealed class RegistryLaunchAtLoginService : ILaunchAtLoginService
{
    private const string RunKeyPath = @"Software\Microsoft\Windows\CurrentVersion\Run";
    private const string ValueName = "Scratchpad";

    public bool IsEnabled
    {
        get
        {
            using var key = Registry.CurrentUser.OpenSubKey(RunKeyPath, writable: false);
            return key?.GetValue(ValueName) is string existingValue &&
                   string.Equals(existingValue.Trim('"'), ExecutablePath, StringComparison.OrdinalIgnoreCase);
        }
    }

    public void SetEnabled(bool enabled)
    {
        using var key = Registry.CurrentUser.OpenSubKey(RunKeyPath, writable: true)
            ?? Registry.CurrentUser.CreateSubKey(RunKeyPath);

        if (enabled)
        {
            key.SetValue(ValueName, $"\"{ExecutablePath}\"");
        }
        else
        {
            key.DeleteValue(ValueName, throwOnMissingValue: false);
        }
    }

    private static string ExecutablePath =>
        System.Diagnostics.Process.GetCurrentProcess().MainModule?.FileName
        ?? throw new InvalidOperationException("Could not resolve the current executable's path.");
}
