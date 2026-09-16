# aeroplace

Places the focused floating window for [AeroSpace](https://github.com/nikitabobko/AeroSpace) on macOS.

AeroSpace does not position floating windows. Its `resize` command refuses them (upstream issue #9), and no command sets an absolute rect. `aeroplace` fills that gap with the macOS Accessibility API.

```sh
aeroplace center   # centre the window, keep its size
aeroplace cycle    # step to the next size, centred
aeroplace stages   # print the size ladder, touch no window
```

`center` and `cycle` read the window from AeroSpace, then write the position and the size directly. `stages` needs no window and no Accessibility permission, so you can use it to check the ladder on any display.

### The size ladder

`cycle` steps through four sizes, then wraps. Each step is a quarter more of the usable area than the last: 25, 50, 75 and 100 percent.

The shape changes with the size. Width scales by the area fraction to the power of two thirds, height by the power of one third. The exponents add to 1, which keeps the area exact. A small window is therefore much closer to square than the display is, and the largest window matches the shape of the display.

Move the two exponents apart for a taller small window, together for a squarer one. They must always add to 1.

On a 2560 by 1366 usable area:

| Stage | Size        | Aspect |
| ----- | ----------- | ------ |
| 1     | 1016 × 861  | 1.18   |
| 2     | 1613 × 1084 | 1.49   |
| 3     | 2113 × 1241 | 1.70   |
| 4     | 2560 × 1366 | 1.87   |

`AREA_STAGES`, `WIDTH_EXPONENT` and `HEIGHT_EXPONENT` in `Placement.swift` control the ladder.

### Usable area

`aeroplace` uses the display that holds the window, not the focused display. It subtracts the AeroSpace `outer.bottom` gap from the visible frame, because a bar such as SketchyBar draws over the area AppKit reports as visible. It reads that value from `aerospace.toml`, so keep `outer.bottom` a scalar.

## Install

```sh
make install          # builds release, installs to ~/.local/bin
make install PREFIX=/usr/local
```

Grant Accessibility permission to `aeroplace` in System Settings, under Privacy and Security. Without it, `center` and `cycle` exit 1 with a message.

## Use from AeroSpace

Give an absolute path. AeroSpace starts from the GUI and does not read your shell profile.

```toml
ctrl-alt-c = ['layout floating', 'exec-and-forget /Users/you/.local/bin/aeroplace center']
ctrl-alt-r = ['layout floating', 'exec-and-forget /Users/you/.local/bin/aeroplace cycle']
```

## Why a binary

The earlier version of this tool was a shell script driving JavaScript for Automation. Each window operation went through System Events as an Apple Event, measured at about 65 ms. Position and size are two separate writes, so the window visibly moved and then resized.

Direct Accessibility calls remove that overhead for reads, which cost about 0.6 ms. Writes are not symmetric. On a measured sample, a position write costs under 1 ms, but a size write costs 7 to 25 ms, because the application handles the resize on its own run loop.

That asymmetry sets the order. `cycle` writes the size first, reads back what the application accepted, then centres for the real size. The window therefore holds an intermediate shape for about 5 ms rather than about 18 ms, which is under one frame at 60 Hz instead of over one. Reading the accepted size also removes a third write, because an application that refuses a size is centred correctly the first time.

macOS gives no window animation to a third-party tool, so this is one snap, not a transition.
