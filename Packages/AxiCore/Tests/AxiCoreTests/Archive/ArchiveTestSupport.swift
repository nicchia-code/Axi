import AxiScreen
import CoreGraphics
import Foundation
@testable import AxiCore

/// Files of the repository `Fixtures/` folder, found from this source file.
enum ArchiveFixtures {
    static func url(_ name: String) -> URL {
        // .../Axi/Packages/AxiCore/Tests/AxiCoreTests/Archive/ArchiveTestSupport.swift
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<6 { root.deleteLastPathComponent() }
        return root.appending(path: "Fixtures").appending(path: name)
    }
}

/// The AI reply every test uses unless it says otherwise.
let validMetadataReply = """
    {"title": "Fattura di prova", "summary": "Un riassunto breve.", "tags": ["fattura", "progetto"], \
    "documentDate": "2025-10-06", "language": "it"}
    """

struct FakeAssistant: AIAssistant {
    var reply: String = validMetadataReply

    func complete(_ prompt: String) async throws -> String { reply }
}

/// Never answers: waits until the task is cancelled.
struct SilentAssistant: AIAssistant {
    func complete(_ prompt: String) async throws -> String {
        try await Task.sleep(for: .seconds(60))
        return validMetadataReply
    }
}

struct FakeEmbedder: TextEmbedding {
    var dimension = 3
    var answersCount: Int?

    func embed(_ texts: [String]) async throws -> [[Float]] {
        let count = answersCount ?? texts.count
        return (0..<count).map { _ in Array(repeating: Float(0.5), count: dimension) }
    }
}

struct FakeRecognizer: TextRecognizing {
    let source = TextSource.vision
    var text = "testo riconosciuto"

    func recognizeText(in image: CGImage) async throws -> String { text }
}

/// Fails the way the recognizer can fail on a scanned page: with an error that is not an unreadable file.
struct ThrowingRecognizer: TextRecognizing {
    struct Broken: Error {}
    let source = TextSource.vision

    func recognizeText(in image: CGImage) async throws -> String { throw Broken() }
}

/// Answers as Azure Document Intelligence does: the submission is accepted and the analysis
/// succeeds with `text`. It stands in for the network.
struct AzureStubTransport: HTTPTransport {
    var text: String

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let url = request.url!
        if request.httpMethod == "POST" {
            let operation = "https://axi.cognitiveservices.azure.com/documentintelligence/documentModels/prebuilt-read/analyzeResults/prova?api-version=2024-11-30"
            let response = HTTPURLResponse(
                url: url, statusCode: 202, httpVersion: nil, headerFields: ["Operation-Location": operation])!
            return (Data(), response)
        }
        let body = try JSONSerialization.data(
            withJSONObject: ["status": "succeeded", "analyzeResult": ["content": text]])
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (body, response)
    }
}

/// The Azure recognizer the archive receives when Azure is configured, answering with `text`.
func azureRecognizer(text: String) -> AzureTextRecognizer {
    AzureTextRecognizer(
        client: AzureDocumentIntelligenceClient(
            configuration: AzureDocumentIntelligenceConfiguration(
                endpoint: URL(string: "https://axi.cognitiveservices.azure.com/")!, apiKey: "chiave-di-prova"),
            transport: AzureStubTransport(text: text),
            pollInterval: .milliseconds(1),
            maxPolls: 5))
}

struct FakeWebPages: WebPageRendering {
    var result: Data?

    func pdf(of address: URL) async throws -> Data {
        guard let result else { throw WebPageRenderer.Failure.loadFailed }
        return result
    }
}

/// Answers the configured download, without the network.
struct FakeWebPageDownloader: WebPageDownloading {
    var answer: Result<WebPageDownload, WebPageDownloadFailure>

    init(_ answer: Result<WebPageDownload, WebPageDownloadFailure> = .success(.notPDF)) {
        self.answer = answer
    }

    func download(_ address: URL) async throws -> WebPageDownload {
        try answer.get()
    }

    /// A PDF answer whose temporary file is a copy of a fixture, as the downloader would leave it.
    static func pdf(fixture: String, suggestedName: String) throws -> WebPageDownload {
        let copy = FileManager.default.temporaryDirectory.appending(path: "axi-test-\(UUID().uuidString).pdf")
        try FileManager.default.copyItem(at: ArchiveFixtures.url(fixture), to: copy)
        return .pdf(file: copy, suggestedName: suggestedName)
    }
}

struct FakeOutlook: OutlookEmailReading {
    func emailOnScreen() async -> EmailMessage? { nil }
}

struct FakeAttachments: AttachmentTaking {
    var answers: [TakenAttachment]

    func take(_ email: EmailMessage, into directory: URL) async -> [TakenAttachment] { answers }
}

/// A vault in a temporary folder, and the pipeline wired to it with fakes.
struct ArchiveTestBench {
    static let archivedAt = Date(timeIntervalSince1970: 1_760_000_000)
    /// The reading that found the test documents: relative dates resolve against it.
    static let readingMoment = ReadingMoment(
        date: Date(timeIntervalSince1970: 1_759_900_000),
        timeZone: TimeZone(identifier: "Europe/Rome")!
    )

    let root: URL
    let vault: VaultStore
    let app = ApplicationSnapshot(bundleIdentifier: "com.apple.Preview", name: "Anteprima", processIdentifier: 1)

    init() throws {
        root = FileManager.default.temporaryDirectory.appending(path: "archive-\(UUID().uuidString)")
        vault = try VaultStore(
            databaseURL: root.appending(path: "vault.sqlite"),
            filesDirectory: root.appending(path: "files"),
            embeddingDimension: 3
        )
    }

    var filesDirectory: URL { vault.filesDirectory }

    /// Number of files in the vault folder: nothing must stay there after a failed archiving.
    var storedFileCount: Int {
        (try? FileManager.default.contentsOfDirectory(atPath: filesDirectory.path()).count) ?? 0
    }

    /// A copy of a fixture in a folder outside the vault, as the user would have it.
    func userFile(_ name: String, as newName: String? = nil) throws -> URL {
        let folder = root.appending(path: "user")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let target = folder.appending(path: newName ?? name)
        try? FileManager.default.removeItem(at: target)
        try FileManager.default.copyItem(at: ArchiveFixtures.url(name), to: target)
        return target
    }

    func pipeline(
        assistant: any AIAssistant = FakeAssistant(),
        embedder: any TextEmbedding = FakeEmbedder(),
        recognizer: any TextRecognizing = FakeRecognizer(),
        attachments: (any AttachmentTaking)? = nil,
        webPages: any WebPageRendering = FakeWebPages(),
        downloads: any WebPageDownloading = FakeWebPageDownloader(),
        outlook: any OutlookEmailReading = FakeOutlook()
    ) -> ArchivingPipeline {
        ArchivingPipeline(
            vault: vault,
            recognizer: recognizer,
            assistant: assistant,
            embedder: embedder,
            attachments: attachments,
            webPages: webPages,
            downloads: downloads,
            outlook: outlook,
            interfaceLanguage: "it",
            contextWindowTokens: { 32_000 },
            now: { Self.archivedAt },
            progresso: { _ in }
        )
    }
}
