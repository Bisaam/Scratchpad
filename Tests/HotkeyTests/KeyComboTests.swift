import Carbon.HIToolbox
import Testing
@testable import Scratchpad

struct KeyComboTests {

    @Test func defaultShortcutDisplaysAsOptionCommandD() {
        #expect(KeyCombo.default.displayString == "⌥⌘D")
    }

    @Test func displayStringOrdersModifiersControlOptionShiftCommand() {
        let combo = KeyCombo(
            keyCode: UInt32(kVK_ANSI_S),
            carbonModifierFlags: UInt32(controlKey | optionKey | shiftKey | cmdKey)
        )
        #expect(combo.displayString == "⌃⌥⇧⌘S")
    }

    @Test func codableRoundTrips() throws {
        let combo = KeyCombo.default
        let data = try JSONEncoder().encode(combo)
        let decoded = try JSONDecoder().decode(KeyCombo.self, from: data)
        #expect(decoded == combo)
    }
}
