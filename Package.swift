// swift-tools-version: 5.9

import PackageDescription

let argParserUrl = "https://github.com/apple/swift-argument-parser"
let shellOutLink = "https://github.com/Maxim-Lanskoy/ShellOut.git"
let concatenator = "Concatenator"

let package = Package(
    name: "SRM",
    platforms: [
        .macOS(.v10_15) //, .linux
    ],
    products: [
        .executable(name: "srm", targets: ["SRM"]),
    ],
    dependencies: [
        .package(url: argParserUrl, from: "1.3.0"),
        .package(url: shellOutLink, from: "2.3.1")
    ],
    targets: [
        .executableTarget(
            name: "SRM", dependencies: [
                .product(name: "ShellOut", package: "ShellOut"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/SRM"
        ),
        .executableTarget(
            name: concatenator, path: "Sources/\(concatenator)"
        )
    ]
)
