import Foundation

/// A file open in the front application.
public struct FileDocument: Sendable, Equatable {
    public var url: URL
    public var source: ApplicationSnapshot

    public init(url: URL, source: ApplicationSnapshot) {
        self.url = url
        self.source = source
    }
}

/// The message open or selected in Outlook.
public struct EmailMessage: Sendable, Equatable {
    public var sender: String?
    public var recipients: [String]
    public var subject: String?
    public var sentAt: String?
    public var body: String
    public var attachmentNames: [String]
    public var source: ApplicationSnapshot

    public init(
        sender: String?,
        recipients: [String],
        subject: String?,
        sentAt: String?,
        body: String,
        attachmentNames: [String],
        source: ApplicationSnapshot
    ) {
        self.sender = sender
        self.recipients = recipients
        self.subject = subject
        self.sentAt = sentAt
        self.body = body
        self.attachmentNames = attachmentNames
        self.source = source
    }
}

/// The page open in a browser.
public struct WebPage: Sendable, Equatable {
    public var address: URL
    /// The page title, as the page area or the browser window gives it; nil when neither has one.
    public var title: String?
    public var visibleText: String?
    public var source: ApplicationSnapshot

    public init(address: URL, title: String? = nil, visibleText: String?, source: ApplicationSnapshot) {
        self.address = address
        self.title = title
        self.visibleText = visibleText
        self.source = source
    }
}

/// Something Axi can archive, found in the front window.
public enum DocumentCandidate: Sendable, Equatable {
    case file(FileDocument)
    case email(EmailMessage)
    case webPage(WebPage)

    /// The origin name the user knows the document by: the file name with its extension, the email subject,
    /// the page title. Nil when there is none (an email without subject, a page without title).
    public var originName: String? {
        switch self {
        case .file(let file): file.url.lastPathComponent
        case .email(let email): nonEmpty(email.subject)
        case .webPage(let page): nonEmpty(page.title)
        }
    }
}

/// Chooses the archivable documents in the front window: an email, a web page, a file, or the files of a Finder selection.
public struct DocumentFinder: Sendable {
    public static let mailBundleIdentifiers: Set<String> = ["com.microsoft.Outlook"]
    static let firefoxBundleIdentifier = "org.mozilla.firefox"
    public static let finderBundleIdentifier = "com.apple.finder"
    public static let browserBundleIdentifiers: Set<String> = [
        "com.apple.Safari",
        "com.google.Chrome",
        firefoxBundleIdentifier,
    ]

    public init() {}

    /// The archivable documents in the front window, or why there are none. A Finder selection gives all its files.
    public func find(in snapshot: AccessibilitySnapshot) -> Result<[DocumentCandidate], NoDocumentReason> {
        let app = snapshot.application
        let bundle = app.bundleIdentifier ?? ""
        if Self.mailBundleIdentifiers.contains(bundle) {
            guard let message = OutlookMessageReader.read(snapshot.window, source: app) else {
                return .failure(.nothingInFront)
            }
            return .success([.email(message)])
        }
        if Self.browserBundleIdentifiers.contains(bundle) {
            guard let address = BrowserAddress.pageURL(in: snapshot.window) else {
                return .failure(.addressUnreadable)
            }
            // A file the browser shows is a file open in any other app; only http/https is a web page.
            // A folder is not a document, as in the Finder.
            if address.isFileURL {
                guard !Self.isFolder(address) else { return .failure(.nothingInFront) }
                return .success([.file(FileDocument(url: address, source: app))])
            }
            let page = WebPage(
                address: address,
                title: Self.pageTitle(in: snapshot.window),
                visibleText: VisibleTextReader.pageText(in: snapshot.window),
                source: app)
            return .success([.webPage(page)])
        }
        if bundle == Self.finderBundleIdentifier {
            return Self.finderDocuments(in: snapshot.selectedURLs, source: app)
        }
        guard let url = snapshot.window.url, url.isFileURL, !Self.isFolder(url) else {
            return .failure(.nothingInFront)
        }
        return .success([.file(FileDocument(url: url, source: app))])
    }

    /// The files of a Finder selection, in selection order. Folders are not documents and are left out;
    /// a selection with no file gives nothingInFront.
    public static func finderDocuments(in urls: [URL], source: ApplicationSnapshot) -> Result<[DocumentCandidate], NoDocumentReason> {
        let files = urls
            .filter { $0.isFileURL && !isFolder($0) }
            .map { DocumentCandidate.file(FileDocument(url: $0, source: source)) }
        return files.isEmpty ? .failure(.nothingInFront) : .success(files)
    }

    /// The title of the page: the page area's, else the browser window's.
    private static func pageTitle(in window: AccessibilityNode) -> String? {
        let area = window.descendantsAndSelf.first { $0.role == AccessibilityRole.webArea }
        return nonEmpty(area?.title) ?? nonEmpty(window.title)
    }

    private static func isFolder(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}

/// The address of the page shown by a browser window: http, https or file.
enum BrowserAddress {
    static func pageURL(in window: AccessibilityNode) -> URL? {
        // The page area first; the window's own address only when the page area has none; then the address bar.
        let nodes = window.descendantsAndSelf
        if let url = nodes.lazy
            .filter({ $0.role == AccessibilityRole.webArea })
            .compactMap(\.url)
            .first(where: isReadable) {
            return url
        }
        if let url = window.url, isReadable(url) {
            return url
        }
        return addressBarURL(in: window)
    }

    /// The address typed in the browser's address bar, or nil when there is no address field or it is empty.
    static func addressBarURL(in window: AccessibilityNode) -> URL? {
        window.descendantsAndSelf
            .lazy
            .filter(isAddressField)
            .compactMap { normalized(nonEmpty($0.value)) }
            .first
    }

    private static func isAddressField(_ node: AccessibilityNode) -> Bool {
        guard node.role == AccessibilityRole.textField || node.role == AccessibilityRole.comboBox else {
            return false
        }
        let name = ((node.label ?? "") + " " + (node.title ?? "")).lowercased()
        return name.contains("address") || name.contains("indirizzo")
    }

    static func normalized(_ text: String?) -> URL? {
        guard var text = text, !text.isEmpty else { return nil }
        if !text.contains("://") {
            text = "https://" + text
        }
        guard let url = URL(string: text), isReadable(url) else { return nil }
        return url
    }

    /// A web page (http, https with a host) or a file (file://); other addresses are not read.
    private static func isReadable(_ url: URL) -> Bool {
        if url.isFileURL { return true }
        guard let scheme = url.scheme?.lowercased() else { return false }
        return (scheme == "http" || scheme == "https") && url.host != nil
    }
}
