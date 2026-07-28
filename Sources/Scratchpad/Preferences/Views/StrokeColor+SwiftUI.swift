import AppKit
import SwiftUI

/// Bridges `StrokeColor` (a plain, portable RGBA value with no Apple-only
/// types) to SwiftUI's `Color`, for use in the `ColorPicker` in Preferences.
/// This conversion lives here, at the UI edge, rather than on `StrokeColor`
/// itself, so the drawing model stays framework-agnostic.
extension StrokeColor {
    var swiftUIColor: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    init(swiftUIColor color: Color) {
        let nsColor = (NSColor(color).usingColorSpace(.deviceRGB)) ?? NSColor(color)
        self.init(
            red: Double(nsColor.redComponent),
            green: Double(nsColor.greenComponent),
            blue: Double(nsColor.blueComponent),
            alpha: Double(nsColor.alphaComponent)
        )
    }
}
