import ApplicationServices
import CLua
import Foundation

enum Primitives {
    static func register(_ state: OpaquePointer, executable: String) {
        let functions: [(String, lua_CFunction)] = [
            ("aerospace", aerospace),
            ("trusted", trusted),
            ("window", window),
            ("size", size),
            ("set_size", setSize),
            ("set_position", setPosition),
            ("screen", screen),
            ("sleep", sleep),
        ]
        lua_createtable(state, 0, Int32(functions.count + 1))
        for (name, function) in functions {
            lua_pushcclosure(state, function, 0)
            lua_setfield(state, -2, name)
        }
        lua_pushstring(state, executable)
        lua_setfield(state, -2, "executable")
        lua_setglobal(state, "aeroplace")
    }
}

private let aerospaceBinary = "/opt/homebrew/bin/aerospace"

private func aerospace(_ state: OpaquePointer?) -> Int32 {
    guard let state else { return 0 }
    var arguments: [String] = []
    for index in stride(from: 1, through: lua_gettop(state), by: 1) {
        guard lua_isstring(state, index) != 0, let pointer = lua_tolstring(state, index, nil) else {
            return failure(state, "aerospace: argument \(index) is not a string")
        }
        arguments.append(String(cString: pointer))
    }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: aerospaceBinary)
    process.arguments = arguments
    process.environment = ProcessInfo.processInfo.environment
        .filter { $0.key != "AEROSPACE_WINDOW_ID" && $0.key != "AEROSPACE_WORKSPACE" }
    let output = Pipe()
    let error = Pipe()
    process.standardOutput = output
    process.standardError = error
    guard (try? process.run()) != nil else { return failure(state, "aerospace: cannot run \(aerospaceBinary)") }
    let stdout = trimmed(output.fileHandleForReading.readDataToEndOfFile())
    let stderr = trimmed(error.fileHandleForReading.readDataToEndOfFile())
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        return failure(state, stderr.isEmpty ? "aerospace: exit \(process.terminationStatus)" : stderr)
    }
    lua_pushstring(state, stdout)
    return 1
}

private func trusted(_ state: OpaquePointer?) -> Int32 {
    guard let state else { return 0 }
    lua_pushboolean(state, AXIsProcessTrusted() ? 1 : 0)
    return 1
}

private func window(_ state: OpaquePointer?) -> Int32 {
    guard let state else { return 0 }
    guard let pid = number(state, 1).flatMap({ pid_t(exactly: $0) }), let title = text(state, 2) else {
        return failure(state, "window: expected an integer pid and a title")
    }
    guard let match = AXWindow.match(pid: pid, title: title) else {
        return failure(state, "window: no Accessibility window for pid \(pid)")
    }
    lua_pushlightuserdata(state, Unmanaged.passRetained(match.element).toOpaque())
    return 1
}

private func size(_ state: OpaquePointer?) -> Int32 {
    guard let state else { return 0 }
    guard let window = handle(state, 1) else { return failure(state, "size: expected a window handle") }
    guard let size = window.size() else { return failure(state, "size: cannot read the window size") }
    lua_pushnumber(state, Double(size.width))
    lua_pushnumber(state, Double(size.height))
    return 2
}

private func setSize(_ state: OpaquePointer?) -> Int32 {
    guard let state else { return 0 }
    guard let window = handle(state, 1), let width = number(state, 2), let height = number(state, 3) else {
        return failure(state, "set_size: expected a window handle, a width, and a height")
    }
    guard window.setSize(CGSize(width: width, height: height)) else {
        return failure(state, "set_size: the application refused the size")
    }
    lua_pushboolean(state, 1)
    return 1
}

private func setPosition(_ state: OpaquePointer?) -> Int32 {
    guard let state else { return 0 }
    guard let window = handle(state, 1), let x = number(state, 2), let y = number(state, 3) else {
        return failure(state, "set_position: expected a window handle, an x, and a y")
    }
    guard window.setPosition(CGPoint(x: x, y: y)) else {
        return failure(state, "set_position: the application refused the position")
    }
    lua_pushboolean(state, 1)
    return 1
}

private func screen(_ state: OpaquePointer?) -> Int32 {
    guard let state else { return 0 }
    guard let index = number(state, 1).flatMap({ Int(exactly: $0) }) else {
        return failure(state, "screen: expected an integer index")
    }
    guard let frame = Screen.visibleFrame(index: index) else { return failure(state, "screen: no screen") }
    for value in [frame.origin.x, frame.origin.y, frame.width, frame.height] {
        lua_pushnumber(state, Double(value))
    }
    return 4
}

private func sleep(_ state: OpaquePointer?) -> Int32 {
    guard let state else { return 0 }
    guard let seconds = number(state, 1), seconds >= 0 else {
        return failure(state, "sleep: expected a non-negative number of seconds")
    }
    Thread.sleep(forTimeInterval: seconds)
    return 0
}

private func text(_ state: OpaquePointer, _ index: Int32) -> String? {
    guard lua_type(state, index) == LUA_TSTRING, let pointer = lua_tolstring(state, index, nil) else {
        return nil
    }
    return String(cString: pointer)
}

private func number(_ state: OpaquePointer, _ index: Int32) -> Double? {
    guard lua_type(state, index) == LUA_TNUMBER else { return nil }
    return lua_tonumberx(state, index, nil)
}

private func handle(_ state: OpaquePointer, _ index: Int32) -> AXWindow? {
    guard lua_type(state, index) == LUA_TLIGHTUSERDATA, let pointer = lua_touserdata(state, index) else {
        return nil
    }
    return AXWindow(element: Unmanaged<AXUIElement>.fromOpaque(pointer).takeUnretainedValue())
}

private func trimmed(_ data: Data) -> String {
    var text = String(decoding: data, as: UTF8.self)
    while let last = text.last, last.isWhitespace { text.removeLast() }
    return text
}

private func failure(_ state: OpaquePointer, _ message: String) -> Int32 {
    lua_pushnil(state)
    lua_pushstring(state, message)
    return 2
}
