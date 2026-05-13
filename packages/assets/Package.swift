// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Assets",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "Assets",
            targets: ["Assets"]
        ),
    ],
    targets: [
        .target(
            name: "Assets",
            path: "src",
            resources: [
                .process("images"),
                .process("icons"),
            ]
        ),
    ]
)
