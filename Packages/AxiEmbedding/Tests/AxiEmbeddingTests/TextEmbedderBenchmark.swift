import Foundation
import MLX
import Testing

@testable import AxiEmbedding

/// Measurements for the README. Opt-in: set `AXI_EMBEDDING_BENCHMARK=1`, and optionally
/// `AXI_EMBEDDING_MODEL_DIR` to measure another local checkpoint (for example a quantized one).
@Suite(
    .serialized,
    .enabled(
        if: ProcessInfo.processInfo.environment["AXI_EMBEDDING_BENCHMARK"] != nil,
        "Set AXI_EMBEDDING_BENCHMARK to run"))
struct TextEmbedderBenchmark {

    @Test func measureLoadSpeedMemoryAndQuality() async throws {
        let directory =
            ProcessInfo.processInfo.environment["AXI_EMBEDDING_MODEL_DIR"]
            .map { URL(filePath: $0, directoryHint: .isDirectory) }
            ?? TextEmbedder.defaultModelDirectory
        let url = try #require(
            Bundle.module.url(
                forResource: "reference-sentence-similarity", withExtension: "json",
                subdirectory: "Fixtures"))
        let reference = try JSONDecoder().decode(
            ReferenceFile.self, from: Data(contentsOf: url))

        let loadStart = ContinuousClock.now
        let memoryBeforeLoad = Memory.activeMemory
        let embedder = try await TextEmbedder(modelDirectory: directory)
        let loadSeconds = ContinuousClock.now - loadStart
        let loadedBytes = Memory.activeMemory - memoryBeforeLoad

        // Warm-up: the first pass compiles Metal kernels.
        _ = try await embedder.embed(reference.sentences)

        let runs = 10
        let passageCount = runs * reference.sentences.count
        let inferenceStart = ContinuousClock.now
        for _ in 0..<runs {
            _ = try await embedder.embed(reference.sentences)
        }
        let perPassage = (ContinuousClock.now - inferenceStart) / passageCount

        // Pairs 0/1 and 2/3 are translations; 4...7 are unrelated (see the fixture).
        var quality = ""
        for dimensions in [768, 256, 128] {
            let vectors = try await embedder.embed(reference.sentences, dimensions: dimensions)
            let fidelity = zip(vectors, reference.embeddings).map { vector, expected in
                let prefix = Array(expected.prefix(dimensions))
                let dot = zip(vector, prefix).reduce(0.0) { $0 + Double($1.0) * $1.1 }
                let norm = prefix.reduce(0.0) { $0 + $1 * $1 }.squareRoot()
                return dot / norm
            }.min() ?? 0
            let affine = [(0, 1), (2, 3)].map { pair in
                dot(vectors[pair.0], vectors[pair.1])
            }
            let unrelated = (4...7).flatMap { other in
                [0, 1, 2, 3].map { dot(vectors[$0], vectors[other]) }
            }
            let margin = (affine.min() ?? 0) - (unrelated.max() ?? 0)
            quality += "\n  \(dimensions) dims: min cosine vs reference "
            quality += String(format: "%.4f", fidelity)
            quality += ", affine min " + String(format: "%.3f", affine.min() ?? 0)
            quality += ", unrelated max " + String(format: "%.3f", unrelated.max() ?? 0)
            quality += ", margin " + String(format: "%.3f", margin)
        }

        print(
            """
            AXI_EMBEDDING_BENCHMARK model=\(directory.lastPathComponent)
              load: \(loadSeconds)
              live MLX memory after load: \(loadedBytes / 1_000_000) MB
              peak MLX memory: \(Memory.peakMemory / 1_000_000) MB
              time per passage (\(passageCount) passages): \(perPassage)\(quality)
            """)
    }

    private func dot(_ a: [Float], _ b: [Float]) -> Float {
        zip(a, b).reduce(0) { $0 + $1.0 * $1.1 }
    }
}

private struct ReferenceFile: Decodable {
    let sentences: [String]
    let embeddings: [[Double]]
}
