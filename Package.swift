// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StoreKitMadeEasy",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "StoreKitMadeEasy",
            targets: ["StoreKitMadeEasy"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "StoreKitMadeEasy",
            dependencies: [],
            path: "Sources/StoreKitMadeEasy",
            resources: []
        ),
        .testTarget(
            name: "StoreKitMadeEasyTests",
            dependencies: ["StoreKitMadeEasy"],
            path: "Tests/StoreKitMadeEasyTests"
        ),
    ]
)
