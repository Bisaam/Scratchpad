using System.Text.RegularExpressions;
using System.Windows.Forms;

namespace Scratchpad.Overlay;

/// Identifies a physical display, used to key per-screen overlay windows,
/// drawing stores, and persisted drawing files.
///
/// Wraps `Screen.DeviceName` (e.g. `\\.\DISPLAY1`) rather than `Screen`
/// itself, since .NET recreates `Screen` instances on every screen
/// configuration change while the device name is stable for the life of a
/// connected display -- mirrors the macOS app's `DisplayIdentifier`, which
/// wraps `CGDirectDisplayID` for the same reason. Like `CGDirectDisplayID`,
/// this name is not guaranteed stable across every hardware reconfiguration
/// (e.g. some docking-station changes can renumber `\\.\DISPLAYn`); accepted
/// as a known limitation, same as the macOS side.
public readonly record struct DisplayIdentifier(string RawValue)
{
    private static readonly Regex UnsafeFilenameCharacters = new(@"[^A-Za-z0-9_-]", RegexOptions.Compiled);

    /// A filesystem-safe representation, for naming per-display files.
    public string FilenameComponent => UnsafeFilenameCharacters.Replace(RawValue, "_");

    public static DisplayIdentifier? FromScreen(Screen screen) =>
        string.IsNullOrEmpty(screen.DeviceName) ? null : new DisplayIdentifier(screen.DeviceName);
}
