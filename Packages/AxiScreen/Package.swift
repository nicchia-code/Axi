// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AxiScreen",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "AxiScreen", targets: ["AxiScreen"]),
    ],
    targets: [
        .target(name: "AxiScreen"),
        .testTarget(
            name: "AxiScreenTests",
            dependencies: ["AxiScreen"]
        ),
    ]
)
