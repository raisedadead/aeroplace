# aeroplace

Places floating windows for AeroSpace on macOS with the Accessibility API, because AeroSpace does not.

## Layout

- `Sources/aeroplace/main.swift` — verbs and the top-level flow
- `Sources/aeroplace/AeroSpace.swift` — window lookup and the `outer.bottom` read
- `Sources/aeroplace/Placement.swift` — the usable area and the size ladder
- `Sources/aeroplace/Window.swift` — Accessibility reads and writes

## Rules

- Never run `center` or `cycle` to test a change. Both act on the operator's focused window. Use `stages`, which touches no window.
- `swift build -c release` and `aeroplace stages` are the validators. Compare the ladder with the table in README.md.
- Keep the Accessibility path free of Apple Events. System Events costs about 65 ms per call; a direct Accessibility call costs about 0.6 ms.
- AppKit reports the visible frame from the bottom left of the primary display. The Accessibility API measures from the top left. `UsableArea` flips Y once.
- Do not add a dependency for the `outer.bottom` read. A line match is enough.

## Conventions

- ISC licence. `main` is the trunk. Work on `feat/` branches.
- Commit subjects use `type(scope): subject`, 50 characters, imperative.
