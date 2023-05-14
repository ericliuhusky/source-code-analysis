// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Runtime",
    products: [
        .library(
            name: "Runtime",
            targets: ["Runtime"]),
    ],
    targets: [
        .target(name: "Runtime")
    ]
)
