import Foundation
import Testing
@testable import AxiCore

@Suite("Scaricamento dei PDF dalle pagine web", .serialized)
struct WebPageDownloaderTests {
    /// Answers every request with a declared size above the limit and a tiny PDF body.
    final class OversizeProtocol: URLProtocol {
        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
            let headers = ["Content-Length": String(WebPageDownloader.maxBytes + 1), "Content-Type": "application/pdf"]
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data("%PDF-1.4 piccolo".utf8))
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }

    private func downloader() -> WebPageDownloader {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [OversizeProtocol.self]
        return WebPageDownloader(session: URLSession(configuration: configuration))
    }

    @Test("Un PDF dichiarato oltre il massimo è rifiutato anche senza estensione .pdf")
    func declaredOversizeIsRefusedForEveryAddress() async throws {
        let address = try #require(URL(string: "https://example.com/documento"))
        let result = try await downloader().download(address)

        // The download never starts: nothing is returned as a PDF.
        #expect(result == .notPDF)
    }

    @Test("Un indirizzo .pdf con dimensione dichiarata oltre il massimo è rifiutato come troppo grande")
    func declaredOversizePDFIsTooLarge() async throws {
        let address = try #require(URL(string: "https://example.com/documento.pdf"))
        await #expect(throws: WebPageDownloadFailure.tooLarge) {
            _ = try await downloader().download(address)
        }
    }
}
