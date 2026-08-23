# Scratchpad Development Journal

---

## Project Start

Date:
2026-07-28

---

### Vision

Create the simplest and smoothest fullscreen drawing overlay available on macOS.

The application should disappear when not needed and instantly become available with a single shortcut.

No unnecessary UI.

Minimal friction.

---

## Initial Technical Decisions

Platform

- macOS first

Language

- Swift

UI

- SwiftUI

Native APIs

- AppKit
- CoreGraphics
- CoreAnimation

Project Manager

- Swift Package Manager where practical

Reference Project

- LinearMouse

---

## Planned Architecture

Separate modules:

- Overlay
- Drawing
- Rendering
- Hotkeys
- Settings
- Status Bar
- Persistence
- Animation

The rendering engine should remain independent from the window system.

---

## Open Questions

- Best drawing backend — resolved: `CAShapeLayer` per stroke, built by a `DrawingRenderer` protocol (`CAShapeLayerStrokeRenderer`). GPU-composited once drawn; only the in-progress stroke's layer mutates per `mouseDragged`.
- Stroke smoothing algorithm — resolved: quadratic curve through the midpoint of each consecutive point pair (`StrokeSmoothing`), a pure/testable function with no AppKit dependency.
- Cursor implementation — resolved: `drawing-icon.png`, bundled as an SPM resource and loaded via `Bundle.module` into an `NSCursor` (`PencilCursor`). An SF Symbol was tried first but the user reported it rendering as a plain crosshair.
- Retina rendering strategy — not explicitly tuned; relies on `CALayer`/`NSView`'s automatic `contentsScale` following the window's backing scale. Not yet stress-tested on a HiDPI + non-HiDPI mixed monitor setup.
- Multi-monitor synchronization — resolved architecturally: one `DrawingStore` per `DisplayIdentifier` (`CGDirectDisplayID`), `OverlayCoordinator` diffs screens on `didChangeScreenParametersNotification` to add/remove windows. Not yet stress-tested against real hot-plug/undock hardware events.
- Best persistence format — resolved: plain `Codable` JSON, one file per display, under `~/Library/Application Support/Scratchpad/Drawings/` — deliberately not SwiftData, to keep the format portable to a future Windows port.

---

## Future Improvements

Pressure-sensitive input

Undo/Redo

Laser pointer mode

Infinite canvas

Shape tools

OCR

Screen annotation

Screen recording integration

Collaboration mode

Windows implementation

