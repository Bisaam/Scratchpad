import AppKit

/// The single object that holds both `OverlayState` and access to every
/// display's `DrawingStore`, so it can mediate between them without either
/// one knowing the other exists. Its two entry points are intentionally
/// disjoint: `toggle()` only ever mutates `OverlayState`, and `clearAll()`
/// only ever mutates drawing stores.
@MainActor
final class OverlayCoordinator {
    let overlayState: OverlayState

    private let drawingStoreFactory: DrawingStoreFactory
    private let renderer: DrawingRenderer
    private let animator: OverlayFadeAnimator
    private let settingsStore: SettingsStore
    private let screenObserving: ScreenObserving
    private var controllersByDisplay: [DisplayIdentifier: OverlayWindowController] = [:]
    private var screenChangeToken: AnyObject?

    init(
        overlayState: OverlayState,
        drawingStoreFactory: DrawingStoreFactory,
        renderer: DrawingRenderer,
        animator: OverlayFadeAnimator,
        settingsStore: SettingsStore,
        screenObserving: ScreenObserving
    ) {
        self.overlayState = overlayState
        self.drawingStoreFactory = drawingStoreFactory
        self.renderer = renderer
        self.animator = animator
        self.settingsStore = settingsStore
        self.screenObserving = screenObserving
        self.screenChangeToken = screenObserving.observeScreenChanges { [weak self] in
            self?.handleScreenChange()
        }
    }

    func toggle() {
        if overlayState.isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        for screen in screensForCurrentDisplayMode() {
            guard let displayID = DisplayIdentifier(screen: screen) else { continue }
            let controller = controller(for: screen, display: displayID)
            controller.updateDimOpacity(settingsStore.settings.backgroundDimOpacity)
            applyCurrentPencilStyle(to: displayID)
            controller.show(duration: settingsStore.settings.animationDuration)
        }
        overlayState.setVisible(true)
    }

    func hide() {
        for controller in controllersByDisplay.values {
            controller.hide(duration: settingsStore.settings.animationDuration)
        }
        overlayState.setVisible(false)
    }

    /// Erases every display's drawing, including displays with no
    /// currently-live overlay window (e.g. when `displayMode` is
    /// `.currentDisplayOnly`). Never touches `overlayState`.
    func clearAll() {
        for screen in screenObserving.screens {
            guard let displayID = DisplayIdentifier(screen: screen) else { continue }
            if let controller = controllersByDisplay[displayID] {
                controller.clearDrawing()
            } else {
                drawingStoreFactory.store(for: displayID).clear()
            }
        }
    }

    private func controller(for screen: NSScreen, display: DisplayIdentifier) -> OverlayWindowController {
        if let existing = controllersByDisplay[display] {
            existing.updateFrame(to: screen.frame)
            return existing
        }
        let controller = OverlayWindowController(
            screen: screen,
            display: display,
            drawingStore: drawingStoreFactory.store(for: display),
            renderer: renderer,
            animator: animator
        )
        controllersByDisplay[display] = controller
        return controller
    }

    private func screensForCurrentDisplayMode() -> [NSScreen] {
        switch settingsStore.settings.displayMode {
        case .allDisplays:
            return screenObserving.screens
        case .currentDisplayOnly:
            let mouseLocation = NSEvent.mouseLocation
            let screenUnderMouse = screenObserving.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
            let fallback = screenUnderMouse ?? NSScreen.main
            return fallback.map { [$0] } ?? []
        }
    }

    private func handleScreenChange() {
        let currentDisplayIDs = Set(screenObserving.screens.compactMap(DisplayIdentifier.init(screen:)))

        for (displayID, controller) in controllersByDisplay where !currentDisplayIDs.contains(displayID) {
            controller.hide(duration: 0)
            controllersByDisplay.removeValue(forKey: displayID)
            drawingStoreFactory.removeStore(for: displayID)
        }

        guard overlayState.isVisible else { return }
        for screen in screensForCurrentDisplayMode() {
            guard let displayID = DisplayIdentifier(screen: screen), controllersByDisplay[displayID] == nil else {
                continue
            }
            let controller = controller(for: screen, display: displayID)
            controller.updateDimOpacity(settingsStore.settings.backgroundDimOpacity)
            applyCurrentPencilStyle(to: displayID)
            controller.show(duration: settingsStore.settings.animationDuration)
        }
    }

    /// Applied to strokes started from now on, not to strokes already
    /// drawn, so a mid-session preference change never rewrites history.
    private func applyCurrentPencilStyle(to displayID: DisplayIdentifier) {
        drawingStoreFactory.store(for: displayID).updateDefaultStyle(
            color: settingsStore.settings.strokeColor,
            lineWidth: settingsStore.settings.strokeWidth
        )
    }
}
