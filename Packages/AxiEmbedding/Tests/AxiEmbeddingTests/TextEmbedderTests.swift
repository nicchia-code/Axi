import Foundation
import Testing

@testable import AxiEmbedding

/// Reference vectors produced by `google/embeddinggemma-2` in sentence-transformers,
/// text-only, float32, with the `task: sentence similarity | query: ` prefix.
private struct Reference: Decodable {
    let prompt: String
    let dimensions: Int
    let sentences: [String]
    let embeddings: [[Double]]
}

private enum Fixture {
    static func reference() throws -> Reference {
        let url = try #require(
            Bundle.module.url(
                forResource: "reference-sentence-similarity", withExtension: "json",
                subdirectory: "Fixtures"))
        return try JSONDecoder().decode(Reference.self, from: Data(contentsOf: url))
    }

    /// The checkpoint is a local download, never fetched by the tests.
    static var modelIsInstalled: Bool {
        FileManager.default.fileExists(
            atPath: TextEmbedder.defaultModelDirectory
                .appending(path: "config.json").path(percentEncoded: false))
    }
}

private func dot(_ a: [Float], _ b: [Float]) -> Float {
    zip(a, b).reduce(0) { $0 + $1.0 * $1.1 }
}

private func cosine(_ a: [Double], _ b: [Double]) -> Double {
    let dotProduct = zip(a, b).reduce(0) { $0 + $1.0 * $1.1 }
    let normA = a.reduce(0) { $0 + $1 * $1 }.squareRoot()
    let normB = b.reduce(0) { $0 + $1 * $1 }.squareRoot()
    return dotProduct / (normA * normB)
}

@Suite(.serialized, .enabled(if: Fixture.modelIsInstalled, "Install the EmbeddingGemma 2 checkpoint in Axi's models folder"))
struct TextEmbedderTests {

    @Test func italianAndEnglishVectorsMatchReference() async throws {
        let reference = try Fixture.reference()
        let embedder = try await TextEmbedder()
        let vectors = try await embedder.embed(reference.sentences)

        #expect(vectors.count == reference.sentences.count)
        for (index, vector) in vectors.enumerated() {
            #expect(vector.count == reference.dimensions)
            let similarity = cosine(
                vector.map(Double.init), reference.embeddings[index])
            #expect(similarity > 0.99, "sentence \(index): cosine \(similarity) against reference")
        }
    }

    @Test func affinePairsScoreAboveUnrelatedSentences() async throws {
        let reference = try Fixture.reference()
        let embedder = try await TextEmbedder()
        let vectors = try await embedder.embed(reference.sentences)

        // Indices 0/1 and 2/3 are the Italian/English translations; 4...7 are unrelated.
        let pairs = [(0, 1), (2, 3)]
        let unrelated = [4, 5, 6, 7]
        for (a, b) in pairs {
            let affine = dot(vectors[a], vectors[b])
            for other in unrelated {
                let unrelatedScore = max(dot(vectors[a], vectors[other]), dot(vectors[b], vectors[other]))
                #expect(
                    affine > unrelatedScore,
                    "pair \(a)/\(b) scores \(affine), unrelated \(other) scores \(unrelatedScore)")
            }
        }
    }

    @Test func truncatedVectorsStayUnitLengthAndMatchReference() async throws {
        let reference = try Fixture.reference()
        let embedder = try await TextEmbedder()
        let vectors = try await embedder.embed(
            Array(reference.sentences.prefix(2)), dimensions: 256)

        for (index, vector) in vectors.enumerated() {
            #expect(vector.count == 256)
            let norm = vector.reduce(Float(0)) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(norm - 1) < 1e-4)
            let truncated = Array(reference.embeddings[index].prefix(256))
            let similarity = cosine(vector.map(Double.init), truncated)
            #expect(similarity > 0.99, "sentence \(index): cosine \(similarity) at 256 dims")
        }
    }

    @Test func installedCheckpointPassesVerification() async throws {
        try await TextEmbedder.verify()
    }
}

/// The check of the welcome window: a folder without a usable checkpoint must fail, never pass as ready.
struct TextEmbedderVerifyTests {

    @Test func emptyFolderFailsVerification() async throws {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: "axi-verify-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        await #expect(throws: (any Error).self) {
            try await TextEmbedder.verify(modelDirectory: folder)
        }
    }
}
