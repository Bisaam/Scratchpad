import SwiftUI

/// SwiftUI bridge to `KeyRecorderView`, for use inside the (otherwise
/// SwiftUI) Preferences form.
struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var combo: KeyCombo

    func makeNSView(context: Context) -> KeyRecorderView {
        let view = KeyRecorderView(combo: combo)
        view.onChange = { combo = $0 }
        return view
    }

    func updateNSView(_ nsView: KeyRecorderView, context: Context) {
        nsView.combo = combo
    }
}
