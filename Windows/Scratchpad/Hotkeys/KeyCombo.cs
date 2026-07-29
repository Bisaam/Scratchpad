using System.Windows.Input;

namespace Scratchpad.Hotkeys;

/// A global keyboard shortcut: a Win32 virtual-key code plus modifier flags.
/// `Modifiers` is stored as `System.Windows.Input.ModifierKeys`, whose flag
/// values (Alt=0x1, Control=0x2, Shift=0x4, Windows=0x8) happen to line up
/// exactly with the `MOD_*` constants `RegisterHotKey` expects, so no
/// translation layer is needed between the two -- same rationale as the
/// macOS app's `KeyCombo`, which stores Carbon's modifier representation
/// directly since that is what `RegisterEventHotKey` requires.
public readonly record struct KeyCombo(uint VirtualKeyCode, ModifierKeys Modifiers)
{
    /// Ctrl+Alt+D, per the project's chosen Windows default shortcut.
    public static readonly KeyCombo Default = new(
        VirtualKeyCode: 0x44, // VK_D
        Modifiers: ModifierKeys.Control | ModifierKeys.Alt
    );

    /// A human-readable form for display in Preferences, e.g. "Ctrl+Alt+D".
    /// Covers the letter, digit, and space keys a global shortcut would
    /// realistically use; anything else falls back to a placeholder rather
    /// than guessing.
    public string DisplayString
    {
        get
        {
            var parts = new List<string>();
            if (Modifiers.HasFlag(ModifierKeys.Control)) parts.Add("Ctrl");
            if (Modifiers.HasFlag(ModifierKeys.Alt)) parts.Add("Alt");
            if (Modifiers.HasFlag(ModifierKeys.Shift)) parts.Add("Shift");
            if (Modifiers.HasFlag(ModifierKeys.Windows)) parts.Add("Win");
            parts.Add(Characters.TryGetValue(VirtualKeyCode, out var character) ? character : "?");
            return string.Join("+", parts);
        }
    }

    private static readonly Dictionary<uint, string> Characters = BuildCharacterMap();

    private static Dictionary<uint, string> BuildCharacterMap()
    {
        var map = new Dictionary<uint, string>();
        for (var letter = 'A'; letter <= 'Z'; letter++)
        {
            map[(uint)letter] = letter.ToString();
        }
        for (var digit = '0'; digit <= '9'; digit++)
        {
            map[(uint)digit] = digit.ToString();
        }
        map[0x20] = "Space"; // VK_SPACE
        return map;
    }
}
