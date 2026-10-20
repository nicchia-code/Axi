import AxiCore
import AxiOMP
import Foundation

/// One chat session of the OMP process, as the mini-chat uses it.
protocol OMPChatSession: Sendable {
    func contextWindowTokens() async throws -> Int?
    func prompt(_ message: String, sessionDirectory: URL?, onTextDelta: @escaping @Sendable (String) -> Void, onMessageStart: @escaping @Sendable () -> Void, onActivity: @escaping @Sendable (OMPActivity) -> Void) async throws -> String
    func abort() async
}

/// Gives the mini-chat its OMP chat session and the directory where each conversation's OMP session lives.
protocol OMPChatSessionProviding: Sendable {
    func chatSession() async throws -> any OMPChatSession
    func ompSessionDirectory(forConversation conversation: String) async throws -> URL
}

extension OMPClient: OMPChatSession {}

extension OMPConnection: OMPChatSessionProviding {
    func chatSession() async throws -> any OMPChatSession {
        try chat()
    }

    func ompSessionDirectory(forConversation conversation: String) async throws -> URL {
        try sessionDirectory(forConversation: conversation)
    }
}

/// The answer being written right now: which conversation it belongs to, the OMP session that writes it,
/// the model's context window, and where the citations it gathers go.
actor OMPChatTurn {
    private var conversationID: UUID?
    private var session: (any OMPChatSession)?
    private var contextWindowTokens: Int?
    private var onCitation: (@Sendable (DocumentCitation) -> Void)?
    private var waiting: [CheckedContinuation<Void, Never>] = []

    /// Starts a turn. When an earlier turn is still running (an interrupted answer that OMP has not released yet),
    /// waits for it to end: OMP runs one turn at a time.
    func begin(
        conversationID: UUID,
        session: any OMPChatSession,
        contextWindowTokens: Int?,
        onCitation: @escaping @Sendable (DocumentCitation) -> Void
    ) async {
        while self.conversationID != nil {
            await withCheckedContinuation { waiting.append($0) }
        }
        self.conversationID = conversationID
        self.session = session
        self.contextWindowTokens = contextWindowTokens
        self.onCitation = onCitation
    }

    func end() {
        conversationID = nil
        session = nil
        contextWindowTokens = nil
        onCitation = nil
        if !waiting.isEmpty {
            waiting.removeFirst().resume()
        }
    }

    /// The whole-document rule for the running turn, or nil when the context window is unknown.
    func contextPolicy() -> ContextPolicy? {
        contextWindowTokens.map { ContextPolicy(contextWindowTokens: $0) }
    }

    func cite(_ citation: DocumentCitation) {
        onCitation?(citation)
    }

    /// Aborts OMP's turn, if the running turn belongs to the conversation.
    func abort(conversationID: UUID) async {
        guard self.conversationID == conversationID, let session else { return }
        await session.abort()
    }
}

/// The mini-chat's assistant, answered by OMP.
struct OMPAssistantService: AssistantService {
    let provider: any OMPChatSessionProviding
    let turn: OMPChatTurn
    /// Looks up the titles of the documents the steps name.
    let documents: any VaultDocuments

    func ask(_ request: AssistantRequest) -> AsyncStream<AssistantUpdate> {
        let (stream, continuation) = AsyncStream.makeStream(of: AssistantUpdate.self)
        let task = Task {
            await answer(request, into: continuation)
            continuation.finish()
        }
        continuation.onTermination = { _ in task.cancel() }
        return stream
    }

    func interrupt(conversationID: UUID) async {
        await turn.abort(conversationID: conversationID)
    }

    private func answer(_ request: AssistantRequest, into continuation: AsyncStream<AssistantUpdate>.Continuation) async {
        let sessionName = request.sessionID ?? request.conversationID.uuidString
        do {
            let chat = try await provider.chatSession()
            let directory = try await provider.ompSessionDirectory(forConversation: sessionName)
            let contextWindow = try? await chat.contextWindowTokens()
            await turn.begin(
                conversationID: request.conversationID,
                session: chat,
                contextWindowTokens: contextWindow,
                onCitation: { continuation.yield(.citation($0)) }
            )
            continuation.yield(.session(sessionName))
            let (activities, activityInput) = AsyncStream.makeStream(of: OMPActivity.self)
            let reporter = Task { await report(activities, into: continuation) }
            var promptError: Error?
            do {
                _ = try await chat.prompt(
                    Self.message(for: request),
                    sessionDirectory: directory,
                    onTextDelta: { continuation.yield(.text($0)) },
                    onMessageStart: { continuation.yield(.messageStarted) },
                    onActivity: { activityInput.yield($0) }
                )
            } catch {
                promptError = error
            }
            activityInput.finish()
            await reporter.value
            await turn.end()
            if let promptError { throw promptError }
            continuation.yield(.finished)
        } catch OMPError.aborted, OMPError.processExited {
            continuation.yield(.stopped)
        } catch let error as OMPError {
            continuation.yield(.failed(error.errorDescription ?? "OMP non è riuscito a rispondere."))
        } catch {
            continuation.yield(.failed("OMP non è riuscito a rispondere."))
        }
    }

