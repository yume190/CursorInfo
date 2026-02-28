// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SPM",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "cursor-info", targets: ["CursorInfo"]),
        .executable(name: "demangle", targets: ["Demangle"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/SourceKitten", from: "0.37.2"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.7.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "CursorInfo",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SourceKittenFramework", package: "SourceKitten"),
            ]
        ),
        .executableTarget(
            name: "Demangle",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
    ]
)
