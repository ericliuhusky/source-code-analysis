// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Fishhook",
    products: [
        .library(
            name: "Fishhook",
            targets: ["Fishhook"]),
    ],
    targets: [
        .target(name: "Fishhook"),
    ]
)