    /// Turns OMP's activity into steps and reasoning, in the order OMP reports them.
    private func report(_ activities: AsyncStream<OMPActivity>, into continuation: AsyncStream<AssistantUpdate>.Continuation) async {
        var toolSteps: [String: UUID] = [:]
        var retryStep: UUID?
        var summaryStep: UUID?
        for await activity in activities {
            switch activity {
            case .thinking(let delta):
                continuation.yield(.reasoning(delta))
            case .retryStarted(let attempt, let maximum):
                let step = AnswerStep(id: UUID(), kind: .retry(attempt: attempt, maxAttempts: maximum))
                retryStep = step.id
                continuation.yield(.stepStarted(step))
            case .retryEnded:
                if let id = retryStep {
                    retryStep = nil
                    continuation.yield(.stepFinished(id))
                }
            case .compactionStarted:
                let step = AnswerStep(id: UUID(), kind: .summarize)
                summaryStep = step.id
                continuation.yield(.stepStarted(step))
            case .compactionEnded:
                if let id = summaryStep {
                    summaryStep = nil
                    continuation.yield(.stepFinished(id))
                }
            case .toolStarted(let callID, let name, let arguments):
                guard let kind = await Self.kind(ofTool: name, arguments: arguments, documents: documents) else { continue }
                let step = AnswerStep(id: UUID(), kind: kind)
                toolSteps[callID] = step.id
                continuation.yield(.stepStarted(step))
            case .toolFinished(let callID):
                if let id = toolSteps.removeValue(forKey: callID) {
                    continuation.yield(.stepFinished(id))
                }
            }
        }
    }

    /// The step a host tool call makes, or nil for a call that makes none.
    static func kind(ofTool name: String, arguments: JSONValue, documents: any VaultDocuments) async -> AnswerStep.Kind? {
        func title() async -> String {
            let id = arguments["documentID"]?.string ?? ""
            return (try? await documents.title(documentID: id)) ?? ""
        }
        switch name {
        case "search_vault":
            return .searchVault(words: arguments["query"]?.string ?? "")
        case "read_document_page":
            return .readPage(page: arguments["page"]?.int ?? 1, title: await title())
        case "cite_documents":
            return .cite(count: arguments["citations"]?.array?.count ?? 0)
        case "set_document_tags":
            return .changeTags(title: await title())
        case "request_document_deletion":
            return .askDeletion(title: await title())
        default:
            return nil
        }
    }

    /// The text OMP receives: the current date and time, the rules for answering, the screen the user shared, then the question.
    static func message(for request: AssistantRequest) -> String {
        var parts = ["Current date and time on the user's Mac: \(describe(request.asked))."]
        parts.append(instructions)
        if let screen = request.screen {
            let title = screen.title.isEmpty ? "" : ", \(screen.title)"
            let read = screen.moment.map { ", read on \(describe($0))" } ?? ""
            parts.append("What is on the user's screen (\(screen.appName)\(title))\(read):\n\(screen.text)")
        }
        parts.append("Question: \(request.question)")
        return parts.joined(separator: "\n\n")
    }

    /// A moment as the model reads it: the local date and time, the offset from UTC and the time zone.
    static func describe(_ moment: ZonedMoment) -> String {
        let zone = moment.timeZone
        let date = DateFormatter()
        date.locale = Locale(identifier: "en_US_POSIX")
        date.timeZone = zone
        date.dateFormat = "EEEE d MMMM yyyy, HH:mm"
        let offset = DateFormatter()
        offset.locale = Locale(identifier: "en_US_POSIX")
        offset.timeZone = zone
        offset.dateFormat = "xxx"
        return "\(date.string(from: moment.date)) (UTC\(offset.string(from: moment.date)), \(zone.identifier))"
    }

    static let instructions = """
        Answer from the user's document vault. Use the search_vault tool to find documents and the \
        read_document_page tool to read a page in full. Searching or reading does not cite anything: \
        before writing the answer, call the cite_documents tool with every document and page the answer \
        uses, and only those. Then write the answer and write nothing after it. If the vault has no sources \
        for the answer, say so in the answer without calling cite_documents. \
        Change or delete a document only when the user asks. \
        Dates and times: relative times in the text of the screen ("tomorrow", "2 hours ago") are relative \
        to the moment the screen was read. Relative times in a document are relative to the date the \
        document was received, or to its own date when it has none. In the answer, write a date that was \
        relative in the source as the absolute date followed by the relative one in parentheses, relative \
        to the current date and time, for example "Monday 20 October at 15:00 (tomorrow)".
        """
}
