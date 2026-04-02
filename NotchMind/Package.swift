// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NotchMind",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "NotchMind", targets: ["App"])
    ],
    targets: [
        .executableTarget(
            name: "App",
            path: "Sources/App",
            dependencies: []
        )
    ]
)