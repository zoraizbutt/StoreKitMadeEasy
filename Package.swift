// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StoreFlow",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "StoreFlow",
            targets: ["StoreFlow"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "StoreFlow",
            dependencies: [],
            path: "Sources/StoreFlow",
            resources: []
        ),
        .testTarget(
            name: "StoreFlowTests",
            dependencies: ["StoreFlow"],
            path: "Tests/StoreFlowTests"
        ),
    ]
)
