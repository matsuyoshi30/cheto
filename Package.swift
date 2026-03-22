// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "cheto",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "cheto",
            path: "cheto",
            exclude: ["Info.plist"],
            resources: [.process("Assets.xcassets")]
        ),
        .testTarget(
            name: "chetoTests",
            dependencies: ["cheto"],
            path: "chetoTests"
        ),
    ]
)
