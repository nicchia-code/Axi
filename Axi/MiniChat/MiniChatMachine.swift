import Foundation
import AxiScreen

/// Events the mini-chat emits to the rest of the app.
enum MiniChatEvent: String, Equatable, Sendable {
    case aperta = "mini-chat.APERTA"
    case chiusa = "mini-chat.CHIUSA"
    case nonDisponibile = "mini-chat.NON_DISPONIBILE"
}

enum ChatError: Codable, Equatable, Sendable {
    case answerFailed(String)
    case ompStopped
}

/// The answer being written: streamed text, the documents cited so far, the steps and the reasoning.
struct PendingAnswer: Equatable, Sendable {
    var text: String = ""
    var citations: [DocumentCitation] = []
    /// Set when OMP starts a new message: its first text replaces the text shown instead of adding to it.
    var nextTextReplaces = false
    var steps: [AnswerStep] = []
    var reasoning = ""
}

/// The steps and reasoning of a finished answer, shown collapsed under the answer. Never saved.
struct AnswerSummary: Equatable, Sendable {
    /// The answer message the summary belongs to.
    var messageID: UUID
    var steps: [AnswerStep]
    var reasoning: String
}

/// Everything the chat window shows, plus the state of the machine.
struct MiniChatModel: Equatable, Sendable {
    enum State: Equatable, Sendable {
        case closed
        case preparing
        case ready
        case answering
        case confirmingDeletion
        case conversationList
    }

    enum ScreenStatus: Equatable, Sendable {
        case none
        case context(ScreenContext)
        /// The screen could not be read. The reason is the failure of the reading; nil when the reading did not start or failed for no permission.
        case unreadable(ReadingFailure?)

        var context: ScreenContext? {
            if case .context(let context) = self { return context }
            return nil
        }
    }

    var state: State
    var conversation: Conversation
    var screen: ScreenStatus
    var pendingAnswer: PendingAnswer?
    var pendingDeletion: DeletionPreview?
    /// Identifies the opening of the chat; late screen reads from another opening are ignored.
    var session: UUID
    /// Identifies the conversation load still expected; late loads are ignored.
    var loadToken: UUID?
    /// Set while the notice of an unreadable stored conversation shows in the list. For a latest conversation that
    /// could not be read, the id is the placeholder empty conversation that replaces it, since the stored id is unknown.
    var unreadableConversation: UUID? = nil
    /// Set when a deleted document left its file on disk until the next launch; the next question clears it.
    var leftoverFile = false
    /// The summary of the answer just finished, under its message; nil once the conversation changes or a question is sent.
    var answerSummary: AnswerSummary?

    static func closed(now: Date) -> MiniChatModel {
        MiniChatModel(
            state: .closed,
            conversation: .empty(now: now),
            screen: .none,
            pendingAnswer: nil,
            pendingDeletion: nil,
            session: UUID(),
            loadToken: nil,
            unreadableConversation: nil
        )
    }

    /// Riprova is offered when the answer failed right after its question, with no partial answer.
    var canRetry: Bool {
        guard state == .ready, conversation.messages.count >= 2,
              let last = conversation.messages.last, last.failure != nil else { return false }
        return conversation.messages[conversation.messages.count - 2].author == .user
    }
}

/// Inputs of the mini-chat: the user's actions, the screen reading, the assistant's updates.
enum MiniChatInput: Equatable, Sendable {
    // User
    case openChat(ompReady: Bool)
    case closeChat
    case sendQuestion(String)
    case removeContext
    case newConversation
    case openConversationList
    case openCitedDocument(DocumentCitation)
    case retryAnswer
    case interruptAnswer
    case confirmDeletion
    case cancelDeletion
    case reopenConversation(UUID)
    case deleteConversation(UUID)
    case closeConversationList

    // Screen reading
    case screenRead(session: UUID, ScreenContext)
    case screenReadFailed(session: UUID, ReadingFailure?)

    // Storage
    case conversationLoaded(token: UUID, Conversation)
    case conversationLoadFailed(token: UUID)

    // Assistant
    case assistant(AssistantUpdate)
    case deletionRequested(DeletionPreview)
    /// A deleted document left its file on disk until the next launch.
    case deletionLeftFile
}

/// Work the machine asks the environment to do.
enum MiniChatEffect: Equatable, Sendable {
    case emit(MiniChatEvent)
    case readScreen(session: UUID)
    case loadLatestConversation(token: UUID)
    case loadConversation(UUID, token: UUID)
    case refreshConversationList
    case ask(AssistantRequest)
    case interruptAnswer
    case saveConversation(Conversation)
    case openDocument(DocumentCitation)
    case settleDeletion(documentID: String, confirmed: Bool)
    case deleteConversation(UUID)
}

/// The mini-chat state machine, as the Model describes it. Inputs that the Model
/// does not allow in the current state change nothing and return no effects.
struct MiniChatMachine: Sendable {
    private(set) var model: MiniChatModel
    private let now: @Sendable () -> Date

    init(now: @escaping @Sendable () -> Date = { Date() }) {
        self.now = now
        self.model = .closed(now: now())
    }

