import AppKit
import CoreGraphics

/// Identifies a physical display, used to key per-screen overlay windows,
/// drawing stores, and persisted drawing files.
///
/// Wraps `CGDirectDisplayID` rather than `NSScreen` itself, since AppKit
/// recreates `NSScreen` instances on every screen-configuration change while
/// the underlying display ID is stable for the life of a connected display.
struct DisplayIdentifier: Codable, Hashable {
    var rawValue: CGDirectDisplayID

    init(rawValue: CGDirectDisplayID) {
        self.rawValue = rawValue
    }

    /// A filesystem-safe representation, for naming per-display files.
    var filenameComponent: String {
        String(rawValue)
    }
}

extension DisplayIdentifier {
    /// Returns `nil` if the screen does not expose a display ID, which does
    /// not happen for any real hardware but keeps this call site honest.
    init?(screen: NSScreen) {
        guard
            let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        else {
            return nil
        }
        self.init(rawValue: CGDirectDisplayID(number.uint32Value))
    }
}
