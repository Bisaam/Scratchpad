import AppKit

/// A solid black backdrop behind the drawing canvas, at a configurable
/// opacity (SPEC.md's background dim). Its own opacity is fixed once
/// visible; the overlay's fade in/out animates the whole window's
/// `alphaValue` instead, so this view has no animation logic of its own.
final class DimBackgroundView: NSView {
    init() {
        super.init(frame: .zero)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    var dimOpacity: Double = 0 {
        didSet {
            layer?.backgroundColor = NSColor.black.withAlphaComponent(dimOpacity).cgColor
        }
    }
}
