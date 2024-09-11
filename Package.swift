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
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/Maxim-Lanskoy/ShellOut.git", from: "2.3.1")
    ],
    targets: [
        .executableTarget(
            name: "SRM",
            dependencies: [
                .product(name: "ShellOut", package: "ShellOut"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        )
    ]
)
