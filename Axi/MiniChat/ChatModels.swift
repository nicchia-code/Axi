import Foundation

/// An instant with the time zone of the Mac at that instant. The zone is kept by identifier, so a saved
/// moment reads back with the same offset.
struct ZonedMoment: Codable, Equatable, Sendable {
    var date: Date
    var timeZoneIdentifier: String

    init(date: Date, timeZone: TimeZone) {
        self.date = date
        self.timeZoneIdentifier = timeZone.identifier
    }

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }
}

/// What the user had on screen when a question was asked.
struct ScreenContext: Codable, Equatable, Sendable {
    /// Name of the app in front.
    var appName: String
    /// Bundle identifier of that app, used to show its icon.
    var bundleIdentifier: String?
    /// Title of the document or of the window in front.
    var title: String
    /// Visible text; sent to the model with the question.
    var text: String
    /// When the screen was read. Nil for contexts saved before the reading moment was recorded.
    var moment: ZonedMoment? = nil
}

/// A document cited in an answer, with the page when known.
struct DocumentCitation: Codable, Equatable, Hashable, Sendable {
    var documentID: String
    var title: String
    var page: Int?
}

struct ChatMessage: Codable, Equatable, Sendable, Identifiable {
    enum Author: String, Codable, Sendable {
        case user
        case axi
    }

    var id: UUID
    var author: Author
    var text: String
    var date: Date
    /// Screen context that accompanied a user question, if any.
    var screenContext: ScreenContext?
    var citations: [DocumentCitation]
    /// Set on the message that tells the user the answer failed; the failure is saved with the conversation.
    var failure: ChatError? = nil
}

struct Conversation: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    /// Empty until the first question is sent.
    var title: String
    var createdAt: Date
    /// OMP session that holds the conversation's history.
    var ompSessionID: String?
    var messages: [ChatMessage]

    static func empty(id: UUID = UUID(), now: Date) -> Conversation {
        Conversation(id: id, title: "", createdAt: now, ompSessionID: nil, messages: [])
    }

    var lastMessageAt: Date {
        messages.last?.date ?? createdAt
    }

    var summary: ConversationSummary {
        ConversationSummary(id: id, title: title, lastMessageAt: lastMessageAt, ompSessionID: ompSessionID)
    }
}

struct ConversationSummary: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var title: String
    var lastMessageAt: Date
    var ompSessionID: String?
}

enum ConversationTitle {
    static let maxLength = 60

    /// The title of a conversation is its first question, shortened.
    static func make(from question: String) -> String {
        let collapsed = question
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        guard collapsed.count > maxLength else { return collapsed }
        return String(collapsed.prefix(maxLength - 1)) + "…"
    }
}

/// What a deletion would remove, shown to the user before confirming.
struct DeletionPreview: Codable, Equatable, Sendable {
    var documentID: String
    var title: String
    var kind: String
    var archivedAt: Date
    /// Titles of the attached documents that disappear with it.
    var attachments: [String]
}
