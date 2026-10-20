import AxiScreen
import Foundation
import Testing
@testable import Axi

@Suite("Mini-chat state machine")
struct MiniChatMachineTests {
    private let fixedDate = Date(timeIntervalSince1970: 1_750_000_000)

    private func machine() -> MiniChatMachine {
        MiniChatMachine(now: { fixedDate })
    }

    /// Opens the chat, reads the screen and finishes preparing, so the chat is Pronta.
    private func readyMachine() -> MiniChatMachine {
        var machine = machine()
        _ = machine.handle(.openChat(ompReady: true))
        let session = machine.model.session
        _ = machine.handle(.screenRead(session: session, ScreenContext(
            appName: "Preview", bundleIdentifier: "com.apple.Preview", title: "Bolletta.pdf", text: "Totale 42 euro",
            moment: ZonedMoment(date: fixedDate.addingTimeInterval(-600), timeZone: TimeZone(identifier: "Europe/Rome")!))))
        return machine
    }

    @Test("A question carries the moment it was asked, and the screen keeps the moment it was read")
    func questionCarriesMoments() {
        var machine = readyMachine()
        let effects = machine.handle(.sendQuestion("Quanto costa?"))
        let asked = effects.compactMap { effect -> AssistantRequest? in
            if case .ask(let request) = effect { return request }
            return nil
        }
        #expect(asked.first?.asked.date == fixedDate)
        #expect(asked.first?.screen?.moment?.date == fixedDate.addingTimeInterval(-600))
        #expect(machine.model.conversation.messages[0].screenContext?.moment == asked.first?.screen?.moment)
    }

    @Test("Opening with OMP not ready stays closed and emits non-disponibile")
    func openingWithoutOMPStaysClosed() {
        var machine = machine()
        let effects = machine.handle(.openChat(ompReady: false))
        #expect(machine.model.state == .closed)
        #expect(effects == [.emit(.nonDisponibile)])
    }

    @Test("Opening with OMP ready goes to preparing and emits aperta")
    func openingWithOMPPrepares() {
        var machine = machine()
        let effects = machine.handle(.openChat(ompReady: true))
        #expect(machine.model.state == .preparing)
        #expect(effects.contains(.emit(.aperta)))
        #expect(effects.contains { if case .readScreen = $0 { true } else { false } })
        #expect(effects.contains { if case .loadLatestConversation = $0 { true } else { false } })
    }

    @Test("Screen read goes to ready with the context as a label")
    func screenReadBecomesReady() {
        var machine = machine()
        _ = machine.handle(.openChat(ompReady: true))
        let session = machine.model.session
        let context = ScreenContext(appName: "Mail", bundleIdentifier: nil, title: "Inbox", text: "Ciao")
        _ = machine.handle(.screenRead(session: session, context))
        #expect(machine.model.state == .ready)
        #expect(machine.model.screen == .context(context))
    }

    @Test("A failed screen read goes to ready and keeps the missing permission")
    func failedScreenReadBecomesReady() {
        var machine = machine()
        _ = machine.handle(.openChat(ompReady: true))
        _ = machine.handle(.screenReadFailed(session: machine.model.session, .permissionMissing([.screenRecording])))
        #expect(machine.model.state == .ready)
        #expect(machine.model.screen == .unreadable(.permissionMissing([.screenRecording])))
    }

    @Test("A failed recognition goes to ready and keeps its reason")
    func failedRecognitionKeepsReason() {
        var machine = machine()
        _ = machine.handle(.openChat(ompReady: true))
        _ = machine.handle(.screenReadFailed(session: machine.model.session, .recognitionFailed))
        #expect(machine.model.state == .ready)
        #expect(machine.model.screen == .unreadable(.recognitionFailed))
        #expect(machine.model.screen.context == nil)
    }

    @Test("A screen read failure with no reason keeps no reason")
    func failedScreenReadWithoutReason() {
        var machine = machine()
        _ = machine.handle(.openChat(ompReady: true))
        _ = machine.handle(.screenReadFailed(session: machine.model.session, nil))
        #expect(machine.model.state == .ready)
        #expect(machine.model.screen == .unreadable(nil))
    }

    @Test("A screen read from an earlier opening is ignored")
    func staleScreenReadIgnored() {
        var machine = machine()
        _ = machine.handle(.openChat(ompReady: true))
        _ = machine.handle(.screenRead(session: UUID(), ScreenContext(
            appName: "X", bundleIdentifier: nil, title: "", text: "")))
        #expect(machine.model.state == .preparing)
    }

