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

## AeroSpace gaps

Send each window task to the `aerospace` CLI first. AeroSpace cannot do the tasks in the list below, so aeroplace does them with the Accessibility API. Add a verb to aeroplace only for a task in this list.

- **Position a floating window.** `move` fails on a floating window ([MoveCommand:39][move-floating]), and no command sets a position. Write the position with `AXWindow.setPosition`, as `center` does.
- **Resize a floating window.** `resize` fails on a floating window ([ResizeCommand:37][resize], [issue #9][issue-9]). Write the size with `AXWindow.setSize`, read back the size that the application accepted, then centre for that size, as `cycle` does.
- **Place a window that becomes floating.** `layout floating` restores the last floating size and keeps the current position ([LayoutCommand:79][layout-floating]). Put `exec-and-forget <path>/aeroplace center` after `layout floating` in the same binding or rule.
- **Keep a floating window clear of a bar.** Gaps apply to tiled windows only. AeroSpace moves a floating window only when the monitor under it shows another workspace, and sizes it only for `fullscreen` ([layoutRecursive:72][floating-layout]). Subtract `outer.bottom` from the visible frame, as `UsableArea` does.
- **Read a frame.** `list-windows` and `list-monitors` print no position or size ([format variables][format-vars]). Read a window frame with `AXWindow` and a display frame with `NSScreen`. Select the display with `%{monitor-appkit-nsscreen-screens-id}`.
- **Find the Accessibility window.** AeroSpace prints `%{window-id}` but no Accessibility element. Match the element on `%{app-pid}` and `%{window-title}`, as `AXWindow.match` does.

### Accordion root

AeroSpace replaces an accordion root with a `tiles` root after two tree edits. Fix this in `aerospace.toml`. aeroplace has no part in it.

- `move` across the workspace edge puts a new `tiles` root above the old root ([MoveCommand:137][move-edge]).
- `join-with` puts two windows in a new `tiles` container ([JoinWith:23][join]). When the root holds nothing else, normalization makes that container the root ([normalizeContainers:12][flatten]).
- `default-root-container-layout` applies only when a workspace has no root yet ([WorkspaceEx:7][root]).

Bind `move` with `--boundaries-action stop`. Restore the root with `layout --root h_accordion`.

The links point to AeroSpace commit `d56e163` (0.21.3-Beta). After an AeroSpace upgrade, read each linked file at the new commit and update this section.

## Conventions

- ISC licence. `main` is the trunk. Work on `feat/` branches.
- Commit subjects use `type(scope): subject`, 50 characters, imperative.

[flatten]: https://github.com/nikitabobko/AeroSpace/blob/d56e1637c3a1ed660d0cadd7534e94fb3218d1c3/Sources/AppBundle/tree/normalizeContainers.swift#L12
[floating-layout]: https://github.com/nikitabobko/AeroSpace/blob/d56e1637c3a1ed660d0cadd7534e94fb3218d1c3/Sources/AppBundle/layout/layoutRecursive.swift#L72
[format-vars]: https://github.com/nikitabobko/AeroSpace/blob/d56e1637c3a1ed660d0cadd7534e94fb3218d1c3/Sources/Common/cmdArgs/impl/ListWindowsCmdArgs.swift#L179-L207
[issue-9]: https://github.com/nikitabobko/AeroSpace/issues/9
[join]: https://github.com/nikitabobko/AeroSpace/blob/d56e1637c3a1ed660d0cadd7534e94fb3218d1c3/Sources/AppBundle/command/impl/JoinWithCommand.swift#L23
[layout-floating]: https://github.com/nikitabobko/AeroSpace/blob/d56e1637c3a1ed660d0cadd7534e94fb3218d1c3/Sources/AppBundle/command/impl/LayoutCommand.swift#L79
[move-edge]: https://github.com/nikitabobko/AeroSpace/blob/d56e1637c3a1ed660d0cadd7534e94fb3218d1c3/Sources/AppBundle/command/impl/MoveCommand.swift#L137-L143
[move-floating]: https://github.com/nikitabobko/AeroSpace/blob/d56e1637c3a1ed660d0cadd7534e94fb3218d1c3/Sources/AppBundle/command/impl/MoveCommand.swift#L39
[resize]: https://github.com/nikitabobko/AeroSpace/blob/d56e1637c3a1ed660d0cadd7534e94fb3218d1c3/Sources/AppBundle/command/impl/ResizeCommand.swift#L37
[root]: https://github.com/nikitabobko/AeroSpace/blob/d56e1637c3a1ed660d0cadd7534e94fb3218d1c3/Sources/AppBundle/tree/WorkspaceEx.swift#L7-L13
