# AxiEmbedding

Turns texts into vectors with EmbeddingGemma 2 (text only) on MLX Swift. Used by Axi's document indexing and search.

## Usage

```swift
let embedder = try await TextEmbedder()  // ~/Library/Application Support/Axi/models/embeddinggemma-2-8bit
let vectors = try await embedder.embed(["Il gatto dorme.", "A cat is sleeping."])
```

- `TextEmbedder` loads only the text path: vision and audio weights are excluded.
- Vectors are unit length, float32, 768 dimensions by default.
- `dimensions:` accepts 768, 512, 256 or 128 (Matryoshka truncation, then renormalization).
- `task:` defaults to `.sentenceSimilarity`; use `.searchQuery` and `.document` for retrieval.

## Model

- Model: EmbeddingGemma 2 (`google/embeddinggemma-2`, Apache-2.0). The Specs call it "EmbeddingGemma 2"; there is no `embeddinggemma-300m` in this version.
- Checkpoint: `mlx-community/embeddinggemma-2-8bit`, folder `embeddinggemma-2-8bit` under Axi's models folder. Download it once, for example with `huggingface-cli download mlx-community/embeddinggemma-2-8bit --local-dir "$HOME/Library/Application Support/Axi/models/embeddinggemma-2-8bit"`.
- Runtime: `mlx-swift-lm` (`MLXVLM`, `EmbeddingGemma2Embedding`), pinned to commit `48114eed` of `main`. The 3.32.3 tag does not include EmbeddingGemma 2 yet.
- Fallback: not needed. EmbeddingGemma 2 runs on MLX Swift on Apple Silicon, so no other model was chosen.

## Measurements

Apple Silicon (arm64), macOS 27.0, Xcode 27.1, release of the MLX library as pinned. Input: the 8 sentences of the test fixture, averaged over 10 runs after a warm-up. Memory is MLX active memory.

| Checkpoint | Live MLX memory after load | Peak MLX memory | Time per passage | Load |
|---|---|---|---|---|
| bf16 (`embeddinggemma-2-bf16`) | 542 MB | 565 MB | 0.044 s (0.137 s under other load) | 2.8 s to 7.1 s |
| 8-bit (`embeddinggemma-2-8bit`) | 288 MB | 309 MB | 0.046 s | 5.1 s |

Quality against the sentence-transformers reference (float32, text only):

| Dimensions | Min cosine vs reference (bf16 / 8-bit) | Affine pairs, min score (8-bit) | Unrelated, max score (8-bit) | Margin (8-bit) |
|---|---|---|---|---|
| 768 | 1.0000 / 0.9999 | 0.942 | 0.790 | 0.152 |
| 256 | 1.0000 / 0.9999 | 0.947 | 0.803 | 0.144 |
| 128 | 1.0000 / 0.9999 | 0.966 | 0.863 | 0.102 |

Decisions:

- **Quantization: 8-bit.** It halves memory (288 MB against 542 MB) and speed is the same. Its vectors agree with the reference to 0.9999 and the affine/unrelated margins are unchanged.
- **Dimension: 768.** The margin is largest at 768. 256 keeps most of the margin (0.144) and cuts vector storage to one third, so it is the option if the index grows. 128 loses too much margin (0.102).

## Tests

```sh
swift test
```

- `TextEmbedderTests` compares the vectors of Italian and English sentences with the reference fixture (`Tests/AxiEmbeddingTests/Fixtures/reference-sentence-similarity.json`), checks that affine pairs score above unrelated sentences, and checks 256-dimension truncation.
- These tests need the checkpoint in Axi's models folder. Without it they are skipped with a message; they never download anything.
- The benchmark is opt-in: `AXI_EMBEDDING_BENCHMARK=1 swift test --filter TextEmbedderBenchmark`. Set `AXI_EMBEDDING_MODEL_DIR` to measure another local checkpoint.

The reference fixture was generated with sentence-transformers 6.1, `google/embeddinggemma-2`, text only (`config_kwargs={"vision_config": None, "audio_config": None}`), float32, prefix `task: sentence similarity | query: `.
