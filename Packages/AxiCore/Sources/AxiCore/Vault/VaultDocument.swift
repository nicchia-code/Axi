import Foundation

/// The kinds of document the vault keeps.
public enum DocumentKind: String, Sendable, Equatable, CaseIterable {
    case pdf
    case word
    case email
    /// A web page. Without a PDF copy only its text and address are kept.
    case web
    case image
    case other
}

/// Where a document comes from: the app, the original path, or the web address.
public struct DocumentSource: Sendable, Equatable {
    public var app: String?
    public var path: String?
    public var url: String?

    public init(app: String? = nil, path: String? = nil, url: String? = nil) {
        self.app = app
        self.path = path
        self.url = url
    }
}

/// The text of one page of a document.
public struct DocumentPage: Sendable, Equatable {
    public var number: Int
    public var text: String

    public init(number: Int, text: String) {
        self.number = number
        self.text = text
    }
}

/// An indexed passage of a document, with its embedding vector. `page` is the page the
/// passage comes from; nil when the document has no pages.
public struct DocumentChunk: Sendable, Equatable {
    public var text: String
    public var embedding: [Float]
    public var page: Int?

    public init(text: String, embedding: [Float], page: Int? = nil) {
        self.text = text
        self.embedding = embedding
        self.page = page
    }
}

/// The data an email keeps beyond the common document fields.
public struct EmailDetails: Sendable, Equatable {
    public var sender: String
    public var recipients: [String]
    public var subject: String
    /// When the email was received. Nil when its receipt date is not known.
    public var sentAt: Date?
    /// The date as Outlook showed it on screen, in text, when the email came from Outlook.
    public var displayedSentAt: String?
    /// Names of the attachments Axi could not take; kept so the user can add them later.
    public var missingAttachmentNames: [String]

    public init(
        sender: String,
        recipients: [String],
        subject: String,
        sentAt: Date?,
        displayedSentAt: String? = nil,
        missingAttachmentNames: [String] = []
    ) {
        self.sender = sender
        self.recipients = recipients
        self.sentAt = sentAt
        self.subject = subject
        self.displayedSentAt = displayedSentAt
        self.missingAttachmentNames = missingAttachmentNames
    }
}

/// A date the vault keeps as absolute. An instant keeps the UTC offset the Mac's time zone
/// had at that instant; a day has no time, and none is invented for it.
public enum AbsoluteDate: Sendable, Equatable, Hashable, Codable {
    case instant(Date)
    /// A day: the calendar day of this date in UTC, which is how a day is held in memory.
    case day(Date)
}

/// A date the text cites: an event, a deadline or an appointment.
public struct CitedDate: Sendable, Equatable, Hashable, Codable {
    /// Nil only for a relative date of an email whose receipt date is unknown.
    public var date: AbsoluteDate?
    /// What the date is, in short words.
    public var about: String
    /// The words of the text the date comes from.
    public var originalText: String

    public init(date: AbsoluteDate?, about: String, originalText: String) {
        self.date = date
        self.about = about
        self.originalText = originalText
    }
}

/// A document that the archiving work hands to the vault once it is ready.
public struct ArchivedDocument: Sendable, Equatable {
    public var id: String
    public var title: String
    public var kind: DocumentKind
    /// Name of the file as it was in the source.
    public var originalName: String?
    /// Path of the copy in the vault's files folder, relative to that folder.
    public var copyPath: String?
    /// True for a web page archived without its PDF: only text and address are kept.
    public var pdfMissing: Bool
    public var source: DocumentSource
    public var contentHash: String
    /// Date taken from the content; may be missing.
    public var documentDate: Date?
    public var archivedAt: Date
    public var language: String?
    public var summary: String
    public var tags: [String]
    public var pages: [DocumentPage]
    public var chunks: [DocumentChunk]
    /// Dates the text cites, at most 20, in the order they appear.
    public var citedDates: [CitedDate]
    /// Set only for an email.
    public var email: EmailDetails?
    /// Set only for an attachment: the id of the email it is attached to.
    public var emailID: String?

    public init(
        id: String,
        title: String,
        kind: DocumentKind,
        originalName: String? = nil,
        copyPath: String? = nil,
        pdfMissing: Bool = false,
        source: DocumentSource = DocumentSource(),
        contentHash: String,
        documentDate: Date? = nil,
        archivedAt: Date,
        language: String? = nil,
        summary: String,
        tags: [String] = [],
        pages: [DocumentPage] = [],
        chunks: [DocumentChunk] = [],
        citedDates: [CitedDate] = [],
        email: EmailDetails? = nil,
        emailID: String? = nil
    ) {
        self.id = id
        self.title = title
        self.kind = kind
        self.originalName = originalName
        self.copyPath = copyPath
        self.pdfMissing = pdfMissing
        self.source = source
        self.contentHash = contentHash
        self.documentDate = documentDate
        self.archivedAt = archivedAt
        self.language = language
        self.summary = summary
        self.tags = tags
        self.pages = pages
        self.chunks = chunks
        self.citedDates = citedDates
        self.email = email
        self.emailID = emailID
    }
}

/// A document as stored in the vault, with the fields that identify it and its links.
public struct StoredDocument: Sendable, Equatable {
    public var id: String
    public var title: String
    public var kind: DocumentKind
    public var emailID: String?
    public var tags: [String]
}
