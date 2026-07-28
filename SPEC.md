# Scratchpad Specification

## Project

Scratchpad

A minimal fullscreen drawing overlay for explaining ideas visually.

Primary inspiration:

NetworkChuck

---

# Platform

Phase 1

macOS

Phase 2

Windows

Architecture should make Windows implementation straightforward.

Implemented under `Windows/` as a .NET 8 / WPF port (`Scratchpad.sln`), mirroring the macOS module layout (App, Overlay, Drawing, Rendering, Persistence, Preferences, TrayIcon, Hotkeys, Animations, Utilities) file-for-file where the platform allows. Global shortcut default is Ctrl+Alt+D (the macOS default is ⌥⌘D). See JOURNAL.md's "Windows port" entry for architectural decisions and unverified assumptions -- this was authored on macOS with no Windows machine available to build or run it.

---

# Design Goals

- extremely minimal
- fast
- distraction-free
- native
- elegant

No floating toolbars.

No unnecessary UI.

---

# Primary Workflow

User presses global shortcut.

↓

Overlay fades in.

↓

Desktop becomes slightly darker.

↓

Drawing cursor appears.

↓

User draws.

↓

Press shortcut again.

↓

Overlay fades away.

Drawing remains saved.

---

# Core Features

## Overlay

Fullscreen

Always on top

Transparent

Mouse input enabled

Keyboard shortcut activated

---

## Drawing

Freehand pencil

Smooth strokes

Pressure support (future)

Undo (future)

Redo (future)

Eraser (future)

Multiple colors (future)

Brush sizes (future)

---

## Overlay Animation

Fade in

Fade out

Animation duration configurable

---

## Background

Configurable dim amount

Examples:

0%

15%

30%

50%

---

## Cursor

Pencil cursor while drawing

Normal cursor otherwise

---

## Status Bar

Menu bar icon only.

No Dock icon by default.

Menu:

Show Scratchpad

Hide Scratchpad

Clear Pad

Preferences

Launch at Login

About

Quit

---

## Persistence

Drawing remains after hiding overlay.

User clears manually.

---

## Preferences

Global shortcut

Animation duration

Background dim opacity

Launch at Login

Open on current display

Open on all displays (future)

Default brush size (future)

Default color (future)

---

# Multi-Monitor

Initial version:

Overlay every connected monitor.

Future:

Current monitor only.

---

# Performance Goals

60 FPS minimum

Minimal idle CPU

Minimal memory usage

Fast startup

---

# Rendering

Separate rendering engine from UI.

Drawing engine should expose interfaces that can later be implemented on Windows.

Rendering implementation should not be tightly coupled to SwiftUI.

---

# Suggested Folder Structure

App/

Core/

Drawing/

Overlay/

Rendering/

Persistence/

Preferences/

StatusBar/

Hotkeys/

Animations/

Utilities/

Resources/

Tests/

---

# Coding Standards

No magic numbers.

No global mutable state.

Prefer protocols.

Keep files under ~300 lines when practical.

---

# Future Roadmap

Version 0.1

Basic overlay

Drawing

Status bar

Preferences

Persistence

Version 0.2

Undo

Redo

Brush sizes

Version 0.3

Multiple colors

Pressure

Shapes

Version 0.4

Laser pointer

Text tool

Screenshots

Version 1.0

Production ready
