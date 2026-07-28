import AppKit
import Carbon.HIToolbox
import CoreGraphics
import Foundation
import QuartzCore

// TEMPORARY, development-only: `swift test`'s runner process does not
// execute under this machine's bare Command Line Tools install (no Xcode.app
// -- see JOURNAL.md), so this file stands in for manually driving the same
// assertions as Tests/ during the build. Removed before the app ships;
// `swift test` should be re-run for real once opened in Xcode.
@MainActor
enum DevSmokeTest {

    static func runIfRequested() -> Never? {
        guard ProcessInfo.processInfo.environment["SCRATCHPAD_SMOKE_TEST"] != nil else { return nil }
        runFileDrawingRepositoryChecks()
        runSettingsStoreChecks()
        runStrokeSmoothingChecks()
        runDrawingStoreChecks()
        runDrawingCanvasViewChecks()
        runOverlayCoordinatorChecks()
        runKeyComboChecks()
        runStatusBarAndPreferencesChecks()
        runPencilStyleAndEraserChecks()
        print("ALL SMOKE TESTS PASSED")
        exit(0)
    }

    private static func check(_ condition: Bool, _ message: String) {
        guard condition else { fatalError("FAILED: \(message)") }
        print("ok: \(message)")
    }

    private static func runFileDrawingRepositoryChecks() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ScratchpadSmokeTest-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = FileDrawingRepository(directory: directory)

        check(repository.load(for: DisplayIdentifier(rawValue: 1)) == .empty, "missing display returns empty document")

        let display = DisplayIdentifier(rawValue: 42)
        let stroke = Stroke(points: [StrokePoint(x: 0, y: 0), StrokePoint(x: 10, y: 10)])
        let document = DrawingDocument(strokes: [stroke], updatedAt: Date(timeIntervalSince1970: 0))
        try! repository.save(document, for: display)
        check(repository.load(for: display) == document, "saved document round-trips through load")

        try! repository.clear(for: display)
        check(repository.load(for: display) == .empty, "clear removes the saved document")

