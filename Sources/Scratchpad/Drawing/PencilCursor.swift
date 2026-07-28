import AppKit

/// The cursor shown while the overlay is visible, replacing the system
/// arrow (SPEC.md: "Pencil cursor while drawing"). Uses the app's own
/// `PencilCursor.png` (a copy of `drawing-icon.png`, bundled as an SPM
/// resource) rather than an SF Symbol, so the cursor matches the app's icon.
@MainActor
enum PencilCursor {
    static let cursor: NSCursor = {
        let image = loadImage()
        image.size = NSSize(width: 32, height: 32)
        // Approximate location of the pencil's tip in the source artwork;
        // adjust if a future icon revision shifts the glyph.
        return NSCursor(image: image, hotSpot: NSPoint(x: 4, y: 28))
    }()

    private static func loadImage() -> NSImage {
        guard
            let url = Bundle.module.url(forResource: "PencilCursor", withExtension: "png"),
            let image = NSImage(contentsOf: url)
        else {
            return NSImage(size: NSSize(width: 32, height: 32))
        }
        return image
    }
}
