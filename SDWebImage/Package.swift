// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "SDWebImage",
    products: [
        .library(
            name: "SDWebImage",
            targets: ["SDWebImage"])
    ],
    targets: [
        .target(name: "SDWebImage")
    ]
)