    @Test("Removing the context clears the label")
    func removingContext() {
        var machine = readyMachine()
        _ = machine.handle(.removeContext)
        #expect(machine.model.screen == .none)
    }

    @Test("An empty question is not sent")
    func emptyQuestionIgnored() {
        var machine = readyMachine()
        let effects = machine.handle(.sendQuestion("   "))
        #expect(effects.isEmpty)
        #expect(machine.model.state == .ready)
    }

    @Test("A question goes to answering, sets the title and asks the assistant with the context")
    func questionStartsAnswer() {
        var machine = readyMachine()
        let effects = machine.handle(.sendQuestion("  Quanto  costa\nla bolletta? "))
        #expect(machine.model.state == .answering)
        #expect(machine.model.conversation.title == "Quanto costa la bolletta?")
        #expect(machine.model.conversation.messages.count == 1)
        #expect(machine.model.conversation.messages[0].screenContext?.title == "Bolletta.pdf")
        let asked = effects.compactMap { effect -> AssistantRequest? in
            if case .ask(let request) = effect { return request }
            return nil
        }
        #expect(asked.first?.question == "Quanto  costa\nla bolletta?")
        #expect(asked.first?.screen?.title == "Bolletta.pdf")
    }

    @Test("The title is the first question, shortened to 60 characters")
    func titleIsShortened() {
        let long = String(repeating: "parola ", count: 20)
        let title = ConversationTitle.make(from: long)
        #expect(title.count == ConversationTitle.maxLength)
        #expect(title.hasSuffix("…"))
    }

    @Test("A finished answer is saved with its citations and returns to ready")
    func finishedAnswerIsSaved() {
        var machine = readyMachine()
        _ = machine.handle(.sendQuestion("Canone?"))
        let citation = DocumentCitation(documentID: "doc-contratto", title: "Contratto", page: 2)
        _ = machine.handle(.assistant(.session("sess-1")))
        _ = machine.handle(.assistant(.text("Il canone è ")))
        _ = machine.handle(.assistant(.text("850 euro.")))
        _ = machine.handle(.assistant(.citation(citation)))
        let effects = machine.handle(.assistant(.finished))

        #expect(machine.model.state == .ready)
        #expect(machine.model.pendingAnswer == nil)
        #expect(machine.model.conversation.ompSessionID == "sess-1")
        let axi = machine.model.conversation.messages.last
        #expect(axi?.author == .axi)
        #expect(axi?.text == "Il canone è 850 euro.")
        #expect(axi?.citations == [citation])
        #expect(effects.contains { if case .saveConversation = $0 { true } else { false } })
    }

    @Test("A new OMP message replaces the answer text, and the saved answer is only the last one")
    func newMessageReplacesAnswer() {
        var machine = readyMachine()
        _ = machine.handle(.sendQuestion("Canone?"))
        let citation = DocumentCitation(documentID: "doc-contratto", title: "Contratto", page: 2)
        _ = machine.handle(.assistant(.text("Cerco nel vault.")))
        _ = machine.handle(.assistant(.messageStarted))
        _ = machine.handle(.assistant(.citation(citation)))
        _ = machine.handle(.assistant(.messageStarted))
        _ = machine.handle(.assistant(.text("Il canone è ")))
        #expect(machine.model.pendingAnswer?.text == "Il canone è ")
        _ = machine.handle(.assistant(.text("850 euro.")))
        _ = machine.handle(.assistant(.finished))

        let axi = machine.model.conversation.messages.last
        #expect(axi?.text == "Il canone è 850 euro.")
        #expect(axi?.citations == [citation])
        #expect(machine.model.conversation.messages.filter { $0.author == .axi }.count == 1)
    }

    @Test("A new OMP message without text keeps the answer text")
    func toolOnlyMessageKeepsAnswer() {
        var machine = readyMachine()
        _ = machine.handle(.sendQuestion("Canone?"))
        _ = machine.handle(.assistant(.text("Il canone è 850 euro.")))
        _ = machine.handle(.assistant(.messageStarted))
        #expect(machine.model.pendingAnswer?.text == "Il canone è 850 euro.")
        _ = machine.handle(.assistant(.finished))

        #expect(machine.model.conversation.messages.last?.text == "Il canone è 850 euro.")
    }

