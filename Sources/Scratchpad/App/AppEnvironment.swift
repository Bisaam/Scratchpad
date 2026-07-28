import AppKit
import Observation

/// Constructs every protocol-typed dependency via initializer injection and
/// retains the object graph for the lifetime of the app. This is the single
/// place where concrete implementations are chosen; every other type in the
/// app depends only on protocols.
@MainActor
final class AppEnvironment {
    private let settingsStore: SettingsStore
    private let overlayCoordinator: OverlayCoordinator
    private let hotkeyMonitor: HotkeyMonitoring
    private let statusBarController: StatusBarController

    init() {
        let drawingRepository = FileDrawingRepository()
        let settingsStore = SettingsStore()
        let drawingStoreFactory = DrawingStoreFactory(repository: drawingRepository)

        let overlayCoordinator = OverlayCoordinator(
            overlayState: OverlayState(),
            drawingStoreFactory: drawingStoreFactory,
            renderer: CAShapeLayerStrokeRenderer(),
            animator: NSAnimationContextFadeAnimator(),
            settingsStore: settingsStore,
            screenObserving: NSScreenObserver()
        )

        let launchAtLoginService = SMAppServiceLaunchAtLoginService()
        let preferencesWindowController = PreferencesWindowController(
            settingsStore: settingsStore,
            launchAtLoginService: launchAtLoginService
        )
        let statusBarController = StatusBarController(
            overlayCoordinator: overlayCoordinator,
            launchAtLoginService: launchAtLoginService,
            preferencesWindowController: preferencesWindowController,
            aboutPanelPresenter: AboutPanelPresenter()
        )

        self.settingsStore = settingsStore
        self.overlayCoordinator = overlayCoordinator
        self.hotkeyMonitor = CarbonGlobalHotkeyMonitor()
        self.statusBarController = statusBarController

        registerHotkey()
        observeShortcutChanges()
    }

    private func registerHotkey() {
        try? hotkeyMonitor.startMonitoring(settingsStore.settings.globalShortcut) { [weak self] in
            self?.overlayCoordinator.toggle()
        }
    }

    /// `SettingsStore` is `@Observable`, not Combine-based, so reacting to a
    /// live shortcut change from outside SwiftUI means re-subscribing after
    /// every change -- the standard pattern for observing `@Observable`
    /// state imperatively.
    private func observeShortcutChanges() {
        withObservationTracking {
            _ = settingsStore.settings.globalShortcut
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.registerHotkey()
                self?.observeShortcutChanges()
            }
        }
    }
}
