// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SRM",
    products: [
        .executable(
            name: "srm",
            targets: ["SRM"]
        ),
    ],
    dependencies: [
        // Example:
        // .package(url: "https://github.com/apple/swift-argument-parser", from: "1.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "SRM",
            dependencies: [
                // Place to add dependencies from external libraries or modules here, if any
                // Example: .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/SRM",
            resources: [
                // If having any resources (e.g., config files), it is possible to define them here
            ]
        ),
        .testTarget(
            name: "SRMTests",
            dependencies: ["SRM"],
            path: "Tests/SRMTests"
        )
    ]
)
