# Contributing

Scratchpad is a small, opinionated project — the goal is to stay minimal, so
not every feature idea is a good fit. If you're planning something larger
than a bug fix, open an issue first to discuss it before writing code.

## Getting set up

See the [Building](README.md#building) section of the README. There is no
Xcode project — everything is driven by Swift Package Manager.

## Guidelines

- Keep modules focused and protocol-oriented; see the Architecture section
  of the README before adding a new type.
- Pure logic (stroke smoothing, geometry, persistence formats) should stay
  free of AppKit/SwiftUI dependencies so it can be unit tested and, ideally,
  ported to the Windows implementation.
- Avoid adding third-party dependencies unless there's no reasonable way to
  do it with system frameworks.
- Run `swift test` (or the smoke-test fallback described in the README)
  before opening a pull request.
- Update `JOURNAL.md` with any non-obvious architectural decision — it's the
  running history of *why* the code looks the way it does.

## Windows port

The `Windows/` implementation mirrors the macOS module layout as closely as
the platform allows. If you're porting a macOS change over, keep the same
file/type names on the C# side where practical.

## Pull requests

Keep PRs scoped to one change. Describe what changed and why, not just what
files moved.
