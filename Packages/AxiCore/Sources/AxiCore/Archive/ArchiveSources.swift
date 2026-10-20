import AppKit
import AxiScreen
import Foundation
import WebKit

/// Prints a web page to PDF, loading it in a hidden web view.
public struct WebPageRenderer: WebPageRendering {
    public enum Failure: Error, Equatable {
        case timedOut
        case loadFailed
        case processTerminated
    }

    /// Wait after the load finishes, before the PDF is created: the page may still be laying out.
    private static let settleDelay: Duration = .seconds(1)

    /// One limit for the load and the creation of the PDF together.
    private let timeout: Duration

    public init(timeout: Duration = .seconds(45)) {
        self.timeout = timeout
    }

    public func pdf(of address: URL) async throws -> Data {
        try await renderPDF(of: address, timeout: timeout)
    }

    @MainActor
    private func renderPDF(of address: URL, timeout: Duration) async throws -> Data {
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 1024, height: 1400))
        // A borderless window that is never shown: the web view needs a window to lay the page out.
        // It is not released on close: it lives until the PDF is ready, and is released once, here.
        let window = NSWindow(
            contentRect: webView.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = webView
        defer { window.close() }

        let loader = PageLoader(webView: webView)
        webView.navigationDelegate = loader

        let deadline = Task { @MainActor in
            do {
                try await Task.sleep(for: timeout)
            } catch {
                return
            }
            loader.fail(Failure.timedOut)
        }
        defer { deadline.cancel() }

        try await loader.load(address: address)
        try await Task.sleep(for: Self.settleDelay)
        return try await loader.pdf()
    }
}

/// Downloads the PDF an address serves directly. The temporary file exists only once the response is confirmed as a PDF.
public struct WebPageDownloader: WebPageDownloading {
    /// Largest PDF kept, in bytes.
    static let maxBytes = 200_000_000
    /// Time for a PDF from an address that does not say it is one; past it, the page is rendered instead.
    static let firstAnswerLimit: Duration = .seconds(15)
    /// Time for the whole download.
    static let totalLimit: Duration = .seconds(120)
    /// Bytes gathered before each write to the temporary file.
    private static let chunkSize = 64 * 1024

    private let session: URLSession

    public init(session: URLSession = URLSession(configuration: .ephemeral)) {
        self.session = session
    }

    public func download(_ address: URL) async throws -> WebPageDownload {
        let says = Self.saysPDF(address)
        let target = FileManager.default.temporaryDirectory.appending(path: "axi-web-\(UUID().uuidString).pdf")
        do {
            return try await withThrowingTaskGroup(of: WebPageDownload.self) { group in
                group.addTask {
                    try await self.receive(address, says: says, target: target)
                }
                group.addTask { () async throws -> WebPageDownload in
                    let first = says ? Self.totalLimit : Self.firstAnswerLimit
                    try await Task.sleep(for: first)
                    if !FileManager.default.fileExists(atPath: target.path) {
                        throw WebPageDownloadFailure.timedOut
                    }
                    try await Task.sleep(for: Self.totalLimit - first)
                    throw WebPageDownloadFailure.timedOut
                }
                guard let result = try await group.next() else { throw WebPageDownloadFailure.network }
                return result
            }
        } catch let failure as WebPageDownloadFailure {
            // Confirmed as a PDF only when the temporary file exists: before that, the page is archived as a web page.
            let confirmed = FileManager.default.fileExists(atPath: target.path)
            try? FileManager.default.removeItem(at: target)
            if !says && !confirmed { return .notPDF }
            throw failure
        } catch {
            try? FileManager.default.removeItem(at: target)
            throw error
        }
    }

    /// Streams the response; throws a failure, or a cancellation, without writing a non-PDF response.
    private func receive(_ address: URL, says: Bool, target: URL) async throws -> WebPageDownload {
        var request = URLRequest(url: address)
        request.timeoutInterval = 120
        do {
            let (bytes, response) = try await session.bytes(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw WebPageDownloadFailure.network
            }
            if http.expectedContentLength > Self.maxBytes {
                throw WebPageDownloadFailure.tooLarge
            }
            var head: [UInt8] = []
            var buffer = Data()
            var received = 0
            var handle: FileHandle?
            defer { try? handle?.close() }
            for try await byte in bytes {
                received += 1
                if received > Self.maxBytes { throw WebPageDownloadFailure.tooLarge }
                if let handle {
                    buffer.append(byte)
                    if buffer.count >= Self.chunkSize {
                        try handle.write(contentsOf: buffer)
                        buffer.removeAll(keepingCapacity: true)
                    }
                } else {
                    head.append(byte)
                    if head.count == 4 {
                        guard head == Array("%PDF".utf8) else { throw WebPageDownloadFailure.notPDF }
                        FileManager.default.createFile(atPath: target.path, contents: nil)
                        handle = try FileHandle(forWritingTo: target)
                        buffer.append(contentsOf: head)
                    }
                }
            }
            guard let handle else { throw WebPageDownloadFailure.notPDF }
            if !buffer.isEmpty { try handle.write(contentsOf: buffer) }
            return .pdf(file: target, suggestedName: Self.suggestedName(response, address: address))
        } catch let error as URLError {
            switch error.code {
            case .timedOut: throw WebPageDownloadFailure.timedOut
            case .cancelled: throw CancellationError()
            default: throw WebPageDownloadFailure.network
            }
        }
    }

    /// An address whose path ends in `.pdf` is expected to serve a PDF.
    static func saysPDF(_ address: URL) -> Bool {
        address.pathExtension.lowercased() == "pdf"
    }

