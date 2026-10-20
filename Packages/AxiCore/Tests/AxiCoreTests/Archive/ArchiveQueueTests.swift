import Testing
@testable import AxiCore

@Suite("Coda di archiviazione")
struct ArchiveQueueTests {
    @Test("Da Vuota, un documento individuato senza archiviazione in corso parte subito")
    func documentStartsImmediatelyWhenIdle() {
        var queue = ArchiveQueue<String>()

        let started = queue.receive(.documentIdentified(["a"]))

        #expect(started == "a")
        #expect(queue.state == .empty)
        #expect(queue.pendingCount == 0)
    }

    @Test("Da Vuota, un documento individuato con archiviazione in corso aspetta il suo turno")
    func documentWaitsWhileArchiving() {
        var queue = ArchiveQueue<String>()
        _ = queue.receive(.documentIdentified(["a"]))

        let started = queue.receive(.documentIdentified(["b"]))

        #expect(started == nil)
        #expect(queue.state == .withWaitingDocuments)
        #expect(queue.pendingCount == 1)
    }

    @Test("Da Vuota, un solo file senza archiviazione in corso parte subito")
    func singleFileStartsImmediatelyWhenIdle() {
        var queue = ArchiveQueue<String>()

        let started = queue.receive(.filesReleased(["a"]))

        #expect(started == "a")
        #expect(queue.state == .empty)
        #expect(queue.pendingCount == 0)
    }

    @Test("Da Vuota, un solo file con archiviazione in corso aspetta")
    func singleFileWaitsWhileArchiving() {
        var queue = ArchiveQueue<String>()
        _ = queue.receive(.filesReleased(["a"]))

        let started = queue.receive(.filesReleased(["b"]))

        #expect(started == nil)
        #expect(queue.state == .withWaitingDocuments)
        #expect(queue.pendingCount == 1)
    }

    @Test("Da Vuota, più file senza archiviazione in corso: parte il primo, gli altri aspettano")
    func multipleFilesStartFirstWhenIdle() {
        var queue = ArchiveQueue<String>()

        let started = queue.receive(.filesReleased(["a", "b", "c"]))

        #expect(started == "a")
        #expect(queue.state == .withWaitingDocuments)
        #expect(queue.pendingCount == 2)
    }

    @Test("Da Vuota, più file con archiviazione in corso aspettano tutti nell'ordine di consegna")
    func multipleFilesAllWaitWhileArchiving() {
        var queue = ArchiveQueue<String>()
        _ = queue.receive(.documentIdentified(["x"]))

        let started = queue.receive(.filesReleased(["a", "b"]))

        #expect(started == nil)
        #expect(queue.state == .withWaitingDocuments)
        #expect(queue.pendingCount == 2)
    }

    @Test("Da Vuota, una selezione del Finder di più file: parte il primo, gli altri aspettano nell'ordine")
    func identifiedSelectionStartsFirstWhenIdle() {
        var queue = ArchiveQueue<String>()

        let started = queue.receive(.documentIdentified(["a", "b", "c"]))

        #expect(started == "a")
        #expect(queue.state == .withWaitingDocuments)
        #expect(queue.pendingCount == 2)
        #expect(queue.receive(.archived) == "b")
        #expect(queue.receive(.archived) == "c")
        #expect(queue.state == .empty)
    }

    @Test("Un rilascio vuoto non cambia la coda")
    func emptyReleaseChangesNothing() {
        var queue = ArchiveQueue<String>()

        #expect(queue.receive(.filesReleased([])) == nil)
        #expect(queue.state == .empty)
        #expect(queue.pendingCount == 0)
    }