        let first = DisplayIdentifier(rawValue: 1)
        let second = DisplayIdentifier(rawValue: 2)
        let firstDocument = DrawingDocument(strokes: [Stroke()], updatedAt: Date())
        try! repository.save(firstDocument, for: first)
        check(repository.load(for: first) == firstDocument, "first display persisted")
        check(repository.load(for: second) == .empty, "second display unaffected")
    }

    private final class InMemorySettingsPersistence: SettingsPersisting {
        private(set) var savedSettings: AppSettings?
        var settingsToLoad: AppSettings?
        func loadSettings() -> AppSettings? { settingsToLoad }
        func saveSettings(_ settings: AppSettings) { savedSettings = settings }
    }

    private static func runSettingsStoreChecks() {
        do {
            let persistence = InMemorySettingsPersistence()
            let store = SettingsStore(persistence: persistence)
            check(store.settings == .defaultValue, "falls back to default value when nothing is persisted")
        }
        do {
            let persistence = InMemorySettingsPersistence()
            var custom = AppSettings.defaultValue
            custom.backgroundDimOpacity = 0.5
            persistence.settingsToLoad = custom
            let store = SettingsStore(persistence: persistence)
            check(store.settings == custom, "loads previously persisted settings")
        }
        do {
            let persistence = InMemorySettingsPersistence()
            let store = SettingsStore(persistence: persistence)
            store.settings.backgroundDimOpacity = 0.15
            check(persistence.savedSettings?.backgroundDimOpacity == 0.15, "changing settings persists the new value")
        }
        do {
            let persistence = InMemorySettingsPersistence()
            persistence.settingsToLoad = .defaultValue
            let store = SettingsStore(persistence: persistence)
            store.settings = .defaultValue
            check(persistence.savedSettings == nil, "setting the same value does not trigger an unnecessary save")
        }
    }

    private static func runStrokeSmoothingChecks() {
        check(StrokeSmoothing.segments(for: []).isEmpty, "no points produces no segments")

        let a = StrokePoint(x: 0, y: 0)
        let b = StrokePoint(x: 10, y: 0)
        let c = StrokePoint(x: 20, y: 10)
        let segments = StrokeSmoothing.segments(for: [a, b, c])
        let expectedMidpoint = StrokePoint(x: 15, y: 5)
        check(
            segments == [.move(to: a), .quadCurve(to: expectedMidpoint, control: b), .line(to: c)],
            "three points produce one smoothed curve then a line to the end"
        )

        let renderer = CAShapeLayerStrokeRenderer()
        let hostLayer = CALayer()
        let stroke = Stroke(points: [a, b, c])
        let strokeLayer = renderer.addLayer(for: stroke, to: hostLayer)
        check(hostLayer.sublayers?.count == 1, "adding a stroke layer attaches it to the host layer")
        check(strokeLayer.path != nil, "rendered stroke has a non-nil path")
        renderer.removeAllLayers(from: hostLayer)
        check((hostLayer.sublayers ?? []).isEmpty, "removeAllLayers clears every sublayer")
    }

    private final class MockDrawingRepository: DrawingRepository {
        var documentsByDisplay: [DisplayIdentifier: DrawingDocument] = [:]
        func load(for display: DisplayIdentifier) -> DrawingDocument { documentsByDisplay[display] ?? .empty }
        func save(_ document: DrawingDocument, for display: DisplayIdentifier) throws { documentsByDisplay[display] = document }
        func clear(for display: DisplayIdentifier) throws { documentsByDisplay.removeValue(forKey: display) }
    }

    private static func runDrawingStoreChecks() {
        let display = DisplayIdentifier(rawValue: 1)

        let repository = MockDrawingRepository()
        let persistedStroke = Stroke(points: [StrokePoint(x: 0, y: 0)])
        repository.documentsByDisplay[display] = DrawingDocument(strokes: [persistedStroke], updatedAt: Date())
        let loadedStore = DrawingStore(display: display, repository: repository)
        check(loadedStore.strokes == [persistedStroke], "loads persisted strokes on init")

        let store = DrawingStore(display: display, repository: MockDrawingRepository())
        store.beginStroke(at: CGPoint(x: 0, y: 0))
        store.appendPoint(CGPoint(x: 5, y: 5))
        store.appendPoint(CGPoint(x: 10, y: 10))
        store.endStroke()
        check(store.strokes.count == 1, "begin/append/end builds one completed stroke")
        check(store.strokeInProgress == nil, "no stroke in progress after endStroke")

        store.endStroke()
        check(store.strokes.count == 1, "endStroke without a stroke in progress does nothing")

        store.beginStroke(at: CGPoint(x: 2, y: 2))
        store.clear()
        check(store.strokes.isEmpty, "clear removes all strokes")
        check(store.strokeInProgress == nil, "clear removes any stroke in progress")

        let factory = DrawingStoreFactory(repository: MockDrawingRepository())
        let first = factory.store(for: DisplayIdentifier(rawValue: 10))
        let second = factory.store(for: DisplayIdentifier(rawValue: 10))
        check(first === second, "factory returns the same store instance for the same display")
        check(factory.allStores.count == 1, "factory retains exactly one store per display")
    }

    private static func runDrawingCanvasViewChecks() {
        let repository = MockDrawingRepository()
        let display = DisplayIdentifier(rawValue: 99)
        let persistedStroke = Stroke(points: [StrokePoint(x: 0, y: 0), StrokePoint(x: 5, y: 5)])
        repository.documentsByDisplay[display] = DrawingDocument(strokes: [persistedStroke], updatedAt: Date())
        let store = DrawingStore(display: display, repository: repository)

        let canvas = DrawingCanvasView(store: store, renderer: CAShapeLayerStrokeRenderer())
        canvas.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        check(canvas.layer?.sublayers?.count == 1, "existing strokes are rendered when the canvas is created")

        canvas.clearDrawing()
        check(store.strokes.isEmpty, "clearDrawing empties the drawing store")
        check((canvas.layer?.sublayers ?? []).isEmpty, "clearDrawing removes every rendered layer")
    }

    private final class SpyFadeAnimator: OverlayFadeAnimator {
        func fadeIn(_ window: NSWindow, duration: TimeInterval) {}
        func fadeOut(_ window: NSWindow, duration: TimeInterval, completion: @escaping @MainActor () -> Void) {
            completion()
        }
    }

    private final class StubScreenObserving: ScreenObserving {
        var screens: [NSScreen] { NSScreen.screens }
        func observeScreenChanges(_ handler: @escaping @MainActor () -> Void) -> AnyObject { NSObject() }
    }

    private final class NeverPersistingSettings: SettingsPersisting {
        func loadSettings() -> AppSettings? { nil }
        func saveSettings(_ settings: AppSettings) {}
    }

    private static func runOverlayCoordinatorChecks() {
        guard let screen = NSScreen.main, let display = DisplayIdentifier(screen: screen) else {
            print("skipped: overlay coordinator checks (no NSScreen.main in this environment)")
            return
        }

        let overlayState = OverlayState()
        let factory = DrawingStoreFactory(repository: MockDrawingRepository())
        let coordinator = OverlayCoordinator(
            overlayState: overlayState,
            drawingStoreFactory: factory,
            renderer: CAShapeLayerStrokeRenderer(),
            animator: SpyFadeAnimator(),
            settingsStore: SettingsStore(persistence: NeverPersistingSettings()),
            screenObserving: StubScreenObserving()
        )

        let store = factory.store(for: display)
        store.beginStroke(at: .zero)
        store.appendPoint(CGPoint(x: 1, y: 1))
        store.endStroke()
        let strokesBeforeToggle = store.strokes

        check(overlayState.isVisible == false, "overlay starts hidden")
        coordinator.toggle()
        check(overlayState.isVisible == true, "toggle shows the overlay")
        check(store.strokes == strokesBeforeToggle, "toggling visibility never mutates a drawing store")
        coordinator.toggle()
        check(overlayState.isVisible == false, "toggle hides the overlay again")

        coordinator.toggle()
        let visibilityBeforeClear = overlayState.isVisible
        coordinator.clearAll()
        check(overlayState.isVisible == visibilityBeforeClear, "clearAll never mutates overlay visibility")
        check(store.strokes.isEmpty, "clearAll erases strokes on every connected display")
    }

    private static func runKeyComboChecks() {
        check(KeyCombo.default.displayString == "⌥⌘D", "default shortcut displays as ⌥⌘D")

        let combo = KeyCombo(
            keyCode: UInt32(kVK_ANSI_S),
            carbonModifierFlags: UInt32(controlKey | optionKey | shiftKey | cmdKey)
        )
        check(combo.displayString == "⌃⌥⇧⌘S", "display string orders modifiers control-option-shift-command")

        do {
            let data = try JSONEncoder().encode(KeyCombo.default)
            let decoded = try JSONDecoder().decode(KeyCombo.self, from: data)
            check(decoded == KeyCombo.default, "KeyCombo round-trips through JSON")
        } catch {
            fatalError("FAILED: KeyCombo Codable round-trip threw \(error)")
        }

        let monitor = CarbonGlobalHotkeyMonitor()
        do {
            try monitor.startMonitoring(.default) {}
            monitor.stopMonitoring()
            check(true, "registering and unregistering the default global shortcut does not throw")
        } catch {
            fatalError("FAILED: hotkey registration threw \(error)")
        }
    }

    private static func runStatusBarAndPreferencesChecks() {
        let launchAtLoginService = SMAppServiceLaunchAtLoginService()
        _ = launchAtLoginService.isEnabled
        check(true, "reading launch-at-login status does not crash")

        let settingsStore = SettingsStore(persistence: NeverPersistingSettings())
        let preferencesWindowController = PreferencesWindowController(
            settingsStore: settingsStore,
            launchAtLoginService: launchAtLoginService
        )
        check(preferencesWindowController.window != nil, "preferences window is constructed")

        let overlayState = OverlayState()
        let factory = DrawingStoreFactory(repository: MockDrawingRepository())
        let coordinator = OverlayCoordinator(
            overlayState: overlayState,
            drawingStoreFactory: factory,
            renderer: CAShapeLayerStrokeRenderer(),
            animator: SpyFadeAnimator(),
            settingsStore: settingsStore,
            screenObserving: StubScreenObserving()
        )
        let statusBarController = StatusBarController(
            overlayCoordinator: coordinator,
            launchAtLoginService: launchAtLoginService,
            preferencesWindowController: preferencesWindowController,
            aboutPanelPresenter: AboutPanelPresenter()
        )
        check(true, "status bar controller is constructed without crashing: \(statusBarController)")
    }

    private static func runPencilStyleAndEraserChecks() {
        check(PencilCursor.cursor.image.size != .zero, "pencil cursor loads a non-empty image from the bundled resource")

        check(AppSettings.defaultValue.strokeColor == .default, "default settings use the default stroke color")
        check(AppSettings.defaultValue.strokeWidth == Stroke.defaultLineWidth, "default settings use the default stroke width")

        let customColor = StrokeColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 1)
        let roundTripped = StrokeColor(swiftUIColor: customColor.swiftUIColor)
        let isCloseEnough =
            abs(roundTripped.red - customColor.red) < 0.01 &&
            abs(roundTripped.green - customColor.green) < 0.01 &&
            abs(roundTripped.blue - customColor.blue) < 0.01
        check(isCloseEnough, "StrokeColor round-trips through SwiftUI Color")

        let store = DrawingStore(display: DisplayIdentifier(rawValue: 123), repository: MockDrawingRepository())
        store.updateDefaultStyle(color: customColor, lineWidth: 12)
        store.beginStroke(at: .zero)
        store.appendPoint(CGPoint(x: 1, y: 1))
        store.endStroke()
        check(store.strokes.last?.color == customColor, "updateDefaultStyle changes the color of new strokes")
        check(store.strokes.last?.lineWidth == 12, "updateDefaultStyle changes the width of new strokes")

        // A horizontal stroke from (0,0) to (100,0); a point right on top of
        // it should erase it, a point far away should leave it alone.
        let eraserStore = DrawingStore(display: DisplayIdentifier(rawValue: 124), repository: MockDrawingRepository())
        eraserStore.beginStroke(at: CGPoint(x: 0, y: 0))
        eraserStore.appendPoint(CGPoint(x: 100, y: 0))
        eraserStore.endStroke()
        let missedIDs = eraserStore.removeStrokes(touching: CGPoint(x: 50, y: 500), tolerance: 8)
        check(missedIDs.isEmpty && eraserStore.strokes.count == 1, "eraser misses a point far from any stroke")
        let hitIDs = eraserStore.removeStrokes(touching: CGPoint(x: 50, y: 2), tolerance: 8)
        check(hitIDs.count == 1 && eraserStore.strokes.isEmpty, "eraser removes the whole stroke it touches")
    }
}