    /// The name the server suggests, else the last path component, else the host.
    static func suggestedName(_ response: URLResponse, address: URL) -> String {
        if let name = response.suggestedFilename, !name.isEmpty { return name }
        let last = address.lastPathComponent
        if !last.isEmpty && last != "/" { return last }
        return "\(address.host ?? "pagina").pdf"
    }
}

/// Resumes the load and the PDF of one page: the first outcome (or the timeout) wins, and the others are ignored.
@MainActor
private final class PageLoader: NSObject, WKNavigationDelegate {
    private let webView: WKWebView
    private var loadContinuation: CheckedContinuation<Void, Error>?
    private var pdfContinuation: CheckedContinuation<Data, Error>?
    /// The failure that ended the render. Once set, nothing waits any more.
    private var failure: Error?

    init(webView: WKWebView) {
        self.webView = webView
    }

    func load(address: URL) async throws {
        if let failure { throw failure }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            loadContinuation = continuation
            webView.load(URLRequest(url: address))
        }
    }

    func pdf() async throws -> Data {
        if let failure { throw failure }
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            pdfContinuation = continuation
            webView.createPDF(configuration: WKPDFConfiguration()) { result in
                MainActor.assumeIsolated { self.finishPDF(result) }
            }
        }
    }

    func fail(_ error: Error) {
        guard failure == nil else { return }
        failure = error
        loadContinuation?.resume(throwing: error)
        loadContinuation = nil
        pdfContinuation?.resume(throwing: error)
        pdfContinuation = nil
    }

    private func finishPDF(_ result: Result<Data, Error>) {
        pdfContinuation?.resume(with: result)
        pdfContinuation = nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadContinuation?.resume()
        loadContinuation = nil
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        fail(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        fail(error)
    }

    /// The page process stopped: the page will not finish, so the PDF fails at once.
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        fail(WebPageRenderer.Failure.processTerminated)
    }
}

/// Reads the message open in Outlook, from its Accessibility tree.
public struct OutlookWindowReader: OutlookEmailReading {
    public static let bundleIdentifier = "com.microsoft.Outlook"

    public init() {}

    public func emailOnScreen() async -> EmailMessage? {
        guard let running = NSRunningApplication
            .runningApplications(withBundleIdentifier: Self.bundleIdentifier)
            .first(where: { !$0.isTerminated })
        else { return nil }
        let application = ApplicationSnapshot(
            bundleIdentifier: Self.bundleIdentifier,
            name: running.localizedName ?? "Outlook",
            processIdentifier: running.processIdentifier
        )
        guard let snapshot = try? await LiveAccessibilityReader().snapshot(of: application) else { return nil }
        return OutlookMessageReader.read(snapshot.window, source: application)
    }
}

/// Takes the attachments of an email open in Outlook from its Accessibility tree.
///
/// Each attachment is saved through the save action its element offers, then the saved file is copied.
/// Assumption, not verified against the live app: the save action is named with "save" and leaves the file it
/// writes exposed as the element's `url`. An attachment whose save fails, or that exposes no saved file, is missing.
public struct OutlookAttachmentTaker: AttachmentTaking {
    private let reader: any AccessibilityReading

    public init(reader: any AccessibilityReading = LiveAccessibilityReader()) {
        self.reader = reader
    }

    /// Without a readable Outlook window nothing is taken.
    public func take(_ email: EmailMessage, into directory: URL) async -> [TakenAttachment] {
        guard let before = try? await reader.snapshot(of: email.source) else { return [] }
        var saved = Set<String>()
        for name in email.attachmentNames {
            guard let action = OutlookAttachments.saveAction(named: name, in: before.window) else { continue }
            if await reader.perform(action: action, onElementNamed: name, in: email.source) {
                saved.insert(name)
            }
        }
        guard let window = try? await reader.snapshot(of: email.source)?.window else {
            return email.attachmentNames.map { .missing(name: $0) }
        }
        return email.attachmentNames.enumerated().map { index, name in
            guard saved.contains(name), let file = OutlookAttachments.savedFile(named: name, in: window) else {
                return .missing(name: name)
            }
            // The index keeps two attachments with the same name apart in the scratch folder.
            let target = directory.appending(path: "\(index)-\(name.replacingOccurrences(of: "/", with: "_"))")
            do {
                try FileManager.default.copyItem(at: file, to: target)
                return .file(name: name, url: target)
            } catch {
                return .missing(name: name)
            }
        }
    }
}

enum OutlookAttachments {
    /// True for a file in Outlook's own folder, where it keeps the attachments it opens.
    /// Inference from the sandbox layout (`~/Library/Containers/com.microsoft.Outlook/...`), not verified live.
    static func isOutlookFolder(_ url: URL) -> Bool {
        url.path.contains("/com.microsoft.Outlook/")
    }

    /// The save action of the first element named `name` that offers one, if any.
    static func saveAction(named name: String, in window: AccessibilityNode) -> String? {
        for node in window.descendantsAndSelf where isNamed(node, name) {
            if let action = node.actions.first(where: { $0.localizedCaseInsensitiveContains("save") }) {
                return action
            }
        }
        return nil
    }

    /// The existing file that an element named `name` exposes after the save.
    static func savedFile(named name: String, in window: AccessibilityNode) -> URL? {
        window.descendantsAndSelf.lazy.compactMap { node -> URL? in
            guard isNamed(node, name), let url = node.url, url.isFileURL,
                  FileManager.default.fileExists(atPath: url.path)
            else { return nil }
            return url
        }.first
    }

    private static func isNamed(_ node: AccessibilityNode, _ name: String) -> Bool {
        [node.title, node.label].compactMap { $0 }.contains {
            $0.trimmingCharacters(in: .whitespaces).caseInsensitiveCompare(name) == .orderedSame
        }
    }
}
