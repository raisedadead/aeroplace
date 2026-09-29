// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "aeroplace",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "CLua",
            path: "Sources/CLua",
            cSettings: [.define("LUA_USE_MACOSX")]
        ),
        .executableTarget(name: "aeroplace", dependencies: ["CLua"], path: "Sources/aeroplace"),
    ]
)
