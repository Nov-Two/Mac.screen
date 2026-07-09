// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MacScreen",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacScreen", targets: ["MacScreen"])
    ],
    targets: [
        .executableTarget(
            name: "MacScreen",
            path: "Sources/MacScreen"
        )
    ]
)
