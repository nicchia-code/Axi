// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AxiEmbedding",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "AxiEmbedding", targets: ["AxiEmbedding"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.32.3"),
        .package(url: "https://github.com/huggingface/swift-transformers", from: "1.3.5"),
        // EmbeddingGemma 2 support is on main, after the 3.32.3 tag. Pinned to a commit.
        // Traits are off: the FoundationModels adapter needs macOS 27, Axi targets macOS 26.
        .package(
            url: "https://github.com/ml-explore/mlx-swift-lm",
            revision: "48114eedf3c3d4a682a6b1d644cc5af5c2945d10",
            traits: []),
    ],
    targets: [
        .target(
            name: "AxiEmbedding",
            dependencies: [
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXVLM", package: "mlx-swift-lm"),
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
                .product(name: "MLXHuggingFace", package: "mlx-swift-lm"),
                .product(name: "Tokenizers", package: "swift-transformers"),
            ]
        ),
        .testTarget(
            name: "AxiEmbeddingTests",
            dependencies: [
                "AxiEmbedding",
                .product(name: "MLX", package: "mlx-swift"),
            ],
            resources: [.copy("Fixtures")]
        ),
    ]
)
