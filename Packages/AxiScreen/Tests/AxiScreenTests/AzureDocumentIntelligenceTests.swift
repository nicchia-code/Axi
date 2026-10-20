import Foundation
import Testing
@testable import AxiScreen

/// Returns scripted responses in order and records the requests.
actor ScriptedTransport: HTTPTransport {
    private var responses: [(status: Int, headers: [String: String], body: String)]
    private(set) var requests: [URLRequest] = []

    init(_ responses: [(status: Int, headers: [String: String], body: String)]) {
        self.responses = responses
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        let next = responses.removeFirst()
        let response = HTTPURLResponse(
            url: request.url!, statusCode: next.status, httpVersion: nil, headerFields: next.headers)!
        return (Data(next.body.utf8), response)
    }
}

private let endpoint = URL(string: "https://axi.cognitiveservices.azure.com/")!
private let configuration = AzureDocumentIntelligenceConfiguration(endpoint: endpoint, apiKey: "chiave-di-prova")
private let operationURL = "https://axi.cognitiveservices.azure.com/documentintelligence/documentModels/prebuilt-read/analyzeResults/abc?api-version=2024-11-30"

private func client(_ transport: ScriptedTransport) -> AzureDocumentIntelligenceClient {
    AzureDocumentIntelligenceClient(
        configuration: configuration,
        transport: transport,
        pollInterval: .milliseconds(1),
        maxPolls: 5)
}

@Test func extractsTextAfterPollingUntilSucceeded() async throws {
    let transport = ScriptedTransport([
        (202, ["Operation-Location": operationURL], ""),
        (200, [:], #"{"status":"running"}"#),
        (200, [:], #"{"status":"succeeded","analyzeResult":{"content":"Fattura n. 7\nTotale 120,00"}}"#),
    ])

    let text = try await client(transport).extractText(from: Data([1, 2, 3]), contentType: "application/pdf")

    #expect(text == "Fattura n. 7\nTotale 120,00")
    let submit = try #require(await transport.requests.first)
    #expect(submit.httpMethod == "POST")
    #expect(submit.url?.absoluteString == "https://axi.cognitiveservices.azure.com/documentintelligence/documentModels/prebuilt-read:analyze?api-version=2024-11-30")
    #expect(submit.value(forHTTPHeaderField: "Ocp-Apim-Subscription-Key") == "chiave-di-prova")
    #expect(submit.value(forHTTPHeaderField: "Content-Type") == "application/pdf")
    #expect(submit.httpBody == Data([1, 2, 3]))
    #expect(await transport.requests.count == 3)
}

@Test func failedAnalysisThrows() async throws {
    let transport = ScriptedTransport([
        (202, ["Operation-Location": operationURL], ""),
        (200, [:], #"{"status":"failed"}"#),
    ])
    await #expect(throws: AzureDocumentIntelligenceError.analysisFailed) {
        try await client(transport).extractText(from: Data(), contentType: "image/png")
    }
}

@Test func rejectedKeyThrowsStatus() async throws {
    let transport = ScriptedTransport([(401, [:], "")])
    await #expect(throws: AzureDocumentIntelligenceError.httpStatus(401)) {
        try await client(transport).extractText(from: Data(), contentType: "image/png")
    }
}

@Test func missingOperationLocationThrows() async throws {
    let transport = ScriptedTransport([(202, [:], "")])
    await #expect(throws: AzureDocumentIntelligenceError.invalidResponse) {
        try await client(transport).extractText(from: Data(), contentType: "image/png")
    }
}

@Test func neverSucceedingAnalysisTimesOut() async throws {
    let transport = ScriptedTransport([
        (202, ["Operation-Location": operationURL], ""),
        (200, [:], #"{"status":"running"}"#),
        (200, [:], #"{"status":"running"}"#),
        (200, [:], #"{"status":"running"}"#),
        (200, [:], #"{"status":"running"}"#),
        (200, [:], #"{"status":"running"}"#),
    ])
    await #expect(throws: AzureDocumentIntelligenceError.timedOut) {
        try await client(transport).extractText(from: Data(), contentType: "image/png")
    }
}

@Test func checkConnectionFailsWithWrongKey() async throws {
    // checkConnection uses the real transport, so only the endpoint validation is exercised offline.
    let invalid = AzureDocumentIntelligenceConfiguration(endpoint: URL(string: "ftp://example.com")!, apiKey: "x")
    await #expect(throws: AzureDocumentIntelligenceError.invalidEndpoint) {
        try await AzureDocumentIntelligenceClient.checkConnection(configuration: invalid)
    }
}
