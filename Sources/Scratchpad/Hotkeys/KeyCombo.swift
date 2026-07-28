import Carbon.HIToolbox

/// A global keyboard shortcut: a virtual key code plus Carbon modifier
/// flags. Stored using Carbon's representation directly since that is what
/// `RegisterEventHotKey` (see `CarbonGlobalHotkeyMonitor`) requires, avoiding
/// a translation layer between two equivalent flag sets.
struct KeyCombo: Codable, Equatable {
    var keyCode: UInt32
    var carbonModifierFlags: UInt32

    static let `default` = KeyCombo(
        keyCode: UInt32(kVK_ANSI_D),
        carbonModifierFlags: UInt32(cmdKey | optionKey)
    )
}

extension KeyCombo {
    /// A human-readable form for display in Preferences, e.g. "⌥⌘D".
    /// Covers the letter and digit keys a global shortcut would realistically
    /// use; anything else falls back to a placeholder rather than guessing.
    var displayString: String {
        var symbols = ""
        if carbonModifierFlags & UInt32(controlKey) != 0 { symbols += "⌃" }
        if carbonModifierFlags & UInt32(optionKey) != 0 { symbols += "⌥" }
        if carbonModifierFlags & UInt32(shiftKey) != 0 { symbols += "⇧" }
        if carbonModifierFlags & UInt32(cmdKey) != 0 { symbols += "⌘" }
        symbols += KeyCombo.characters[keyCode] ?? "?"
        return symbols
    }

    private static let characters: [UInt32: String] = {
        func code(_ value: Int) -> UInt32 { UInt32(value) }
        return [
            code(kVK_ANSI_A): "A", code(kVK_ANSI_B): "B", code(kVK_ANSI_C): "C", code(kVK_ANSI_D): "D",
            code(kVK_ANSI_E): "E", code(kVK_ANSI_F): "F", code(kVK_ANSI_G): "G", code(kVK_ANSI_H): "H",
            code(kVK_ANSI_I): "I", code(kVK_ANSI_J): "J", code(kVK_ANSI_K): "K", code(kVK_ANSI_L): "L",
            code(kVK_ANSI_M): "M", code(kVK_ANSI_N): "N", code(kVK_ANSI_O): "O", code(kVK_ANSI_P): "P",
            code(kVK_ANSI_Q): "Q", code(kVK_ANSI_R): "R", code(kVK_ANSI_S): "S", code(kVK_ANSI_T): "T",
            code(kVK_ANSI_U): "U", code(kVK_ANSI_V): "V", code(kVK_ANSI_W): "W", code(kVK_ANSI_X): "X",
            code(kVK_ANSI_Y): "Y", code(kVK_ANSI_Z): "Z",
            code(kVK_ANSI_0): "0", code(kVK_ANSI_1): "1", code(kVK_ANSI_2): "2", code(kVK_ANSI_3): "3",
            code(kVK_ANSI_4): "4", code(kVK_ANSI_5): "5", code(kVK_ANSI_6): "6", code(kVK_ANSI_7): "7",
            code(kVK_ANSI_8): "8", code(kVK_ANSI_9): "9",
            code(kVK_Space): "Space",
        ]
    }()
}
