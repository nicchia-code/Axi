// swift-tools-version: 6.2

import PackageDescription

// sqlite-vec is vendored (see README.md) and compiled against the system SQLite,
// so it can be registered on the connection GRDB opens. No SQLite copy is bundled.
let package = Package(
    name: "AxiVectors",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "AxiVectors", targets: ["AxiVectors"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.11.1"),
    ],
    targets: [
        .target(
            name: "CSQLiteVec",
            cSettings: [
                .define("SQLITE_CORE", to: "1"),
                .define("SQLITE_VEC_OMIT_FS"),
            ],
            linkerSettings: [
                .linkedLibrary("sqlite3"),
            ]
        ),
        .target(
            name: "AxiVectors",
            dependencies: ["CSQLiteVec"]
        ),
        .testTarget(
            name: "AxiVectorsTests",
            dependencies: [
                "AxiVectors",
                .product(name: "GRDB", package: "GRDB.swift"),
            ]
        ),
    ]
)
