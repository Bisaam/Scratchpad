# Scratchpad (Windows)

A .NET 8 / WPF port of the macOS Scratchpad overlay drawing app. See `../SPEC.md` and `../JOURNAL.md` for the shared spec and the port's architectural notes.

This code was written on macOS with no Windows machine available to build or run it. It has not been compiled. Build it on Windows and report back anything that doesn't compile or behave as described.

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
