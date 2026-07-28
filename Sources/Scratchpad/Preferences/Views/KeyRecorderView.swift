import AppKit
import Carbon.HIToolbox

/// A small clickable control that captures the next key combination typed
/// while it has focus and reports it as a `KeyCombo`. AppKit has no stock
/// control for this, so it is built directly on `NSView` rather than
/// wrapping something that doesn't quite fit.
final class KeyRecorderView: NSView {
    var combo: KeyCombo {
        didSet { needsDisplay = true }
    }

    var onChange: ((KeyCombo) -> Void)?

    private var isRecording = false {
        didSet { needsDisplay = true }
    }

    init(combo: KeyCombo) {
        self.combo = combo
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        isRecording = true
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        let modifiers = event.modifierFlags
        var carbonFlags: UInt32 = 0
        if modifiers.contains(.command) { carbonFlags |= UInt32(cmdKey) }
        if modifiers.contains(.option) { carbonFlags |= UInt32(optionKey) }
        if modifiers.contains(.control) { carbonFlags |= UInt32(controlKey) }
        if modifiers.contains(.shift) { carbonFlags |= UInt32(shiftKey) }

        let newCombo = KeyCombo(keyCode: UInt32(event.keyCode), carbonModifierFlags: carbonFlags)
        combo = newCombo
        isRecording = false
        onChange?(newCombo)
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        return super.resignFirstResponder()
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.controlBackgroundColor.setFill()
        let backgroundPath = NSBezierPath(roundedRect: bounds, xRadius: 6, yRadius: 6)
        backgroundPath.fill()

        NSColor.separatorColor.setStroke()
        backgroundPath.lineWidth = 1
        backgroundPath.stroke()

        let text = isRecording ? "Press a key…" : combo.displayString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: isRecording ? NSColor.secondaryLabelColor : NSColor.labelColor,
        ]
        let size = text.size(withAttributes: attributes)
        let origin = NSPoint(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2)
        text.draw(at: origin, withAttributes: attributes)
    }
}
