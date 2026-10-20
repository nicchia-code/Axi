import Foundation
import MLXHuggingFace
import MLXLMCommon
import MLXVLM
import Tokenizers

/// Turns texts into unit-length vectors with EmbeddingGemma 2, running on MLX.
///
/// Only the text path is loaded: vision and audio weights stay out of memory.
public actor TextEmbedder {

    /// Folder name of the checkpoint inside Axi's models folder: 8-bit MLX weights
    /// (`mlx-community/embeddinggemma-2-8bit`), chosen by the measurements in the README.
    public static let modelFolderName = "embeddinggemma-2-8bit"

    /// `~/Library/Application Support/Axi/models/embeddinggemma-2-8bit`.
    public static var defaultModelDirectory: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "Axi", directoryHint: .isDirectory)
            .appending(path: "models", directoryHint: .isDirectory)
            .appending(path: modelFolderName, directoryHint: .isDirectory)
    }

    private let embedder: EmbeddingGemma2Embedding

    /// Loads the checkpoint in `modelDirectory`, which must be a local `embedding_gemma2` folder.
    public init(modelDirectory: URL = TextEmbedder.defaultModelDirectory) async throws {
        embedder = try await EmbeddingGemma2Embedding(
            modelDirectory: modelDirectory,
            tokenizerLoader: #huggingFaceTokenizerLoader(),
            loadVision: false,
            loadAudio: false)
    }

    /// Loads the checkpoint in `modelDirectory` and embeds a probe text, to check that the model
    /// loads and answers before it is used. Throws if loading fails or the answer is not a unit vector of 768 finite values.
    public static func verify(modelDirectory: URL = TextEmbedder.defaultModelDirectory) async throws {
        let embedder = try await TextEmbedder(modelDirectory: modelDirectory)
        let vectors = try await embedder.embed(["Test di avvio del modello."])
        guard vectors.count == 1, vectors[0].count == 768,
              vectors[0].allSatisfy(\.isFinite) else {
            throw TextEmbedderError.unexpectedOutput
        }
        let norm = vectors[0].reduce(Float(0)) { $0 + $1 * $1 }.squareRoot()
        guard abs(norm - 1) < 1e-3 else {
            throw TextEmbedderError.unexpectedOutput
        }
    }

    /// Embeds each text, in order. Vectors are unit length.
    ///
    /// - Parameters:
    ///   - texts: Texts to embed. Compared vectors must come from the same `task`.
    ///   - task: The task prefix of the model card. Use `.sentenceSimilarity` to compare texts.
    ///   - dimensions: 768 for the full vector, or 512, 256, 128 (Matryoshka truncation).
    public func embed(
        _ texts: [String],
        task: EmbeddingGemma2Embedding.Task = .sentenceSimilarity,
        dimensions: Int = 768
    ) async throws -> [[Float]] {
        try await embedder.embed(
            texts.map { EmbeddingGemma2Embedding.Input(text: $0) },
            task: task,
            dimensions: dimensions)
    }
}

/// The checkpoint loaded but its answer is not a usable embedding.
public enum TextEmbedderError: Error, LocalizedError, Sendable, Equatable {
    case unexpectedOutput

    public var errorDescription: String? {
        switch self {
        case .unexpectedOutput: "the model answered with an unexpected vector"
        }
    }
}

