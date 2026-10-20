import AxiScreen
import Foundation

/// The AI of the archiving: one prompt in, one text answer out. Live: the OMP `archive` session.
public protocol AIAssistant: Sendable {
    func complete(_ prompt: String) async throws -> String
}

/// Turns texts into vectors, one per text, of the size the vault was created with.
/// Live: `TextEmbedder` of AxiEmbedding, wrapped by the app.
public protocol TextEmbedding: Sendable {
    func embed(_ texts: [String]) async throws -> [[Float]]
}

/// One attachment of an email open in Outlook: saved to a file, or not taken.
public enum TakenAttachment: Sendable, Equatable {
    /// Saved as `url`, in the directory given to `AttachmentTaking.take`.
    case file(name: String, url: URL)
    /// Could not be taken.
    case missing(name: String)
}

/// Takes the attachments of an email open in Outlook. Names the answer does not list are missing.
public protocol AttachmentTaking: Sendable {
    func take(_ email: EmailMessage, into directory: URL) async -> [TakenAttachment]
}

/// Renders a web page as PDF bytes. Throws when the page does not load.
public protocol WebPageRendering: Sendable {
    func pdf(of address: URL) async throws -> Data
}

/// Result of downloading a web page address.
public enum WebPageDownload: Sendable, Equatable {
    /// The address served a PDF, written to a temporary file the caller removes; the name is the file name the server suggests.
    case pdf(file: URL, suggestedName: String)
    /// The address did not serve a PDF; the page is archived as a web page.
    case notPDF
}

/// Why downloading a web page address failed.
public enum WebPageDownloadFailure: Error, Equatable, Sendable {
    /// No answer within the time limit.
    case timedOut
    /// Network or server error.
    case network
    /// The response is not a PDF.
    case notPDF
    /// The PDF exceeds the size limit.
    case tooLarge
}

/// Downloads the PDF an address serves directly, without rendering the page.
public protocol WebPageDownloading: Sendable {
    func download(_ address: URL) async throws -> WebPageDownload
}

/// The email open in Outlook at this moment, if any.
public protocol OutlookEmailReading: Sendable {
    func emailOnScreen() async -> EmailMessage?
}
