import Foundation
import Testing
@testable import AxiOMP

struct OMPHostToolsTests {
    private func makeDispatcher(events: OMPEventHub = OMPEventHub()) -> OMPHostToolDispatcher {
        OMPHostToolDispatcher(chat: StubChatTools(), vault: StubVaultTools(), events: events)
    }

    @Test func definitionsCoverTheFiveHostTools() {
        let names = OMPHostToolDispatcher.definitions.compactMap { $0["name"]?.string }
        #expect(Set(names) == ["search_vault", "read_document_page", "cite_documents", "set_document_tags", "request_document_deletion"])
    }

    @Test func citeDocumentsRecordsTheDeclaredPages() async {
        let output = await makeDispatcher().handle(toolName: "cite_documents", arguments: .object([
            "citations": .array([
                .object(["documentID": .string("doc-1"), "page": .number(2)]),
                .object(["documentID": .string("doc-2")]),
            ]),
        ]))
        #expect(output == OMPHostToolDispatcher.Output(text: "Citations recorded.", isError: false))
    }

    @Test func citeDocumentsRejectsAPageBelowOne() async {
        let output = await makeDispatcher().handle(toolName: "cite_documents", arguments: .object([
            "citations": .array([.object(["documentID": .string("doc-1"), "page": .number(0)])]),
        ]))
        #expect(output == OMPHostToolDispatcher.Output(text: "Invalid arguments.", isError: true))
    }

    @Test func searchReturnsTheHitsAsJSON() async {
        let output = await makeDispatcher().handle(toolName: "search_vault", arguments: .object(["query": .string("fattura")]))
        #expect(output.isError == false)
        #expect(output.text.contains("doc-1"))
    }

    @Test func searchCarriesPageAndWholeTextWhenPresent() async {
        let dispatcher = OMPHostToolDispatcher(chat: PagedChatTools(), vault: StubVaultTools(), events: OMPEventHub())
        let output = await dispatcher.handle(toolName: "search_vault", arguments: .object(["query": .string("locazione")]))
        #expect(output.isError == false)
        #expect(output.text.contains("\"page\":3"))
        #expect(output.text.contains("\"wholeText\":\"Testo intero\""))
    }

    @Test func searchCarriesTheDatesOfTheHit() async {
        let dispatcher = OMPHostToolDispatcher(chat: DatedChatTools(), vault: StubVaultTools(), events: OMPEventHub())
        let output = await dispatcher.handle(toolName: "search_vault", arguments: .object(["query": .string("scadenza")]))
        #expect(output.isError == false)
        #expect(output.text.contains("\"documentDate\":\"2025-03-10\""))
        #expect(output.text.contains("\"receivedAt\":\"2025-10-09T"))
        #expect(output.text.contains("\"citedDates\":[{"))
        #expect(output.text.contains("\"date\":\"2025-03-20\""))
        #expect(output.text.contains("\"originalText\":\"entro il 20 marzo\""))
    }

    @Test func searchPassesItsFiltersToTheChat() async {
        let recorder = FilterRecorder()
        let dispatcher = OMPHostToolDispatcher(chat: FilteringChatTools(recorder: recorder), vault: StubVaultTools(), events: OMPEventHub())
        let output = await dispatcher.handle(toolName: "search_vault", arguments: .object([
            "query": .string("fattura"),
            "tags": .array([.string("casa")]),
            "kinds": .array([.string("pdf")]),
            "origins": .array([.string("Mail")]),
            "archivedFrom": .string("2025-03-01"),
            "archivedTo": .string("2025-03-31"),
        ]))
        #expect(output.isError == false)
        let filter = await recorder.filter
        #expect(filter?.tags == ["casa"])
        #expect(filter?.kinds == ["pdf"])
        #expect(filter?.origins == ["Mail"])
        #expect(filter?.archivedFrom.map { Calendar.current.component(.day, from: $0) } == 1)
        #expect(filter?.archivedTo.map { Calendar.current.component(.day, from: $0) } == 31)
    }

    @Test func searchPassesTheDocumentReceiptAndCitedDateFilters() async {
        let recorder = FilterRecorder()
        let dispatcher = OMPHostToolDispatcher(chat: FilteringChatTools(recorder: recorder), vault: StubVaultTools(), events: OMPEventHub())
        let output = await dispatcher.handle(toolName: "search_vault", arguments: .object([
            "query": .string("contratto"),
            "documentFrom": .string("2025-03-10"),
            "documentTo": .string("2025-03-11"),
            "receivedFrom": .string("2025-10-09"),
            "receivedTo": .string("2025-10-09"),
            "citedFrom": .string("2025-03-20"),
            "citedTo": .string("2025-03-20"),
        ]))
        #expect(output.isError == false)
        let filter = await recorder.filter
        #expect(filter?.documentFrom.map { Calendar.current.component(.day, from: $0) } == 10)
        #expect(filter?.documentTo.map { Calendar.current.component(.day, from: $0) } == 11)
        #expect(filter?.receivedFrom.map { Calendar.current.component(.month, from: $0) } == 10)
        #expect(filter?.receivedTo.map { Calendar.current.component(.day, from: $0) } == 9)
        #expect(filter?.citedFrom.map { Calendar.current.component(.day, from: $0) } == 20)
        #expect(filter?.citedTo.map { Calendar.current.component(.day, from: $0) } == 20)
    }

    @Test func searchWithoutFiltersPassesNone() async {
        let recorder = FilterRecorder()
        let dispatcher = OMPHostToolDispatcher(chat: FilteringChatTools(recorder: recorder), vault: StubVaultTools(), events: OMPEventHub())
        _ = await dispatcher.handle(toolName: "search_vault", arguments: .object(["query": .string("fattura"), "archivedTo": .null]))
        #expect(await recorder.filter == OMPSearchFilter())
    }

