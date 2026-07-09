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
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.0")
    ],
    targets: [
        .executableTarget(
            name: "MacScreen",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/MacScreen"
        )
    ]
)