    @Test("Con documenti in attesa, documenti e file si aggiungono in fondo")
    func newItemsAppendAtTheEnd() {
        var queue = ArchiveQueue<String>()
        _ = queue.receive(.documentIdentified(["x"]))
        _ = queue.receive(.documentIdentified(["b"]))

        #expect(queue.receive(.documentIdentified(["c"])) == nil)
        #expect(queue.receive(.filesReleased(["d", "e"])) == nil)
        #expect(queue.pendingCount == 4)

        #expect(queue.receive(.archived) == "b")
        #expect(queue.receive(.archived) == "c")
        #expect(queue.receive(.archived) == "d")
        #expect(queue.receive(.archived) == "e")
        #expect(queue.receive(.archived) == nil)
        #expect(queue.state == .empty)
    }

    @Test("ARCHIVIATO con altri in attesa fa partire il primo e resta in attesa")
    func archivedStartsNextAndKeepsWaiting() {
        var queue = ArchiveQueue<String>()
        _ = queue.receive(.filesReleased(["a", "b", "c"]))

        let started = queue.receive(.archived)

        #expect(started == "b")
        #expect(queue.state == .withWaitingDocuments)
        #expect(queue.pendingCount == 1)
    }

    @Test("ARCHIVIATO sull'ultimo documento in coda lo fa partire e torna Vuota")
    func archivedOnLastWaitingStartsItAndEmpties() {
        var queue = ArchiveQueue<String>()
        _ = queue.receive(.filesReleased(["a", "b"]))

        let started = queue.receive(.archived)

        #expect(started == "b")
        #expect(queue.state == .empty)
        #expect(queue.pendingCount == 0)
    }

    @Test("NON_ARCHIVIATO fa partire il primo in coda come ARCHIVIATO")
    func notArchivedStartsNextAndKeepsWaiting() {
        var queue = ArchiveQueue<String>()
        _ = queue.receive(.filesReleased(["a", "b", "c"]))

        let started = queue.receive(.notArchived)

        #expect(started == "b")
        #expect(queue.state == .withWaitingDocuments)
        #expect(queue.pendingCount == 1)
    }

    @Test("NON_ARCHIVIATO sull'ultimo documento in coda lo fa partire e torna Vuota")
    func notArchivedOnLastWaitingStartsItAndEmpties() {
        var queue = ArchiveQueue<String>()
        _ = queue.receive(.filesReleased(["a", "b"]))

        let started = queue.receive(.notArchived)

        #expect(started == "b")
        #expect(queue.state == .empty)
        #expect(queue.pendingCount == 0)
    }

    @Test("Dopo che l'archiviazione finisce da Vuota, un nuovo documento parte subito")
    func newDocumentStartsAfterIdleArchiving() {
        var queue = ArchiveQueue<String>()
        _ = queue.receive(.documentIdentified(["a"]))

        #expect(queue.receive(.archived) == nil)
        #expect(queue.state == .empty)
        #expect(queue.receive(.documentIdentified(["b"])) == "b")
        #expect(queue.state == .empty)
    }

    @Test("Un esito senza archiviazione in corso non fa partire nulla")
    func outcomeWithoutArchivingStartsNothing() {
        var queue = ArchiveQueue<String>()

        #expect(queue.receive(.archived) == nil)
        #expect(queue.receive(.notArchived) == nil)
        #expect(queue.state == .empty)
        #expect(queue.pendingCount == 0)
    }

    @Test("Il numero in attesa segue gli arrivi e le fini delle archiviazioni")
    func pendingCountFollowsTheFlow() {
        var queue = ArchiveQueue<String>()
        _ = queue.receive(.documentIdentified(["a"]))
        _ = queue.receive(.documentIdentified(["b"]))
        #expect(queue.pendingCount == 1)

        _ = queue.receive(.filesReleased(["c", "d"]))
        #expect(queue.pendingCount == 3)

        _ = queue.receive(.archived)
        #expect(queue.pendingCount == 2)

        _ = queue.receive(.notArchived)
        #expect(queue.pendingCount == 1)

        _ = queue.receive(.archived)
        #expect(queue.pendingCount == 0)
        #expect(queue.state == .empty)
    }
}
