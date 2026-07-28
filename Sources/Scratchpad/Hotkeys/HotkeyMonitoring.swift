/// Registers a single system-wide keyboard shortcut and calls a handler
/// when it is pressed, regardless of which app is frontmost.
protocol HotkeyMonitoring: AnyObject {
    func startMonitoring(_ combo: KeyCombo, handler: @escaping () -> Void) throws
    func stopMonitoring()
}

enum HotkeyError: Error {
    case installHandlerFailed(status: Int32)
    case registrationFailed(status: Int32)
}
