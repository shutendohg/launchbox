// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LaunchboxCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "LaunchboxCore", targets: ["LaunchboxCore"]),
    ],
    targets: [
        .target(name: "LaunchboxCore"),
        .testTarget(name: "LaunchboxCoreTests", dependencies: ["LaunchboxCore"]),
    ]
)
