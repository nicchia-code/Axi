/// Documents waiting to be archived: one archiving at a time, in arrival order.
///
/// Pure state machine of `coda-archiviazione`. `receive` returns the item that starts
/// archiving now; the caller emits it as `coda-archiviazione.PROSSIMO_DOCUMENTO`.
public struct ArchiveQueue<Item: Sendable>: Sendable {
    public enum Input: Sendable {
        /// `lettura-schermo.DOCUMENTO_INDIVIDUATO`, with the documents in the order they are found: a Finder selection brings all its files.
        case documentIdentified([Item])
        /// `utente.RILASCIA_FILE`, with the files in the order the Finder delivers them.
        case filesReleased([Item])
        /// `archiviazione.ARCHIVIATO`.
        case archived
        /// `archiviazione.NON_ARCHIVIATO`.
        case notArchived
    }

    public enum State: Sendable, Equatable {
        /// Vuota.
        case empty
        /// Con documenti in attesa.
        case withWaitingDocuments
    }

    /// Documents waiting for their turn, in arrival order.
    private var waiting: [Item] = []
    /// Whether an archiving is in progress. Tracked here so that a document arriving
    /// while the queue is empty still waits behind an archiving that is running.
    private var archiving = false

    public init() {}

    public var state: State {
        waiting.isEmpty ? .empty : .withWaitingDocuments
    }

    /// Number of documents waiting for their turn. The document being archived is not counted.
    public var pendingCount: Int {
        waiting.count
    }

    /// Applies an input and returns the item that starts archiving, if any.
    public mutating func receive(_ input: Input) -> Item? {
        switch input {
        case .documentIdentified(let items):
            waiting.append(contentsOf: items)
            return startNextIfIdle()
        case .filesReleased(let items):
            waiting.append(contentsOf: items)
            return startNextIfIdle()
        case .archived, .notArchived:
            archiving = false
            return startNextIfIdle()
        }
    }

    private mutating func startNextIfIdle() -> Item? {
        guard !archiving, !waiting.isEmpty else { return nil }
        archiving = true
        return waiting.removeFirst()
    }
}
