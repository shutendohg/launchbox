// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LbxCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "LbxCore", targets: ["LbxCore"]),
    ],
    targets: [
        .target(name: "LbxCore"),
        .testTarget(name: "LbxCoreTests", dependencies: ["LbxCore"]),
    ]
)
