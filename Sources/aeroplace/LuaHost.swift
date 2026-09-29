import CLua
import Foundation

enum LuaHost {
    static func run(arguments: [String]) -> Int32 {
        guard let executable = Bundle.main.executableURL?.resolvingSymlinksInPath().path else {
            return failure("cannot resolve the executable path")
        }
        let directory = ProcessInfo.processInfo.environment["AEROPLACE_LUA"]
            ?? URL(fileURLWithPath: executable)
                .deletingLastPathComponent()
                .appendingPathComponent("../share/aeroplace")
                .standardizedFileURL.path
        guard let state = luaL_newstate() else { return failure("cannot create a Lua state") }
        defer { lua_close(state) }
        luaL_openselectedlibs(state, ~0, 0)
        setPackagePath(state, directory: directory)
        setArg(state, executable: executable, arguments: arguments)
        Primitives.register(state, executable: executable)
        guard luaL_loadfilex(state, directory + "/main.lua", nil) == LUA_OK else {
            return failure(errorMessage(state))
        }
        for argument in arguments { lua_pushstring(state, argument) }
        guard lua_pcallk(state, Int32(arguments.count), 1, 0, 0, nil) == LUA_OK else {
            return failure(errorMessage(state))
        }
        return exitCode(state)
    }

    private static func setPackagePath(_ state: OpaquePointer, directory: String) {
        lua_getglobal(state, "package")
        lua_pushstring(state, directory + "/?.lua")
        lua_setfield(state, -2, "path")
        lua_settop(state, -2)
    }

    private static func setArg(_ state: OpaquePointer, executable: String, arguments: [String]) {
        lua_createtable(state, Int32(arguments.count), 1)
        lua_pushstring(state, executable)
        lua_seti(state, -2, 0)
        for (index, argument) in arguments.enumerated() {
            lua_pushstring(state, argument)
            lua_seti(state, -2, lua_Integer(index + 1))
        }
        lua_setglobal(state, "arg")
    }

    private static func exitCode(_ state: OpaquePointer) -> Int32 {
        if lua_type(state, -1) == LUA_TNIL { return 0 }
        guard lua_type(state, -1) == LUA_TNUMBER, lua_isinteger(state, -1) != 0 else {
            return failure("main.lua returned a non-integer")
        }
        return Int32(truncatingIfNeeded: lua_tointegerx(state, -1, nil))
    }

    private static func errorMessage(_ state: OpaquePointer) -> String {
        guard lua_isstring(state, -1) != 0, let text = lua_tolstring(state, -1, nil) else {
            return "non-string Lua error"
        }
        return String(cString: text)
    }

    private static func failure(_ message: String) -> Int32 {
        FileHandle.standardError.write(Data("aeroplace: \(message)\n".utf8))
        return 1
    }
}