    @Test func malformedFilterIsAnInvalidArgument() async {
        let invalidDate = await makeDispatcher().handle(
            toolName: "search_vault",
            arguments: .object(["query": .string("fattura"), "archivedFrom": .string("ieri")])
        )
        #expect(invalidDate == OMPHostToolDispatcher.Output(text: "Invalid arguments.", isError: true))
        let invalidTag = await makeDispatcher().handle(
            toolName: "search_vault",
            arguments: .object(["query": .string("fattura"), "tags": .array([.number(1)])])
        )
        #expect(invalidTag == OMPHostToolDispatcher.Output(text: "Invalid arguments.", isError: true))
    }

    @Test func searchDefinitionOffersTheFilters() {
        let search = OMPHostToolDispatcher.definitions.first { $0["name"]?.string == "search_vault" }
        let properties = search?["parameters"]?["properties"]
        for key in [
            "tags", "kinds", "origins", "archivedFrom", "archivedTo",
            "documentFrom", "documentTo", "receivedFrom", "receivedTo", "citedFrom", "citedTo",
        ] {
            #expect(properties?[key] != nil)
        }
    }

    /// Returns one hit that has a page and a whole text.
    private struct PagedChatTools: OMPChatHostTools {
        func searchVault(query: String, limit: Int, filter: OMPSearchFilter) async throws -> [OMPSearchHit] {
            [OMPSearchHit(documentID: "doc-2", title: "Contratto", page: 3, excerpt: query, wholeText: "Testo intero",
                          archivedAt: Date(timeIntervalSince1970: 0))]
        }

        func readDocumentPage(documentID: String, page: Int) async throws -> OMPDocumentPage {
            throw OMPError.invalidFrame
        }

        func citeDocuments(_ citations: [OMPCitation]) async throws {}
    }

    /// Returns one hit that carries its document, receipt and cited dates.
    private struct DatedChatTools: OMPChatHostTools {
        func searchVault(query: String, limit: Int, filter: OMPSearchFilter) async throws -> [OMPSearchHit] {
            let receivedAt = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 9, hour: 12)) ?? .distantPast
            return [OMPSearchHit(
                documentID: "doc-3", title: "Offerta", excerpt: query, archivedAt: Date(timeIntervalSince1970: 0),
                documentDate: .day(Date(timeIntervalSince1970: 1_741_564_800)),
                receivedAt: .instant(receivedAt),
                citedDates: [OMPCitedDate(
                    date: .day(Date(timeIntervalSince1970: 1_742_428_800)), about: "scadenza", originalText: "entro il 20 marzo"
                )]
            )]
        }

        func readDocumentPage(documentID: String, page: Int) async throws -> OMPDocumentPage {
            throw OMPError.invalidFrame
        }

        func citeDocuments(_ citations: [OMPCitation]) async throws {}
    }

    @Test func missingQueryIsAnInvalidArgument() async {
        let output = await makeDispatcher().handle(toolName: "search_vault", arguments: .object([:]))
        #expect(output == OMPHostToolDispatcher.Output(text: "Invalid arguments.", isError: true))
    }

    @Test func unknownToolIsAnError() async {
        let output = await makeDispatcher().handle(toolName: "run_shell", arguments: .object([:]))
        #expect(output.isError == true)
    }

    @Test func tagChangesArePublished() async {
        let events = OMPEventHub()
        var iterator = events.events().makeAsyncIterator()
        let output = await makeDispatcher(events: events).handle(
            toolName: "set_document_tags",
            arguments: .object(["documentID": .string("doc-1"), "tags": .array([.string("fisco")])])
        )
        #expect(output.isError == false)
        let event = await iterator.next()
        #expect(event == .tagsChanged(documentID: "doc-1", tags: ["fisco"]))
    }

    @Test func deletionAnswersWithTheUserDecision() async {
        let events = OMPEventHub()
        var iterator = events.events().makeAsyncIterator()
        let confirmed = await OMPHostToolDispatcher(chat: StubChatTools(), vault: DecidingVaultTools(deleted: true), events: events)
            .handle(toolName: "request_document_deletion", arguments: .object(["documentID": .string("doc-1")]))
        #expect(confirmed.isError == false)
        #expect(confirmed.text == "Document deleted.")
        let event = await iterator.next()
        #expect(event == .deletionRequested(documentID: "doc-1"))

        let declined = await OMPHostToolDispatcher(chat: StubChatTools(), vault: DecidingVaultTools(deleted: false), events: events)
            .handle(toolName: "request_document_deletion", arguments: .object(["documentID": .string("doc-1")]))
        #expect(declined.isError == false)
        #expect(declined.text == "Deletion declined by the user.")
    }
}

private struct DecidingVaultTools: OMPVaultHostTools {
    let deleted: Bool

    func setDocumentTags(documentID: String, tags: [String]) async throws {}

    func requestDocumentDeletion(documentID: String) async throws -> Bool { deleted }
}

private actor FilterRecorder {
    private(set) var filter: OMPSearchFilter?

    func record(_ filter: OMPSearchFilter) {
        self.filter = filter
    }
}

/// Records the filter of each search and returns no hits.
private struct FilteringChatTools: OMPChatHostTools {
    let recorder: FilterRecorder

    func searchVault(query: String, limit: Int, filter: OMPSearchFilter) async throws -> [OMPSearchHit] {
        await recorder.record(filter)
        return []
    }

    func readDocumentPage(documentID: String, page: Int) async throws -> OMPDocumentPage {
        throw OMPError.invalidFrame
    }

    func citeDocuments(_ citations: [OMPCitation]) async throws {}
}
