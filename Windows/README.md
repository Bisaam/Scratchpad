# Scratchpad (Windows)

A .NET 8 / WPF port of the macOS Scratchpad overlay drawing app. See `../SPEC.md` and `../JOURNAL.md` for the shared spec and the port's architectural notes.

This code was originally written on macOS with no Windows machine available to build or run it, and had never been compiled. It has since been built, fixed, and verified on real Windows 10/11 hardware. Fixes made during that pass:

- `Scratchpad.csproj` had an invalid XML comment (`--` inside `<!-- -->`) that failed MSBuild project load.
- `UseWindowsForms` pulls in `System.Drawing`/`System.Windows.Forms` as *global* implicit usings, which collided with WPF's identically-named types (`Brushes`, `Color`, `Point`, `Pen`, `Cursor`, `SystemColors`, `Button`, `MouseEventArgs`, `KeyEventArgs`, `Application`, `FlowDirection.LeftToRight`, `HorizontalAlignment.Center`). Fixed by removing those two global usings (`<Using Remove=... />`) and relying on the explicit `using System.Drawing;`/`using System.Windows.Forms;` already present in the two files that actually need them (`TrayIconController`, `ScreenObserving`).
- `AppSettings.DisplayMode` (a property) and `AppSettings.DisplayMode` (a nested enum) had the same name (CS0102); the enum was renamed to `OverlayDisplayMode`.
- Several files (`PersistenceLocations.cs`, `FileDrawingRepository.cs`, `JsonSettingsPersistence.cs`, `TrayIconController.cs`, two test files) used `Path`/`File`/`Directory`/`IOException` without `using System.IO;` — added.
- **`App/app.manifest`**: the Windows SxS activation-context loader (which validates the embedded manifest resource far more strictly than a generic XML parser) refused to launch the exe at all with a generic "side-by-side configuration is incorrect... Invalid Xml syntax" error. Root cause, found by bisection: **any XML comment in the manifest** causes the rejection, regardless of position or content — not the DPI-awareness content itself, and not element order (both were suspected and ruled out first). The fix was a comment-free manifest; do not add `<!-- -->` comments back into this specific file.
- `PreferencesWindow`'s constructor called `InitializeComponent()` before assigning `_settingsStore`/`_launchAtLoginService`. Loading the XAML sets each `Slider`'s initial `Value`, which fires `ValueChanged` synchronously during BAML parsing — before those fields existed — crashing the app on first launch with a `NullReferenceException`. Fixed by assigning the fields (and raising `_isLoadingValues`) before `InitializeComponent()`.
- Three `OverlayCoordinatorTests` construct real WPF windows, which requires an STA thread; xUnit's default worker is MTA. Added `Xunit.StaFact` (v1.1.11, the xUnit v2-compatible line) and marked those three `[Fact]`s as `[StaFact]`.
- Added `Windows/global.json` pinning the SDK to 8.0.x so `net8.0-windows` resolves correctly even with a newer SDK also installed.

All 29 unit tests pass and the app has been run and manually exercised end-to-end (tray icon, Ctrl+Alt+D toggle, draw, erase, clear, preferences, quit).

## Requirements

- Windows 10/11
- .NET 8 SDK with the "Desktop development with .NET" (WPF/WinForms) workload

## Build & run

```
cd Windows
dotnet build
dotnet run --project Scratchpad
```

Or open `Scratchpad.sln` in Visual Studio 2022+ and run the `Scratchpad` project.

## Test

```
cd Windows
dotnet test
```

The `Scratchpad.Tests` project mirrors the macOS `Tests/` suite (`StrokeSmoothing`, `StrokeGeometry`, `DrawingStore`, `FileDrawingRepository`, `SettingsStore`, `KeyCombo`, `OverlayCoordinator`). None of these have been run; see JOURNAL.md for the specific risk areas (the hand-built cursor file, and the overlay tests constructing real WPF windows off the xUnit worker thread).

## Usage

- Default global shortcut: **Ctrl+Alt+D**, toggles the overlay.
- Left-click drag to draw, right-click drag to erase a whole stroke.
- A tray icon (bottom-right of the taskbar, may be under the "hidden icons" chevron) has Show/Hide, Clear Pad, Preferences, Launch at Login, About, and Quit.
- Drawings persist per-monitor under `%LOCALAPPDATA%\Scratchpad\Drawings`; settings under `%LOCALAPPDATA%\Scratchpad\settings.json`.
