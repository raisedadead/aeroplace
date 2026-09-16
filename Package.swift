// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "aeroplace",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "aeroplace", path: "Sources/aeroplace")
    ]
)