    mutating func handle(_ input: MiniChatInput) -> [MiniChatEffect] {
        switch (model.state, input) {

        // Chiusa
        case (.closed, .openChat(let ompReady)):
            guard ompReady else { return [.emit(.nonDisponibile)] }
            return openChat()
        case (.closed, _):
            return []

        // Aperta: inherited by every state of the chat
        case (_, .closeChat):
            return closeChat()

        case (_, .deletionLeftFile):
            model.leftoverFile = true
            return []

        // In preparazione
        case (.preparing, .screenRead(let session, let context)) where session == model.session:
            model.screen = .context(context)
            model.state = .ready
            return []
        case (.preparing, .screenReadFailed(let session, let failure)) where session == model.session:
            model.screen = .unreadable(failure)
            model.state = .ready
            return []

        // Conversation loads
        case (_, .conversationLoaded(let token, let conversation)) where token == model.loadToken:
            model.conversation = conversation
            model.loadToken = nil
            if model.state == .conversationList { model.state = .ready }
            return []
        case (_, .conversationLoadFailed(let token)) where token == model.loadToken && (model.state == .preparing || model.state == .conversationList):
            // The stored conversation is never shown as empty nor saved over: the list stays with a notice.
            model.state = .conversationList
            model.unreadableConversation = model.conversation.id
            model.conversation = .empty(now: now())
            model.loadToken = nil
            return []

        // The screen read may finish while the list is shown after a failed load
        case (.conversationList, .screenRead(let session, let context)) where session == model.session:
            model.screen = .context(context)
            return []
        case (.conversationList, .screenReadFailed(let session, let failure)) where session == model.session:
            model.screen = .unreadable(failure)
            return []

        // Pronta
        case (.ready, .sendQuestion(let text)):
            model.leftoverFile = false
            return sendQuestion(text)
        case (.ready, .retryAnswer):
            return retryAnswer()
        case (.ready, .removeContext):
            model.screen = .none
            return []
        case (.ready, .newConversation):
            model.conversation = .empty(now: now())
            model.loadToken = nil
            return []
        case (.ready, .openConversationList):
            model.state = .conversationList
            return [.refreshConversationList]

        // Pronta and In risposta: the document opens without interrupting the answer
        case (.ready, .openCitedDocument(let citation)), (.answering, .openCitedDocument(let citation)):
            return [.openDocument(citation)]

        // In risposta
        case (.answering, .interruptAnswer):
            return [.interruptAnswer] + finishAnswer(error: nil)
        case (.answering, .deletionRequested(let preview)):
            model.state = .confirmingDeletion
            model.pendingDeletion = preview
            return []
        case (.answering, .assistant(let update)), (.confirmingDeletion, .assistant(let update)):
            return answer(update)

        // Conferma dell'eliminazione
        case (.confirmingDeletion, .confirmDeletion):
            return settleDeletion(confirmed: true)
        case (.confirmingDeletion, .cancelDeletion):
            return settleDeletion(confirmed: false)

        // Elenco delle conversazioni
        case (.conversationList, .reopenConversation(let id)):
            // The list stays on screen until the conversation is read; a failed read goes back to it with a notice.
            let token = UUID()
            model.conversation = .empty(id: id, now: now())
            model.pendingAnswer = nil
            model.loadToken = token
            model.unreadableConversation = nil
            return [.loadConversation(id, token: token)]
        case (.conversationList, .deleteConversation(let id)):
            if model.conversation.id == id {
                model.conversation = .empty(now: now())
                model.loadToken = nil
            }
            return [.deleteConversation(id)]
        case (.conversationList, .closeConversationList):
            model.state = .ready
            model.unreadableConversation = nil
            return []

        default:
            // A deletion request outside an answer must not wait forever for a confirmation
            // that cannot come: it is refused at once.
            if case .deletionRequested(let preview) = input {
                return [.settleDeletion(documentID: preview.documentID, confirmed: false)]
            }
            return []
        }
    }

    // MARK: - Transitions

    private mutating func openChat() -> [MiniChatEffect] {
        let session = UUID()
        let token = UUID()
        model = MiniChatModel(
            state: .preparing,
            conversation: .empty(now: now()),
            screen: .none,
            pendingAnswer: nil,
            pendingDeletion: nil,
            session: session,
            loadToken: token
        )
        return [.emit(.aperta), .readScreen(session: session), .loadLatestConversation(token: token)]
    }

    private mutating func closeChat() -> [MiniChatEffect] {
        var effects: [MiniChatEffect] = []
        if model.state == .answering || model.state == .confirmingDeletion {
            effects.append(.interruptAnswer)
            effects += finishAnswer(error: nil)
        }
        effects.append(.emit(.chiusa))
        model = .closed(now: now())
        return effects
    }

