using System.Text.Json;
using System.Windows.Input;
using Scratchpad.Hotkeys;
using Xunit;

namespace Scratchpad.Tests.HotkeyTests;

public class KeyComboTests
{
    [Fact]
    public void DefaultShortcutDisplaysAsCtrlAltD()
    {
        Assert.Equal("Ctrl+Alt+D", KeyCombo.Default.DisplayString);
    }

    [Fact]
    public void DisplayStringOrdersModifiersControlAltShiftWindows()
    {
        var combo = new KeyCombo(0x53, ModifierKeys.Control | ModifierKeys.Alt | ModifierKeys.Shift | ModifierKeys.Windows);
        Assert.Equal("Ctrl+Alt+Shift+Win+S", combo.DisplayString);
    }

    [Fact]
    public void JsonRoundTrips()
    {
        var combo = KeyCombo.Default;
        var json = JsonSerializer.Serialize(combo);
        var decoded = JsonSerializer.Deserialize<KeyCombo>(json);
        Assert.Equal(combo, decoded);
    }
}
