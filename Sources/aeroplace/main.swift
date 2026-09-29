import AppKit

enum Mode: String {
    case center
    case cycle
}

func fail(_ message: String, _ code: Int32) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(code)
}

guard CommandLine.arguments.count == 2,
      let mode = Mode(rawValue: CommandLine.arguments[1])
else { exit(LuaHost.run(arguments: Array(CommandLine.arguments.dropFirst()))) }

func usableArea(screenIndex: Int) -> UsableArea {
    guard let resolved = Screen.resolve(index: screenIndex) else { fail("no screen", 1) }
    return UsableArea(
        screen: resolved.screen,
        primaryHeight: resolved.primaryHeight,
        bottomInset: AeroSpace.bottomInset()
    )
}

guard AXIsProcessTrusted() else { fail("aeroplace needs Accessibility permission", 1) }

guard let row = AeroSpace.focusedWindowRow(),
      let window = AXWindow.match(pid: row.pid, title: row.title),
      let current = window.size()
else { exit(0) }

let area = usableArea(screenIndex: row.screenIndex)

switch mode {
case .center:
    window.setPosition(area.centre(for: current))
case .cycle:
    window.setSize(area.stageAfter(height: current.height))
    window.setPosition(area.centre(for: window.size() ?? current))
}
