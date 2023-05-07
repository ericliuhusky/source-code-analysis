// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "swift-corelibs-foundation",
    products: [
        .library(
            name: "SFoundation",
            targets: ["SFoundation"]),
    ],
    targets: [
        .target(
            name: "SFoundation"),
        .testTarget(
            name: "SFoundationTests",
            dependencies: ["SFoundation"]),
    ]
)
