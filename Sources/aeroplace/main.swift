import AppKit

enum Mode: String {
    case center
    case cycle
    case stages
}

func fail(_ message: String, _ code: Int32) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(code)
}

guard CommandLine.arguments.count == 2,
      let mode = Mode(rawValue: CommandLine.arguments[1])
else { fail("usage: aeroplace <center|cycle|stages>", 2) }

func usableArea(screenIndex: Int) -> UsableArea {
    guard let resolved = Screen.resolve(index: screenIndex) else { fail("no screen", 1) }
    return UsableArea(
        screen: resolved.screen,
        primaryHeight: resolved.primaryHeight,
        bottomInset: AeroSpace.bottomInset()
    )
}

if mode == .stages {
    let area = usableArea(screenIndex: 0)
    print("usable \(Int(area.size.width))x\(Int(area.size.height))")
    var height = area.size.height
    for stage in 1...UsableArea.areaStages {
        let next = area.stageAfter(height: height)
        print("\(stage) \(Int(next.width))x\(Int(next.height))")
        height = next.height
    }
    exit(0)
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
case .stages:
    break
}