    @Test("A failed answer becomes a message in the conversation, and retry re-asks the question")
    func failedAnswerOffersRetry() {
        var machine = readyMachine()
        _ = machine.handle(.sendQuestion("Canone?"))
        let failed = machine.handle(.assistant(.failed("rete")))
        #expect(machine.model.state == .ready)
        #expect(machine.model.conversation.messages.last?.failure == .answerFailed("rete"))
        #expect(machine.model.canRetry)
        #expect(failed.contains { if case .saveConversation = $0 { true } else { false } })

        let effects = machine.handle(.retryAnswer)
        #expect(machine.model.state == .answering)
        #expect(effects.contains { if case .ask(let r) = $0 { r.question == "Canone?" } else { false } })
        #expect(machine.model.conversation.messages.count == 1)
    }

    @Test("Interrupting keeps the text already written")
    func interruptKeepsText() {
        var machine = readyMachine()
        _ = machine.handle(.sendQuestion("Canone?"))
        _ = machine.handle(.assistant(.text("Il canone")))
        let effects = machine.handle(.interruptAnswer)
        #expect(effects.contains(.interruptAnswer))
        #expect(machine.model.state == .ready)
        #expect(machine.model.conversation.messages.last?.text == "Il canone")
    }

    @Test("Closing during an answer interrupts it, keeps the text and emits chiusa")
    func closingDuringAnswer() {
        var machine = readyMachine()
        _ = machine.handle(.sendQuestion("Canone?"))
        _ = machine.handle(.assistant(.text("Parziale")))
        let effects = machine.handle(.closeChat)
        #expect(machine.model.state == .closed)
        #expect(effects.contains(.interruptAnswer))
        #expect(effects.contains(.emit(.chiusa)))
        let saved = effects.compactMap { effect -> Conversation? in
            if case .saveConversation(let conversation) = effect { return conversation }
            return nil
        }.last
        #expect(saved?.messages.last?.text == "Parziale")
    }

    @Test("A deletion request waits for confirmation and the answer resumes")
    func deletionWaitsForConfirmation() {
        var machine = readyMachine()
        _ = machine.handle(.sendQuestion("Elimina il contratto"))
        let preview = DeletionPreview(documentID: "doc-contratto", title: "Contratto", kind: "contratto",
                                      archivedAt: fixedDate, attachments: ["Allegato"])
        _ = machine.handle(.deletionRequested(preview))
        #expect(machine.model.state == .confirmingDeletion)
        #expect(machine.model.pendingDeletion == preview)

        let effects = machine.handle(.confirmDeletion)
        #expect(effects == [.settleDeletion(documentID: "doc-contratto", confirmed: true)])
        #expect(machine.model.state == .answering)
        #expect(machine.model.pendingDeletion == nil)
    }

    @Test("Cancelling a deletion refuses it and resumes the answer")
    func cancellingDeletion() {
        var machine = readyMachine()
        _ = machine.handle(.sendQuestion("Elimina"))
        let preview = DeletionPreview(documentID: "d", title: "T", kind: "k", archivedAt: fixedDate, attachments: [])
        _ = machine.handle(.deletionRequested(preview))
        let effects = machine.handle(.cancelDeletion)
        #expect(effects == [.settleDeletion(documentID: "d", confirmed: false)])
        #expect(machine.model.state == .answering)
    }

    @Test("A deletion request outside an answer is refused at once")
    func deletionOutsideAnswerRefused() {
        var machine = readyMachine()
        let preview = DeletionPreview(documentID: "d", title: "T", kind: "k", archivedAt: fixedDate, attachments: [])
        let effects = machine.handle(.deletionRequested(preview))
        #expect(effects == [.settleDeletion(documentID: "d", confirmed: false)])
        #expect(machine.model.state == .ready)
    }

    @Test("Closing during the deletion card refuses the deletion")
    func closingDuringDeletionRefuses() {
        var machine = readyMachine()
        _ = machine.handle(.sendQuestion("Elimina"))
        let preview = DeletionPreview(documentID: "d", title: "T", kind: "k", archivedAt: fixedDate, attachments: [])
        _ = machine.handle(.deletionRequested(preview))
        let effects = machine.handle(.closeChat)
        #expect(effects.contains(.settleDeletion(documentID: "d", confirmed: false)))
        #expect(machine.model.state == .closed)
    }