Partial/pixel erasing (v0.1's eraser removes whole strokes only)

Migrate from Swift Package Manager to a real Xcode project once Xcode.app is installed on a build machine

---

## Technical Debt

- `Sources/Scratchpad/App/DevSmokeTest.swift` and the `SCRATCHPAD_SMOKE_TEST` env-var hook in `ScratchpadApp.init()` are a temporary stand-in for `swift test` (see the v0.1 entry below for why) and should be deleted once tests run for real in Xcode.
- `CGDirectDisplayID` can change across hardware reconfiguration for external monitors; per-display persistence files are keyed by it, so a reconfigured display's prior drawing may not reattach. Acceptable for v0.1, not solved.
- App Sandbox has not been evaluated or enabled. Deferred to a distribution-focused milestone; none of the current APIs (Carbon hotkey, `SMAppService`, JSON file I/O) are known to need it disabled.
- Multi-monitor hot-plug/undock handling (`OverlayCoordinator.handleScreenChange`) is implemented but has only been exercised via unit/smoke tests with a stubbed screen list, not real hardware.

---

## v0.1 Implementation — 2026-07-28

### Work completed

Built the entire v0.1 milestone (SPEC.md roadmap: overlay, drawing, status bar, preferences, persistence) from an empty repository in one session, followed by a user-feedback round after hands-on testing on a real Mac. Every module in the "Planned Architecture" list above now exists: `Overlay/`, `Drawing/`, `Rendering/`, `Persistence/`, `Preferences/`, `StatusBar/`, `Hotkeys/`, `Animations/`, `Utilities/`, plus an `App/` composition root.

Feedback-round additions (requested after the first live test, ahead of SPEC.md's original v0.2+ roadmap):
- Pencil color and thickness are now live Preferences (`AppSettings.strokeColor`/`strokeWidth`), not fixed constants.
- A right-click-drag eraser that removes whichever whole stroke it touches.
- The overlay no longer covers the Dock or menu bar.
- The drawing cursor is the app's own icon, not a system symbol.

### Architectural decisions

- **Build system**: Swift Package Manager, not an Xcode project. This machine has only the Command Line Tools installed (no `Xcode.app`), so `xcodebuild`/`.xcodeproj` were not usable here. `Package.swift` plus `Scripts/build-app-bundle.sh` assemble a real, ad-hoc-signed `Scratchpad.app` (Info.plist, `AppIcon.icns` via `sips`/`iconutil`, code signing) from the SPM executable. The source tree is organized exactly as an Xcode target's would be, so migrating to a real `.xcodeproj` later is a low-effort, mechanical step, not a rewrite.
- **State decoupling**: `OverlayState` holds exactly one field (`isVisible`); each display's `DrawingStore` holds only that display's strokes. `OverlayCoordinator` is the only object that holds both, and exposes disjoint `toggle()` (visibility only) / `clearAll()` (drawing only) entry points — enforced by `OverlayCoordinatorTests` and mirrored smoke checks.
- **Persistence**: plain `Codable` JSON, one file per display keyed by `CGDirectDisplayID`, under Application Support — not SwiftData, to keep the format portable to a future Windows port.
- **Rendering**: one `CAShapeLayer` per completed stroke (GPU-composited); only the in-progress stroke's path mutates during a drag. `StrokeSmoothing` (curve fitting) and `StrokeGeometry` (point-to-polyline distance, used by the eraser) are pure functions with no AppKit dependency.
- **Hotkey**: Carbon's `RegisterEventHotKey`, not an `NSEvent` global monitor — no Accessibility/Input Monitoring permission prompt, fires regardless of which app is frontmost.
- **Overlay window**: `NSPanel`, `.nonactivatingPanel`, `canBecomeKey`/`canBecomeMain` both `false` so it never steals keyboard focus. Window level is set to *one below the system Dock's* (`CGWindowLevelForKey(.dockWindow) - 1`) rather than `.screenSaver` — the original `.screenSaver` level visually covered the Dock and menu bar, which the user flagged after the first live test; the new level keeps the overlay above ordinary app windows while the Dock, menu bar, and this app's own status item all stay visible and clickable on top of it.
- **Preferences**: SwiftUI content (`PreferencesView`) hosted in an AppKit-owned `NSWindow` via `NSHostingController`. A custom `KeyRecorderView`/`ShortcutRecorderView` captures the global shortcut; `ColorPicker`/`Slider` bind to the new pencil color/thickness settings through a small `StrokeColor <-> SwiftUI.Color` bridge kept at the UI edge (`StrokeColor` itself stays framework-agnostic).
- **Eraser**: right-click-down/drag hit-tests the cursor point against every stroke's polyline (distance <= a fixed tolerance + that stroke's own half-width) and removes any whole stroke it touches, via `DrawingStore.removeStrokes(touching:tolerance:)`. Whole-line erase only; no partial/pixel erasing.
- **Cursor**: `drawing-icon.png` is copied into `Sources/Scratchpad/Resources/PencilCursor.png`, declared as an SPM `.copy` resource, and loaded through the generated `Bundle.module` accessor into an `NSCursor`.

### Discovered issues / environment gotchas

- **`swift test` does not execute under bare Command Line Tools.** The Swift Testing framework compiles and links fine, but its runner process (`swiftpm-testing-helper`) silently no-ops and exits 0 with zero output regardless of pass/fail — confirmed by deliberately breaking a test and seeing the same clean exit. This appears to be a gap in CLT-only environments (no full Xcode). Worked around with `Sources/Scratchpad/App/DevSmokeTest.swift`, a hook behind the `SCRATCHPAD_SMOKE_TEST` environment variable that mirrors every assertion in `Tests/` and runs inside the real app binary (`SCRATCHPAD_SMOKE_TEST=1 .build/debug/Scratchpad`). All 46 checks pass as of this entry. The real `Tests/` target files are still the ones that should be trusted long-term — re-run them for real via `swift test` (or Xcode's test navigator) once this project is opened on a machine with full Xcode installed, and delete `DevSmokeTest.swift` at that point.
- **Copied files can carry Finder/screen-capture extended attributes that break code signing.** `drawing-icon.png` (apparently saved from a screenshot) carried `com.apple.FinderInfo` and `kMDItemIsScreenCapture`-family attributes; `cp`-ing it into the resource bundle propagated them, and `codesign` refused to sign the result ("resource fork, Finder information, or similar detritus not allowed"). Fixed by running `xattr -cr` on the assembled `.app` immediately before signing in `build-app-bundle.sh`.
- **SwiftPM resource bundles aren't automatically part of a manually-assembled `.app`.** `resources:` in `Package.swift` get compiled into a `<Package>_<Target>.bundle` folder next to the built executable, not embedded in it. `build-app-bundle.sh` now copies any `*.bundle` folder into `Contents/Resources/`, which is enough for the generated `Bundle.module` accessor to find it (it checks `Bundle.main.resourceURL` among its candidates).
- **`NSWindow`'s `screen:` initializer is a convenience initializer, not designated.** A subclass must call the 4-argument `init(contentRect:styleMask:backing:defer:)`; the screen is inferred from `contentRect`'s origin.
- **Swift 6 strict concurrency requires `@MainActor` on essentially every AppKit-touching type here** (`OverlayCoordinator`, `StatusBarController`, `PencilCursor`, the `ScreenObserving`/`OverlayFadeAnimator` protocols, etc.), since the app is single-threaded UI logic throughout. `NotificationCenter`'s and `NSAnimationContext`'s completion closures needed an explicit `MainActor.assumeIsolated { … }` inside them, since their closure parameter types aren't statically isolated even though both APIs are documented to always call back on the main thread.

### Verification

Automated: 46/46 `DevSmokeTest` checks pass (persistence, settings, rendering, drawing store, drawing canvas, overlay/drawing decoupling, hotkey registration, status bar/preferences construction, pencil style + eraser). Manual: built and launched the real `Scratchpad.app` on the user's live Mac; user confirmed the app works after the feedback-round fixes (Dock/menu bar stay visible, pencil color/thickness in Preferences, right-click eraser, custom cursor).

---

## Windows port (v0.1 parity) — 2026-07-29

### Work completed

Built the Windows implementation of Scratchpad from scratch under `Windows/`, targeting full v0.1 feature parity with the macOS app: overlay fade in/out, freehand drawing with quadratic-curve smoothing, right-click whole-stroke eraser, per-monitor drawing state, JSON persistence, a tray icon with a context menu, a Preferences window (shortcut recorder, display mode, launch at login, background dim, animation duration, pencil color/thickness), and a global hotkey defaulting to **Ctrl+Alt+D** (the user's requested Windows shortcut; the macOS default remains ⌥⌘D, deliberately not the same combo since Ctrl+Alt+D is the natural Windows-idiomatic choice, not a translation of the Mac one).

Stack: **.NET 8 / WPF** (`Windows/Scratchpad.sln`), chosen over WinUI 3 and Avalonia after asking the user -- WPF has the most mature support for exactly what this app needs (transparent click-through-configurable topmost windows, `RegisterHotKey` P/Invoke, retained-mode shape rendering), and needing `System.Windows.Forms` (`UseWindowsForms=true`) for `Screen` enumeration, `NotifyIcon`, and `ColorDialog` alongside WPF is a first-party-API gap-filling pattern directly analogous to the macOS app pulling in AppKit alongside SwiftUI.

**This was authored entirely on macOS with no Windows machine, .NET SDK, or WPF toolchain available in this environment.** None of it has been compiled, built, or run. Everything below reflects careful reading of the actual .NET/WPF/Win32 APIs involved, not verification. Build it on a real Windows machine (see `Windows/README.md`) and report back the first compiler errors -- there will likely be some.

### Architectural decisions

The folder layout mirrors the macOS `Sources/Scratchpad/` tree exactly (App, Overlay, Drawing, Rendering, Persistence, Preferences, Hotkeys, Animations, Utilities), plus a `TrayIcon/` folder in place of `StatusBar/`. Most types are named and structured to directly parallel their Swift counterpart (e.g. `DrawingStore`, `OverlayCoordinator`, `StrokeSmoothing`, `KeyCombo`), with the same protocol/interface seams (`IDrawingRenderer`, `IHotkeyMonitoring`, `IOverlayFadeAnimator`, `IScreenObserving`, `IDrawingRepository`, `ISettingsPersistence`) so the same test-doubling patterns apply.

- **Immutable settings model**: `AppSettings` is a C# `record` with `required init` properties, not a mutable class -- closer to the Swift `struct`'s value semantics than a mutable class would be. This means Preferences UI code can't do SwiftUI-style `$settingsStore.settings.strokeColor` two-way binding (WPF's binding engine expects a settable path with property-level change notification, which an immutable record can't offer). Every control in `PreferencesWindow.xaml.cs` instead reads `_settingsStore.Settings`, produces an updated copy via a `with` expression, and writes the whole record back -- deliberately avoiding WPF data-binding "magic" I couldn't verify without a compiler, in favor of explicit, readable event-handler code.
- **Hotkey**: `RegisterHotKey`/`UnregisterHotKey` via a hidden `HwndSource` with an `HWND_MESSAGE` parent (`Hotkeys/Win32GlobalHotkeyMonitor.cs`) -- the direct Windows analog of the macOS app's Carbon `RegisterEventHotKey` choice, for the same reason (no Accessibility-style permission prompt, fires regardless of foreground app). `KeyCombo.Modifiers` is typed as `System.Windows.Input.ModifierKeys` specifically because its flag values (Alt=1, Control=2, Shift=4, Windows=8) happen to equal `RegisterHotKey`'s `MOD_*` constants bit-for-bit, so no translation layer is needed -- same rationale as the macOS `KeyCombo` storing Carbon's flags directly.
- **Overlay window**: `OverlayWindow` (`Overlay/OverlayWindow.cs`) is a borderless, transparent, `Topmost` WPF `Window` with `ShowActivated = false` plus a `WS_EX_TOOLWINDOW` extended style applied in `OnSourceInitialized` -- together the Windows analog of the macOS app's `.nonactivatingPanel` + `canBecomeKey == false` (never steals focus, never appears in Alt-Tab/taskbar). Its frame is deliberately the target monitor's *working area*, not full bounds: a borderless topmost window that exactly covers a monitor is also the heuristic Windows' shell uses to detect "an app wants fullscreen," which can auto-hide the taskbar as a side effect -- the exact Windows analog of the Dock-auto-hide problem hit (and only partially fixed, then reverted per the user's request) on the macOS side. Excluding the taskbar's strip from the frame avoids the Windows version of that problem by construction rather than needing a fix after the fact. Known gap: if the user's taskbar is set to auto-hide, `Screen.WorkingArea` equals `Screen.Bounds` (no reserved strip), so the overlay would cover full bounds in that specific configuration -- not solved, flagged here the same way the macOS journal flags its own unresolved edge cases.
- **Re-showing a hidden window without activating it**: WPF's `ShowActivated` property only takes effect on a window's *first* `Show()`; re-showing after `Hide()` activates it regardless. `OverlayWindowController.Show()` works around this by calling `ShowWindow(hwnd, SW_SHOWNOACTIVATE)` directly via P/Invoke for every re-show after the first -- the Win32 equivalent of the macOS app's `orderFrontRegardless()`.
- **Cursor**: Windows/WPF has no equivalent of the macOS non-activating-panel cursor-rect limitation (`WM_SETCURSOR` is honored for any window under the pointer regardless of activation state), so `DrawingCanvas.Cursor` is just set once and works, unlike `DrawingCanvasView`'s `NSTrackingArea` workaround on the Mac. The image itself was pre-packaged into a real `.cur` file (`Resources/PencilCursor.cur`) rather than converted from a bitmap at runtime, to preserve `drawing-icon.png`'s alpha channel -- built by hand-assembling a minimal ICONDIR/ICONDIRENTRY container around the PNG bytes (the same PNG-in-ICO mechanism Windows has supported since Vista), since no Windows machine or image tool capable of producing a real `.cur` was available. **This has not been confirmed to load.** `PencilCursor.Load()` catches any exception and falls back to `Cursors.Cross` specifically because of that risk -- see Discovered issues below.
- **Drawing rendering**: `Rendering/PathStrokeRenderer` renders each stroke as its own WPF `Path` with a frozen `StreamGeometry`, added to a `Canvas` -- the retained-mode analog of the macOS app's one-`CAShapeLayer`-per-stroke approach. `StrokeSmoothing` and `StrokeGeometry` are verbatim algorithmic ports (quadratic-curve-through-midpoint smoothing; point-to-polyline distance for the eraser), kept free of any WPF/UI type exactly like their Swift originals.
- **Persistence**: JSON files under `%LOCALAPPDATA%\Scratchpad\`, one per display (keyed by `Screen.DeviceName`, e.g. `\\.\DISPLAY1`, sanitized for the filename) plus a single `settings.json` -- the macOS app keeps drawings as JSON files too but settings in `UserDefaults`; settings were kept as a plain file here instead of the Windows registry so both live under the same app-data folder.
- **Display identity**: `DisplayIdentifier` wraps `Screen.DeviceName` rather than `Screen` itself (recreated by .NET on every configuration change), mirroring the macOS app's `CGDirectDisplayID`-wrapping `DisplayIdentifier` — and inherits the same known limitation: device names are not guaranteed stable across every hardware reconfiguration.
- **Launch at login**: `HKEY_CURRENT_USER\...\Run` registry key, the closest per-user, permission-prompt-free Windows analog of the macOS app's `SMAppService`.
- **Tray icon**: `NotifyIcon`/`ContextMenuStrip` (WinForms), mirroring the macOS app's raw `NSStatusItem`/`NSMenu` choice over a higher-level API, for the same reason (precise control over the dynamic Show/Hide label and Launch-at-Login checkmark, refreshed on menu-open rather than polled).

### Discovered issues / unverified risk areas (flagging honestly since none of this has run)

- **The hand-built `PencilCursor.cur` is the single highest-risk artifact in this port.** It was assembled by a one-off Python script (not part of the build) wrapping a `sips`-resized 32x32 PNG in a minimal ICONDIR/ICONDIRENTRY container with a (4,4) top-left hotspot. PNG-payload icons are Vista+ standard for `.ico`; cursors share the same container format, but this specific combination was never loaded by an actual Windows cursor API in this session. `PencilCursor.Load()` catches any exception and falls back to `Cursors.Cross` so a bad file degrades to a visible (if wrong) cursor rather than crashing the app via a `TypeInitializationException` on first access -- if it falls back, the fix is almost certainly to regenerate `Resources/PencilCursor.cur` from `drawing-icon.png` using a real Windows-side tool (e.g. an online/CLI ico/cur converter, or GDI+ `Icon` construction from a raw DIB instead of a PNG payload) rather than debugging the hand-rolled container further.
- **`OverlayCoordinatorTests` construct real `OverlayWindowController`/`OverlayWindow` (WPF `Window`) instances** via `Toggle()`/`Show()`, same as the macOS test suite does with real `NSPanel`s. Whether plain xUnit `[Fact]` (running on an MTA thread pool, no pumped `Dispatcher`) is sufficient for WPF `Window`/`DispatcherTimer` construction, or whether these need an STA thread (e.g. via `Xunit.StaFact`), was not verified.
- **DPI**: `App/app.manifest` declares Per-Monitor-V2 DPI awareness, and `OverlayWindow` positions itself via raw `MoveWindow` in physical pixels (bypassing WPF's logical-unit `Left`/`Top`/`Width`/`Height`, whose DPI-virtualization behavior is a frequent source of multi-monitor placement bugs) specifically to sidestep that whole class of issue -- not stress-tested against a real mixed-DPI multi-monitor setup, same caveat the macOS journal already carries for its own multi-monitor code.
- **`dotnet build`/`dotnet test` have never been run against this code.** Expect at least minor compile errors (a missing `using`, a slightly wrong WPF/P/Invoke signature) on the first real build.

### Verification

None yet -- no Windows machine, .NET SDK, or WPF toolchain was available in this session. See `Windows/README.md` for build/run/test instructions; the next step is building on a real Windows machine and fixing whatever the compiler and the discovered-issues list above surface.

---

Claude should update this journal after every significant implementation.
