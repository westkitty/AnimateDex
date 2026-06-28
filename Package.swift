// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AnimateDex",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "AnimateDex", targets: ["AnimateDex"])
    ],
    targets: [
        .executableTarget(
            name: "AnimateDex",
            path: "AnimateDex"
        ),
        .testTarget(
            name: "AnimateDexTests",
            dependencies: ["AnimateDex"],
            path: "Tests"
        )
    ]
)