    /// Riprova: asks again the question that got no answer. Offered only when the failure
    /// is the last message, right after that question, so no partial answer is repeated.
    private mutating func retryAnswer() -> [MiniChatEffect] {
        guard model.canRetry else { return [] }
        let question = model.conversation.messages[model.conversation.messages.count - 2]
        model.conversation.messages.removeLast()
        model.pendingAnswer = PendingAnswer()
        model.answerSummary = nil
        model.state = .answering
        let request = AssistantRequest(
            conversationID: model.conversation.id,
            sessionID: model.conversation.ompSessionID,
            question: question.text,
            asked: ZonedMoment(date: now(), timeZone: .current),
            screen: question.screenContext
        )
        return [.ask(request)]
    }

    private mutating func sendQuestion(_ text: String) -> [MiniChatEffect] {
        let question = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // The send button is disabled for an empty question; nothing is sent.
        guard !question.isEmpty else { return [] }

        let screen = model.screen.context
        let asked = ZonedMoment(date: now(), timeZone: .current)
        model.conversation.messages.append(ChatMessage(
            id: UUID(),
            author: .user,
            text: question,
            date: asked.date,
            screenContext: screen,
            citations: []
        ))
        if model.conversation.title.isEmpty {
            model.conversation.title = ConversationTitle.make(from: question)
        }
        model.loadToken = nil
        model.pendingAnswer = PendingAnswer()
        model.answerSummary = nil
        model.state = .answering

        let request = AssistantRequest(
            conversationID: model.conversation.id,
            sessionID: model.conversation.ompSessionID,
            question: question,
            asked: asked,
            screen: screen
        )
        return [.saveConversation(model.conversation), .ask(request)]
    }

    /// Applies one update of the assistant to the answer being written.
    private mutating func answer(_ update: AssistantUpdate) -> [MiniChatEffect] {
        switch update {
        case .session(let id):
            model.conversation.ompSessionID = id
            return []
        case .text(let delta):
            if model.pendingAnswer == nil { model.pendingAnswer = PendingAnswer() }
            if model.pendingAnswer?.nextTextReplaces == true {
                model.pendingAnswer?.text = delta
                model.pendingAnswer?.nextTextReplaces = false
            } else {
                model.pendingAnswer?.text += delta
            }
            return []
        case .messageStarted:
            if model.pendingAnswer == nil { model.pendingAnswer = PendingAnswer() }
            model.pendingAnswer?.nextTextReplaces = true
            return []
        case .citation(let citation):
            if model.pendingAnswer == nil { model.pendingAnswer = PendingAnswer() }
            if model.pendingAnswer?.citations.contains(citation) == false {
                model.pendingAnswer?.citations.append(citation)
            }
            return []
        case .stepStarted(let step):
            if model.pendingAnswer == nil { model.pendingAnswer = PendingAnswer() }
            model.pendingAnswer?.steps.append(step)
            return []
        case .stepFinished(let id):
            if let index = model.pendingAnswer?.steps.firstIndex(where: { $0.id == id }) {
                model.pendingAnswer?.steps[index].isDone = true
            }
            return []
        case .reasoning(let delta):
            if model.pendingAnswer == nil { model.pendingAnswer = PendingAnswer() }
            model.pendingAnswer?.reasoning += delta
            return []
        case .finished:
            return finishAnswer(error: nil)
        case .failed(let message):
            return finishAnswer(error: .answerFailed(message))
        case .stopped:
            return finishAnswer(error: .ompStopped)
        }
    }

    /// Ends the answer: the text written so far stays in the conversation, which is saved.
    /// A deletion still waiting for confirmation is refused, so the tool call never hangs.
    private mutating func finishAnswer(error: ChatError?) -> [MiniChatEffect] {
        var effects: [MiniChatEffect] = []
        if let preview = model.pendingDeletion {
            effects.append(.settleDeletion(documentID: preview.documentID, confirmed: false))
        }
        var lastMessage: UUID?
        if let pending = model.pendingAnswer, !pending.text.isEmpty || !pending.citations.isEmpty {
            let message = ChatMessage(
                id: UUID(),
                author: .axi,
                text: pending.text,
                date: now(),
                screenContext: nil,
                citations: pending.citations
            )
            model.conversation.messages.append(message)
            lastMessage = message.id
        }
        if let error {
            let message = ChatMessage(
                id: UUID(),
                author: .axi,
                text: "",
                date: now(),
                screenContext: nil,
                citations: [],
                failure: error
            )
            model.conversation.messages.append(message)
            lastMessage = message.id
        }
        if let pending = model.pendingAnswer, !pending.steps.isEmpty || !pending.reasoning.isEmpty, let lastMessage {
            model.answerSummary = AnswerSummary(messageID: lastMessage, steps: pending.steps, reasoning: pending.reasoning)
        }
        model.pendingAnswer = nil
        model.pendingDeletion = nil
        model.state = .ready
        effects.append(.saveConversation(model.conversation))
        return effects
    }

    private mutating func settleDeletion(confirmed: Bool) -> [MiniChatEffect] {
        guard let preview = model.pendingDeletion else { return [] }
        model.pendingDeletion = nil
        model.state = .answering
        return [.settleDeletion(documentID: preview.documentID, confirmed: confirmed)]
    }
}
