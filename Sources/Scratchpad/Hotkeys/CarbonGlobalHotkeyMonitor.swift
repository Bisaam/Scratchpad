import Carbon.HIToolbox

/// Registers the global shortcut via Carbon's `RegisterEventHotKey`.
///
/// This is the one API still sanctioned by Apple for system-wide hotkeys
/// that requires no Accessibility/Input Monitoring permission prompt and
/// fires regardless of which app is frontmost -- unlike an `NSEvent` global
/// monitor, which needs that permission and only observes events while
/// this app isn't key. It is interrupt-driven, not polled.
final class CarbonGlobalHotkeyMonitor: HotkeyMonitoring {
    private static let hotKeySignature = OSType(0x5343_5044) // "SCPD"

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var handler: (() -> Void)?

    func startMonitoring(_ combo: KeyCombo, handler: @escaping () -> Void) throws {
        stopMonitoring()
        self.handler = handler

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, eventRef, userData in
                guard let userData, let eventRef else { return OSStatus(eventNotHandledErr) }
                let monitor = Unmanaged<CarbonGlobalHotkeyMonitor>.fromOpaque(userData).takeUnretainedValue()
                var receivedHotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    eventRef,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &receivedHotKeyID
                )
                if status == noErr, receivedHotKeyID.signature == CarbonGlobalHotkeyMonitor.hotKeySignature {
                    monitor.handler?()
                }
                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &eventHandlerRef
        )
        guard installStatus == noErr else {
            throw HotkeyError.installHandlerFailed(status: installStatus)
        }

        let hotKeyID = EventHotKeyID(signature: Self.hotKeySignature, id: 1)
        let registerStatus = RegisterEventHotKey(
            combo.keyCode,
            combo.carbonModifierFlags,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        guard registerStatus == noErr else {
            throw HotkeyError.registrationFailed(status: registerStatus)
        }
    }

    func stopMonitoring() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
        handler = nil
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }
}
