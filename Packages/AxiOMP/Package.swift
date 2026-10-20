// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AxiOMP",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "AxiOMP", targets: ["AxiOMP"]),
    ],
    targets: [
        .target(name: "AxiOMP"),
        .testTarget(
            name: "AxiOMPTests",
            dependencies: ["AxiOMP"]
        ),
    ]
)
