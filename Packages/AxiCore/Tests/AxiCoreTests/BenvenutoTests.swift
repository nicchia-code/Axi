import Foundation
import Testing
@testable import AxiCore

@Suite("Benvenuto flow")
struct BenvenutoFlowTests {
    @Test func continuesFromPermissionsToDownloadEvenWithoutPermissions() {
        var flow = BenvenutoFlow()
        #expect(flow.step == .permissions)
        flow.apply(.userContinues)
        #expect(flow.step == .modelDownload)
    }

    @Test func downloadedModelCompletes() {
        var flow = BenvenutoFlow(step: .modelDownload)
        flow.apply(.modelDownloaded)
        #expect(flow.step == .completed)
    }

    @Test func failedDownloadCanBeRetried() {
        var flow = BenvenutoFlow(step: .modelDownload)
        flow.apply(.downloadFailed)
        #expect(flow.step == .downloadFailed)
        flow.apply(.userRetriesDownload)
        #expect(flow.step == .modelDownload)
    }

    @Test func eventsOutOfStepChangeNothing() {
        var flow = BenvenutoFlow()
        flow.apply(.modelDownloaded)
        flow.apply(.userRetriesDownload)
        #expect(flow.step == .permissions)
    }
}

@Suite("Benvenuto store")
struct BenvenutoStoreTests {
    @Test func notCompletedUntilMarked() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let store = BenvenutoStore(fileURL: folder.appending(path: "benvenuto.json"))
        #expect(store.isCompleted() == false)
        try store.markCompleted()
        #expect(store.isCompleted())
        #expect(BenvenutoStore(fileURL: store.fileURL).isCompleted())
        try? FileManager.default.removeItem(at: folder)
    }
}

@Suite("Model repository files")
struct ModelRepositoryFilesTests {
    @Test func keepsWeightsAndTokenizerAndDropsMarkdownAndHidden() {
        let listed = [
            ".gitattributes", "1_Pooling/config.json", "2_Normalize/config.json", "README.md",
            "chat_template.jinja", "config.json", "config_sentence_transformers.json",
            "model.safetensors", "model.safetensors.index.json", "modules.json",
            "preprocessor_config.json", "processor_config.json", "sentence_bert_config.json",
            "tokenizer.json", "tokenizer_config.json", "validation.json",
        ]
        let wanted = ModelDownloader.wantedFiles(listed)
        #expect(wanted.contains("model.safetensors"))
        #expect(wanted.contains("config.json"))
        #expect(wanted.contains("tokenizer.json"))
        #expect(wanted.contains("1_Pooling/config.json"))
        #expect(!wanted.contains("README.md"))
        #expect(!wanted.contains(".gitattributes"))
        #expect(wanted.count == listed.count - 2)
    }
}

@Suite("Model file integrity")
struct ModelFileIntegrityTests {
    /// Writes `content` to a new temporary file and returns its location.
    private func temporaryFile(_ content: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try Data(content.utf8).write(to: url)
        return url
    }

    @Test func smallFileIsCheckedWithItsGitBlobHash() throws {
        let url = try temporaryFile("hello\n")
        defer { try? FileManager.default.removeItem(at: url) }
        // `printf 'hello\n' | git hash-object --stdin`
        let file = ModelFile(
            name: "config.json", size: 6,
            digest: .gitBlob("ce013625030ba8dba906f756967f9e9ca394464a"))
        #expect(try ModelDownloader.matches(url, file))
    }

    @Test func sameSizeButAlteredContentIsRefused() throws {
        let url = try temporaryFile("hellO\n")
        defer { try? FileManager.default.removeItem(at: url) }
        let file = ModelFile(
            name: "config.json", size: 6,
            digest: .gitBlob("ce013625030ba8dba906f756967f9e9ca394464a"))
        #expect(try !ModelDownloader.matches(url, file))
    }

    @Test func largeFileIsCheckedWithItsSHA256() throws {
        let url = try temporaryFile("abc")
        defer { try? FileManager.default.removeItem(at: url) }
        let file = ModelFile(
            name: "model.safetensors", size: 3,
            digest: .sha256("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"))
        #expect(try ModelDownloader.matches(url, file))
    }

    @Test func listingGivesSizeAndHashOfEachWantedFile() throws {
        let listing = Data("""
        {"siblings": [
          {"rfilename": "README.md", "size": 10, "blobId": "0123456789012345678901234567890123456789"},
          {"rfilename": "config.json", "size": 6, "blobId": "ce013625030ba8dba906f756967f9e9ca394464a"},
          {"rfilename": "model.safetensors", "size": 3, "blobId": "f4995a2346b4c773588f9d6a16b9474504dcf422",
           "lfs": {"sha256": "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", "size": 3}}
        ]}
        """.utf8)
        let files = try ModelDownloader.files(listing: listing)
        #expect(files == [
            ModelFile(name: "config.json", size: 6,
                      digest: .gitBlob("ce013625030ba8dba906f756967f9e9ca394464a")),
            ModelFile(name: "model.safetensors", size: 3,
                      digest: .sha256("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")),
        ])
    }

    @Test func fileWithoutChecksumIsNotAccepted() {
        let listing = Data(#"{"siblings": [{"rfilename": "config.json", "size": 6}]}"#.utf8)
        #expect(throws: ModelDownloadError.self) {
            try ModelDownloader.files(listing: listing)
        }
    }
}