    @Test("Reopening a conversation from the list loads it and its session")
    func reopeningConversation() {
        var machine = readyMachine()
        _ = machine.handle(.openConversationList)
        #expect(machine.model.state == .conversationList)

        let id = UUID()
        let effects = machine.handle(.reopenConversation(id))
        #expect(machine.model.state == .conversationList)
        let token = machine.model.loadToken
        #expect(token != nil)
        #expect(effects == [.loadConversation(id, token: token!)])

        var loaded = Conversation.empty(id: id, now: fixedDate)
        loaded.ompSessionID = "sess-9"
        _ = machine.handle(.conversationLoaded(token: token!, loaded))
        #expect(machine.model.state == .ready)
        #expect(machine.model.conversation.id == id)
        #expect(machine.model.conversation.ompSessionID == "sess-9")
    }

    @Test("A conversation that cannot be read is not opened empty and is not overwritten")
    func unreadableConversationStaysInList() {
        var machine = readyMachine()
        _ = machine.handle(.openConversationList)

        let id = UUID()
        _ = machine.handle(.reopenConversation(id))
        let token = machine.model.loadToken

        _ = machine.handle(.conversationLoadFailed(token: token!))
        #expect(machine.model.state == .conversationList)
        #expect(machine.model.unreadableConversation == id)
        #expect(machine.model.conversation.id != id)
        #expect(machine.model.loadToken == nil)

        // Nothing can be sent from the list, so nothing is saved over the stored conversation.
        let effects = machine.handle(.sendQuestion("Nuova"))
        #expect(effects.isEmpty)
    }

    @Test("Choosing another conversation clears the notice")
    func noticeClearedOnReopen() {
        var machine = readyMachine()
        _ = machine.handle(.openConversationList)
        _ = machine.handle(.reopenConversation(UUID()))
        _ = machine.handle(.conversationLoadFailed(token: machine.model.loadToken!))

        _ = machine.handle(.reopenConversation(UUID()))
        #expect(machine.model.unreadableConversation == nil)
    }

    @Test("A latest conversation that cannot be read at open shows the list with the notice, never an empty chat")
    func unreadableLatestAtOpenShowsNotice() {
        var machine = MiniChatMachine(now: { fixedDate })
        _ = machine.handle(.openChat(ompReady: true))
        let token = machine.model.loadToken

        _ = machine.handle(.conversationLoadFailed(token: token!))
        #expect(machine.model.state == .conversationList)
        #expect(machine.model.unreadableConversation != nil)
        #expect(machine.model.loadToken == nil)

        // The list cannot send, so the stored conversation is never saved over.
        #expect(machine.handle(.sendQuestion("Nuova")).isEmpty)
    }

    @Test("A late conversation load for an older token is ignored")
    func staleLoadIgnored() {
        var machine = readyMachine()
        _ = machine.handle(.openConversationList)
        _ = machine.handle(.reopenConversation(UUID()))
        let other = Conversation.empty(now: fixedDate)
        _ = machine.handle(.conversationLoaded(token: UUID(), other))
        #expect(machine.model.conversation.id != other.id)
    }

    @Test("New conversation starts an empty one")
    func newConversation() {
        var machine = readyMachine()
        _ = machine.handle(.sendQuestion("Primo"))
        _ = machine.handle(.assistant(.finished))
        _ = machine.handle(.newConversation)
        #expect(machine.model.conversation.messages.isEmpty)
        #expect(machine.model.conversation.title.isEmpty)
    }

    @Test("A leftover file notice shows until the next question")
    func leftoverNoticeClearedByQuestion() {
        var machine = readyMachine()
        _ = machine.handle(.deletionLeftFile)
        #expect(machine.model.leftoverFile == true)
        _ = machine.handle(.sendQuestion("Altra domanda"))
        #expect(machine.model.leftoverFile == false)
    }

    @Test("Opening a cited document works in ready and while answering, without changing state")
    func openingDocumentKeepsState() {
        var machine = readyMachine()
        let citation = DocumentCitation(documentID: "d", title: "T", page: 3)
        #expect(machine.handle(.openCitedDocument(citation)) == [.openDocument(citation)])
        #expect(machine.model.state == .ready)

        _ = machine.handle(.sendQuestion("Domanda"))
        #expect(machine.handle(.openCitedDocument(citation)) == [.openDocument(citation)])
        #expect(machine.model.state == .answering)
    }

    @Test("Chiusa ignores everything except opening the chat")
    func closedIgnoresOtherInputs() {
        var machine = machine()
        #expect(machine.handle(.sendQuestion("ciao")).isEmpty)
        #expect(machine.model.state == .closed)
    }
}
