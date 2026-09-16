import Foundation

struct WindowRow {
    let pid: pid_t
    let screenIndex: Int
    let title: String
}

enum AeroSpace {
    static let binary = "/opt/homebrew/bin/aerospace"
    static let fallbackBottomInset = 60.0

    static func focusedWindowRow(attempts: Int = 20, interval: TimeInterval = 0.05) -> WindowRow? {
        guard let id = focusedWindowId() else { return nil }
        for _ in 0..<attempts {
            if let row = row(of: id) { return row }
            Thread.sleep(forTimeInterval: interval)
        }
        return nil
    }

    static func bottomInset(configPath: String? = nil) -> Double {
        let path = configPath ?? defaultConfigPath()
        guard let text = try? String(contentsOfFile: path, encoding: .utf8) else {
            return fallbackBottomInset
        }
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            guard line.hasPrefix("outer.bottom") else { continue }
            let digits = line.drop { $0 != "=" }.filter(\.isNumber)
            if let value = Double(digits) { return value }
        }
        return fallbackBottomInset
    }

    private static func focusedWindowId() -> String? {
        if let id = ProcessInfo.processInfo.environment["AEROSPACE_WINDOW_ID"],
           id.allSatisfy(\.isNumber), !id.isEmpty {
            return id
        }
        return run(["list-windows", "--focused", "--format", "%{window-id}"])?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func row(of id: String) -> WindowRow? {
        let format = "%{window-id}|%{app-pid}|%{monitor-appkit-nsscreen-screens-id}|%{window-title}"
        guard let output = run(["list-windows", "--all", "--format", format]) else { return nil }
        for line in output.split(separator: "\n") {
            let fields = line.split(separator: "|", maxSplits: 3, omittingEmptySubsequences: false)
            guard fields.count == 4, fields[0] == id, let pid = pid_t(fields[1]) else { continue }
            return WindowRow(pid: pid, screenIndex: Int(fields[2]) ?? 0, title: String(fields[3]))
        }
        return nil
    }

    private static func defaultConfigPath() -> String {
        if let path = run(["config", "--config-path"])?
            .trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
            return path
        }
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let base = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"] ?? "\(home)/.config"
        return "\(base)/aerospace/aerospace.toml"
    }

    private static func run(_ arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binary)
        process.arguments = arguments
        process.environment = ProcessInfo.processInfo.environment
            .filter { $0.key != "AEROSPACE_WINDOW_ID" && $0.key != "AEROSPACE_WORKSPACE" }
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
