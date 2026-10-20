// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AxiCore",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "AxiCore", targets: ["AxiCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.11.1"),
        .package(path: "../AxiVectors"),
        .package(path: "../AxiScreen"),
        .package(path: "../AxiOMP"),
    ],
    targets: [
        .target(
            name: "AxiCore",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "AxiVectors", package: "AxiVectors"),
                .product(name: "AxiScreen", package: "AxiScreen"),
                .product(name: "AxiOMP", package: "AxiOMP"),
            ]
        ),
        .testTarget(
            name: "AxiCoreTests",
            dependencies: [
                "AxiCore",
                .product(name: "AxiScreen", package: "AxiScreen"),
                .product(name: "AxiVectors", package: "AxiVectors"),
                .product(name: "AxiOMP", package: "AxiOMP"),
            ]
        ),
    ]
)
