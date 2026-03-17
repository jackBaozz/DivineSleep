// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "DivineSleep",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "DivineSleep", targets: ["DivineSleep"])
    ],
    targets: [
        .executableTarget(
            name: "DivineSleep",
            path: "Sources/DivineSleep"
        ),
        .testTarget(
            name: "DivineSleepTests",
            dependencies: ["DivineSleep"],
            path: "Tests/DivineSleepTests"
        )
    ]
)
