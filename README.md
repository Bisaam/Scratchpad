# Scratchpad

A minimal fullscreen drawing overlay for macOS. Press a shortcut, the screen
dims, a pencil cursor appears, and you can draw directly on top of whatever
is on screen — useful for explaining something on a call, in a recording, or
to someone standing next to you. Press the shortcut again and it's gone.
Nothing to open, no toolbar to find, no window to manage.

The interaction model is inspired by the annotation style NetworkChuck uses
in his videos.

## Why

Most screen-annotation tools ask you to open an app, pick a window, and
fight with a toolbar before you can draw a single line. Scratchpad is meant
to have none of that: one global shortcut toggles a transparent overlay
across every display, and the only UI is a menu bar icon.

## Features

- Global keyboard shortcut toggles the overlay on/off, from any app
- Freehand pencil drawing with smoothed strokes
- Right-click-drag eraser (removes whichever whole stroke it touches)
- Configurable pencil color and thickness
- Drawings persist per display until you clear them
- Menu bar only — no Dock icon, no main window
- Dock and menu bar stay visible and usable while drawing
- Overlay covers every connected display, tracking hot-plug/undock
- Fade in/out animation with a configurable duration
- Configurable background dim
- Launch at login

## Requirements

- macOS 14 or later
- Swift 6 toolchain (Xcode 16+, or the Command Line Tools)

## Building

Scratchpad is a Swift Package Manager project — there is no `.xcodeproj`.

```sh
swift build -c release
```

To produce a real, launchable `Scratchpad.app` (with an Info.plist, app
icon, and ad-hoc code signature) instead of a bare executable:

```sh
./Scripts/build-app-bundle.sh release
open Scratchpad.app
```

### Running the test suite

```sh
swift test
```

> **Note:** on a machine with only the Command Line Tools installed (no
> Xcode.app), `swift test`'s runner silently exits `0` without actually
> running anything — a known gap in that environment. Until this project is
> opened in a full Xcode install, `SCRATCHPAD_SMOKE_TEST=1
> .build/debug/Scratchpad` runs an equivalent set of checks directly inside
> the app binary as a stand-in. See `JOURNAL.md` for details.

## Usage

| Action | Shortcut |
| --- | --- |
| Toggle overlay | ⌥⌘D (configurable in Preferences) |
| Draw | Left-click and drag |
| Erase a stroke | Right-click and drag over it |
| Clear the current display | Menu bar → Clear Pad |

Preferences (menu bar → Preferences) let you change the shortcut, pencil
color and thickness, background dim, fade duration, and whether Scratchpad
launches at login.

## Architecture

The app is split into small, single-responsibility modules, each isolated
behind a protocol where it touches the system:

```
Sources/Scratchpad/
├── App/            Composition root (AppDelegate, environment wiring)
├── Overlay/         Per-display overlay windows and visibility state
├── Drawing/         Stroke model and the in-memory drawing store
├── Rendering/       CAShapeLayer-based stroke rendering
├── Persistence/     Per-display JSON drawing storage
├── Preferences/     Settings model, storage, and SwiftUI preferences UI
├── StatusBar/       Menu bar item and menu
├── Hotkeys/         Global shortcut registration (Carbon)
├── Animations/       Fade in/out
└── Utilities/       Screen observation, launch-at-login, About panel
```

A few decisions worth knowing before diving in:

- **Overlay windows never take focus.** Each display's overlay is a
  non-activating `NSPanel`, so drawing on top of another app never steals
  its keyboard focus or brings it to the background.
- **Drawing state and overlay visibility are deliberately decoupled.**
  `OverlayState` only knows whether the overlay is visible; each display's
  `DrawingStore` only knows its own strokes. `OverlayCoordinator` is the only
  object that touches both, through two separate entry points, so visibility
  and drawing content can never accidentally couple to each other.
- **Persistence is plain JSON, not SwiftData** — one file per display under
  `~/Library/Application Support/Scratchpad/Drawings/`. This keeps the
  format simple to port to the Windows implementation below.
- **Rendering and stroke smoothing are pure, framework-free functions**
  (`StrokeSmoothing`, `StrokeGeometry`), independent of AppKit, so they're
  testable without spinning up any UI.

See `SPEC.md` for the full product spec and `JOURNAL.md` for a running log
of implementation decisions, trade-offs, and known issues as the project
evolves.

## Windows

A .NET 8 / WPF port targeting feature parity with the macOS app lives under
[`Windows/`](Windows/), mirroring the same module layout file-for-file where
the platform allows. See [`Windows/README.md`](Windows/README.md) for build
instructions. It has not yet been built or run on real Windows hardware —
see `JOURNAL.md` for the specific risk areas.

## Roadmap

Undo/redo, brush sizes, multiple colors, pressure-sensitive input, shape
tools, a laser pointer mode, and partial (pixel-level) erasing are planned.
See `SPEC.md` for the full version roadmap.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## License

MIT — see [`LICENSE`](LICENSE).
