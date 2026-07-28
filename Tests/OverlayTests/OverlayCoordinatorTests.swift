import AppKit
import Testing
@testable import Scratchpad

@MainActor
private final class SpyFadeAnimator: OverlayFadeAnimator {
    func fadeIn(_ window: NSWindow, duration: TimeInterval) {}
    func fadeOut(_ window: NSWindow, duration: TimeInterval, completion: @escaping @MainActor () -> Void) {
        completion()
    }
}

@MainActor
private final class StubScreenObserving: ScreenObserving {
    var screens: [NSScreen] { NSScreen.screens }
    func observeScreenChanges(_ handler: @escaping @MainActor () -> Void) -> AnyObject { NSObject() }
}

@MainActor
private func makeCoordinator() -> (OverlayCoordinator, OverlayState, DrawingStoreFactory) {
    let overlayState = OverlayState()
    let drawingStoreFactory = DrawingStoreFactory(repository: FileDrawingRepository(
        directory: FileManager.default.temporaryDirectory.appendingPathComponent("OverlayCoordinatorTests")
    ))
    let coordinator = OverlayCoordinator(
        overlayState: overlayState,
        drawingStoreFactory: drawingStoreFactory,
        renderer: CAShapeLayerStrokeRenderer(),
        animator: SpyFadeAnimator(),
        settingsStore: SettingsStore(persistence: InMemorySettingsPersistenceForOverlayTests()),
        screenObserving: StubScreenObserving()
    )
    return (coordinator, overlayState, drawingStoreFactory)
}

private final class InMemorySettingsPersistenceForOverlayTests: SettingsPersisting {
    func loadSettings() -> AppSettings? { nil }
    func saveSettings(_ settings: AppSettings) {}
}

@MainActor
struct OverlayCoordinatorTests {

    @Test func toggleNeverMutatesAnyDrawingStore() {
        let (coordinator, _, factory) = makeCoordinator()
        guard let screen = NSScreen.main, let display = DisplayIdentifier(screen: screen) else { return }
        let store = factory.store(for: display)
        store.beginStroke(at: .zero)
        store.appendPoint(CGPoint(x: 1, y: 1))
        store.endStroke()
        let strokesBeforeToggle = store.strokes

        coordinator.toggle()
        coordinator.toggle()

        #expect(store.strokes == strokesBeforeToggle)
    }

    @Test func toggleFlipsOverlayVisibility() {
        let (coordinator, overlayState, _) = makeCoordinator()
        #expect(overlayState.isVisible == false)
        coordinator.toggle()
        #expect(overlayState.isVisible == true)
        coordinator.toggle()
        #expect(overlayState.isVisible == false)
    }

    @Test func clearAllNeverMutatesOverlayVisibility() {
        let (coordinator, overlayState, _) = makeCoordinator()
        coordinator.toggle()
        let visibilityBeforeClear = overlayState.isVisible

        coordinator.clearAll()

        #expect(overlayState.isVisible == visibilityBeforeClear)
    }

    @Test func clearAllErasesStrokesOnEveryConnectedDisplay() {
        let (coordinator, _, factory) = makeCoordinator()
        guard let screen = NSScreen.main, let display = DisplayIdentifier(screen: screen) else { return }
        let store = factory.store(for: display)
        store.beginStroke(at: .zero)
        store.appendPoint(CGPoint(x: 1, y: 1))
        store.endStroke()

        coordinator.clearAll()

        #expect(store.strokes.isEmpty)
    }
}
