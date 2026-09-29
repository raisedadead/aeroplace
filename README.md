# aeroplace

Places windows for [AeroSpace](https://github.com/nikitabobko/AeroSpace) on macOS.

AeroSpace does not position floating windows. Its `resize` command refuses them (upstream issue #9), and no command sets an absolute rect. `aeroplace` fills that gap with the macOS Accessibility API.

```sh
aeroplace center              # centre the window, keep its size
aeroplace cycle               # step to the next size, centred
aeroplace stages              # print the size ladder, touch no window
aeroplace layout [workspace]  # focused window left, the others in one column
aeroplace --version
aeroplace --help
```

`center` and `cycle` read the window from AeroSpace, then write the position and the size directly. `stages` needs no window and no Accessibility permission, so you can use it to check the ladder on any display.

`layout` tiles the tiled and floating windows on the workspace. The focused window takes the left column. On another workspace, the first window takes it. The other windows share the right column. `layout` sends the whole plan to AeroSpace as one `aerospace eval`, so it needs no Accessibility permission. Two `layout` runs never overlap: each run holds `$XDG_STATE_HOME/aerospace/layout.lock`.

The verbs are Lua scripts. The binary embeds Lua 5.5.1 and gives the scripts the AeroSpace CLI, the Accessibility API and the display frames. It reads the scripts from `../share/aeroplace`, relative to the binary. Set `AEROPLACE_LUA` to read them from another directory.

### The size ladder

`cycle` steps through three sizes, then wraps. Each step is a quarter more of the usable area than the last: 25, 50 and 75 percent.

The shape changes with the size. Width scales by the area fraction to the power of two thirds, height by the power of one third. The exponents add to 1, which keeps the area exact. A small window is therefore much closer to square than the display is. Each larger step is closer to the shape of the display.

Move the two exponents apart for a taller small window, together for a squarer one. They must always add to 1.

On a 2560 by 1366 usable area:

| Stage | Size        | Aspect |
| ----- | ----------- | ------ |
| 1     | 1016 × 861  | 1.18   |
| 2     | 1613 × 1084 | 1.49   |
| 3     | 2113 × 1241 | 1.70   |

`fractions`, `width_exponent` and `height_exponent` in `lua/placement.lua` control the ladder.

### Usable area

`aeroplace` uses the display that holds the window, not the focused display. It subtracts the AeroSpace `outer.bottom` gap from the visible frame, because a bar such as SketchyBar draws over the area AppKit reports as visible. It reads that value from `aerospace.toml`, so keep `outer.bottom` a scalar.

## Install

aeroplace needs macOS 13 or later and [AeroSpace](https://github.com/nikitabobko/AeroSpace). It finds the `aerospace` CLI on `PATH`, then in `/opt/homebrew/bin` and `/usr/local/bin`.

With Homebrew, which builds aeroplace from source:

```sh
brew install raisedadead/tap/aeroplace
```

From a clone, with Swift 6 or later:

```sh
make install          # binary to ~/.local/bin, scripts to ~/.local/share/aeroplace
make install PREFIX=/usr/local
make check            # host checks, Lua tests, and the ladder
```

### Accessibility permission

`center` and `cycle` need Accessibility permission. macOS checks the permission of the app that starts `aeroplace`. From a key binding, that app is AeroSpace, which already has the permission. From a shell, grant the permission to your terminal app in System Settings, under Privacy & Security, then Accessibility. Without it, `center` and `cycle` exit 1 with a message.

## Use from AeroSpace

Give an absolute path. AeroSpace starts from the GUI and does not read your shell profile. Use `/opt/homebrew/bin/aeroplace` for Homebrew on Apple silicon, `/usr/local/bin/aeroplace` for Homebrew on Intel, or the full path of `~/.local/bin/aeroplace` for `make install`.

```toml
ctrl-alt-c = ['layout floating', 'exec-and-forget /opt/homebrew/bin/aeroplace center']
ctrl-alt-r = ['layout floating', 'exec-and-forget /opt/homebrew/bin/aeroplace cycle']
ctrl-alt-w = 'exec-and-forget /opt/homebrew/bin/aeroplace layout'
```

## Why a binary

The earlier version of this tool was a shell script driving JavaScript for Automation. Each window operation went through System Events as an Apple Event, measured at about 65 ms. Position and size are two separate writes, so the window visibly moved and then resized.

Direct Accessibility calls remove that overhead for reads, which cost about 0.6 ms. Writes are not symmetric. On a measured sample, a position write costs under 1 ms, but a size write costs 7 to 25 ms, because the application handles the resize on its own run loop.

That asymmetry sets the order. When the window shrinks, `cycle` writes the size first, reads back what the application accepted, then centres for the real size. The window therefore holds an intermediate shape for about 5 ms rather than about 18 ms, which is under one frame at 60 Hz instead of over one. When the window grows in either direction, `cycle` first moves it to the centre for the new size. The application clips a size that runs past the screen edge, so a size written at the old position can come back smaller than the ladder step. In both cases, the last write centres the size that the application accepted.

macOS gives no window animation to a third-party tool, so this is one snap, not a transition.

## Licence

aeroplace is ISC. `Sources/CLua` holds the Lua 5.5.1 library sources from [lua.org](https://www.lua.org), under the MIT licence. The files are unchanged; `lua.c`, `luac.c`, `lua.hpp` and the `Makefile` are left out. The notice is at the end of `Sources/CLua/include/lua.h`.
