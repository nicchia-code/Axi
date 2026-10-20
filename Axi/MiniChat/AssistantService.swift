import Foundation

/// One question sent to the assistant (OMP), with the conversation it belongs to.
struct AssistantRequest: Equatable, Sendable {
    var conversationID: UUID
    /// OMP session of the conversation; nil on the first question.
    var sessionID: String?
    var question: String
    /// When the question was asked: the assistant gives the model the current date and time.
    var asked: ZonedMoment
    /// Screen context that accompanies the question until removed.
    var screen: ScreenContext?
}

/// One step OMP takes while it writes an answer. A step is in progress until `stepFinished` carries its id.
struct AnswerStep: Equatable, Sendable, Identifiable {
    enum Kind: Equatable, Sendable {
        /// `words` is empty when the search had no words.
        case searchVault(words: String)
        case readPage(page: Int, title: String)
        case cite(count: Int)
        case changeTags(title: String)
        case askDeletion(title: String)
        case retry(attempt: Int, maxAttempts: Int)
        case summarize
    }

    let id: UUID
    let kind: Kind
    /// Set once the step finishes.
    var isDone = false
}

/// What the assistant reports while it answers.
enum AssistantUpdate: Equatable, Sendable {
    case session(String)
    case text(String)
    /// OMP starts a new assistant message: its first text replaces the text shown.
    case messageStarted
    case citation(DocumentCitation)
    /// A step starts; the step is shown in progress until it finishes.
    case stepStarted(AnswerStep)
    case stepFinished(UUID)
    /// A piece of the model's reasoning.
    case reasoning(String)
    case finished
    case failed(String)
    case stopped
}

/// The assistant behind the mini-chat. The production implementation talks to OMP;
/// tests use a fake behind this protocol.
protocol AssistantService: Sendable {
    /// Streams the answer. The stream ends after `.finished`, `.failed` or `.stopped`.
    func ask(_ request: AssistantRequest) -> AsyncStream<AssistantUpdate>

    /// Stops the answer in progress for the conversation; the text written so far is kept.
    func interrupt(conversationID: UUID) async
}
