// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SRM",
    platforms: [
        .macOS(.v10_15) //, .linux
    ],
    products: [
        .executable(name: "srm", targets: ["SRM"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.33.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        .executableTarget(
            name: "SRM",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        )
    ]
)
