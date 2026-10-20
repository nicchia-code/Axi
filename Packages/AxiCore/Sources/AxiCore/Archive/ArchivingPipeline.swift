import AxiScreen
import Foundation
import os

/// How one archiving ended.
enum ArchiveOutcome: Sendable, Equatable {
    case archived(DocumentoNelVault)
    case notArchived(MotivoNonArchiviato)
}

/// A step failed for a reason the user is shown. Thrown inside the pipeline, never out of it.
struct ArchivingFailure: Error, Equatable {
    let motivo: MotivoNonArchiviato
    /// Why it failed, for the log: the detail of the reason, without addresses or paths.
    let causa: String?

    init(_ motivo: MotivoNonArchiviato, causa: String? = nil) {
        self.motivo = motivo
        self.causa = causa
    }
}

/// Runs one archiving, from the candidate to the vault, in order:
/// acquisition, duplicates, text, metadata, indexing, commit.
///
/// Everything a failed archiving wrote is removed, so nothing of the document stays in the vault.
/// An attachment that cannot be taken does not fail its email: its name goes to `allegatiNonPresi`.
struct ArchivingPipeline: Sendable {
    /// Embeddings are requested this many passages at a time.
    static let embeddingBatchSize = 16

    let vault: VaultStore
    let recognizer: any TextRecognizing
    let assistant: any AIAssistant
    let embedder: any TextEmbedding
    let attachments: (any AttachmentTaking)?
    let webPages: any WebPageRendering
    /// Downloads the PDF an address serves, before the page is rendered.
    let downloads: any WebPageDownloading
    let outlook: any OutlookEmailReading
    /// ISO 639-1 code of the interface language: summaries and tags are written in it.
    let interfaceLanguage: String
    /// Context window of the model the summaries are asked to, in tokens; read when the metadata are generated.
    let contextWindowTokens: @Sendable () async -> Int
    let now: @Sendable () -> Date
    /// Reports the steps the `attivita` Machine shows; called in order, from the archiving in progress.
    let progresso: @Sendable (EventoAttivita) -> Void

    /// Archives one candidate. `moment` is the reading that found it: relative dates are resolved against it.
    func archive(_ candidate: DocumentCandidate, moment: ReadingMoment) async -> ArchiveOutcome {
        let staging = ArchiveStaging(filesDirectory: vault.filesDirectory)
        var passo = Passo.acquisizione
        do {
            var batch = try await acquire(candidate, moment: moment, staging: staging)
            passo = .duplicati
            try dropDuplicates(&batch, staging: staging)
            passo = .testo
            try await extract(&batch, staging: staging)
            passo = .metadati
            try await describe(&batch, staging: staging)
            passo = .indicizzazione
            try await index(&batch, staging: staging)
            passo = .salvataggio
            let result = try commit(batch)
            staging.releaseScratch()
            return .archived(result)
        } catch let failure as ArchivingFailure {
            staging.discard()
            let motivo = failure.causa.map { "\(failure.motivo.nome) (\($0))" } ?? failure.motivo.nome
            Self.registra(passo, motivo, origine: Self.origine(candidate))
            return .notArchived(failure.motivo)
        } catch is CancellationError {
            staging.discard()
            Self.registra(passo, MotivoNonArchiviato.ompFermato.nome, origine: Self.origine(candidate))
            return .notArchived(.ompFermato)
        } catch {
            staging.discard()
            Self.registra(passo, MotivoNonArchiviato.erroreImprevisto.nome, origine: Self.origine(candidate))
            return .notArchived(.erroreImprevisto)
        }
    }

    // MARK: Batch

    /// The documents of one archiving: the candidate and, when it is an attachment, its email.
    /// Works come parents first; `primaryID` is the one the user sees.
    private struct Batch {
        var works: [Work]
        /// Names of attachments not taken.
        var missing: [String]
        let primaryID: String
    }

    /// One document of the batch, filled step by step.
    private struct Work {
        var id = UUID().uuidString
        var kind: DocumentKind
        /// A required work fails the whole archiving; an attachment fails only itself.
        var isRequired: Bool
        var originalName: String? = nil
        /// The copy in the vault's files folder, if any.
        var copyURL: URL? = nil
        var pdfMissing = false
        var source: DocumentSource
        var contentHash: String
        var email: EmailDetails? = nil
        var emailID: String? = nil
        var pages: [DocumentPage] = []
        var metadata: DocumentMetadata? = nil
        var chunks: [DocumentChunk] = []
    }

    // MARK: Acquisition

    private func acquire(_ candidate: DocumentCandidate, moment: ReadingMoment, staging: ArchiveStaging) async throws -> Batch {
        switch candidate {
        case .file(let file):
            return try await acquireFile(file, moment: moment, staging: staging)
        case .email(let message):
            return try await acquireEmail(message, moment: moment, staging: staging)
        case .webPage(let page):
            return try await acquireWebPage(page, staging: staging)
        }
    }

    private func acquireFile(_ file: FileDocument, moment: ReadingMoment, staging: ArchiveStaging) async throws -> Batch {
        let url = file.url
        let name = url.lastPathComponent
        let kind = TextExtractor.kind(of: url)
        let source = DocumentSource(app: file.source.name, path: url.path)

        let copy: URL
        do {
            copy = try staging.copyFile(from: url, extension: url.pathExtension)
        } catch {
            throw ArchivingFailure(.documentoIllegibile)
        }

        if kind == .email {
            // An `.eml` file is the email itself: its body is the text, its attachments are listed as missing.
            guard let data = try? Data(contentsOf: copy), let parsed = EmlParser.parse(data) else {
                throw ArchivingFailure(.documentoIllegibile)
            }
            let email = emailWork(
                sender: parsed.sender,
                recipients: parsed.recipients,
                subject: parsed.subject,
                receivedAt: parsed.sentAt.flatMap(EmailDate.parse),
                displayedSentAt: nil,
                body: parsed.body,
                source: source,
                originalName: name,
                copyURL: copy,
                moment: moment
            )
            return Batch(works: [email], missing: parsed.attachmentNames, primaryID: email.id)
        }

        let contentHash: String
        do {
            contentHash = try Fingerprint.sha256(fileAt: copy)
        } catch {
            throw ArchivingFailure(.documentoIllegibile)
        }
        var primary = Work(kind: kind, isRequired: true, originalName: name, copyURL: copy, source: source, contentHash: contentHash)

        // An attachment saved from Outlook: link it to its email, or bring the email in with it.
        var parent: Work?
        var missing: [String] = []
        let linkedEmails = OutlookAttachments.isOutlookFolder(url)
            ? try storage { try vault.emailIDs(havingAttachmentNamed: name) }
            : []
        if let linked = linkedEmails.first {
            primary.emailID = linked
        } else if OutlookAttachments.isOutlookFolder(url), let message = await outlook.emailOnScreen(),
                  message.attachmentNames.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }),
                  !message.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let email = try await emailWork(message, source: DocumentSource(app: message.source.name), moment: moment)
            let stored = try storage { try vault.document(withContentHash: email.contentHash) }
            if let stored {
                primary.emailID = stored.id
            } else {
                primary.emailID = email.id
                parent = email
            }
            missing = message.attachmentNames.filter { $0.caseInsensitiveCompare(name) != .orderedSame }
        }

        var works: [Work] = []
        if let parent { works.append(parent) }
        works.append(primary)
        return Batch(works: works, missing: missing, primaryID: primary.id)
    }

    private func acquireEmail(_ message: EmailMessage, moment: ReadingMoment, staging: ArchiveStaging) async throws -> Batch {
        let email = try await emailWork(message, source: DocumentSource(app: message.source.name), moment: moment)
        let taken = await takeAttachments(of: message, parentID: email.id, staging: staging)
        return Batch(works: [email] + taken.works, missing: taken.missing, primaryID: email.id)
    }

    private func acquireWebPage(_ page: WebPage, staging: ArchiveStaging) async throws -> Batch {
        let source = DocumentSource(app: page.source.name, url: page.address.absoluteString)

        // An address that serves a PDF is archived as that PDF: the page is neither rendered nor compared with its text.
        let download: WebPageDownload
        do {
            download = try await downloads.download(page.address)
        } catch let failure as WebPageDownloadFailure {
            throw ArchivingFailure(failure.motivo, causa: failure.causa)
        }
        if case .pdf(let file, let name) = download {
            defer { try? FileManager.default.removeItem(at: file) }
            let copy: URL
            let contentHash: String
            do {
                copy = try staging.copyFile(from: file, extension: "pdf")
                contentHash = try Fingerprint.sha256(fileAt: copy)
            } catch {
                throw ArchivingFailure(.documentoIllegibile)
            }
            let work = Work(kind: .pdf, isRequired: true, originalName: name, copyURL: copy, source: source, contentHash: contentHash)
            return Batch(works: [work], missing: [], primaryID: work.id)
        }

        // Not a PDF: the page is archived as a web page, from its rendered PDF when it matches, else from its text.
        let visible = (page.visibleText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !visible.isEmpty else { throw ArchivingFailure(.documentoIllegibile) }

        // The PDF is kept only if it is the page the user was reading; otherwise only the text is.
        let pdf: Data?
        do {
            pdf = try await webPages.pdf(of: page.address)
        } catch {
            try ensureNotCancelled()
            Self.registra(.acquisizione, "web PDF not created: \(Self.descrizione(error))", origine: Self.origine(source))
            pdf = nil
        }
        if let pdf {
            do {
                let copy = try staging.write(pdf, extension: "pdf")
                if WebPageMatch.matches(visibleText: visible, pdfText: TextExtractor.nativeText(of: copy)) {
                    let work = Work(
                        kind: .web,
                        isRequired: true,
                        copyURL: copy,
                        source: source,
                        contentHash: Fingerprint.sha256(pdf)
                    )
                    return Batch(works: [work], missing: [], primaryID: work.id)
                }
                staging.remove(copy)
                Self.registra(.acquisizione, "web PDF discarded: it does not match the page", origine: Self.origine(source))
            } catch {
                Self.registra(.acquisizione, "web PDF not kept: \(Self.descrizione(error))", origine: Self.origine(source))
            }
        }

        let work = Work(
            kind: .web,
            isRequired: true,
            pdfMissing: true,
            source: source,
            contentHash: Fingerprint.webPage(address: page.address, visibleText: visible),
            pages: [DocumentPage(number: 1, text: visible)]
        )
        return Batch(works: [work], missing: [], primaryID: work.id)
    }

    /// The attachments an email holds, as far as they could be taken. A name not answered is missing.
    private func takeAttachments(
        of message: EmailMessage,
        parentID: String,
        staging: ArchiveStaging
    ) async -> (works: [Work], missing: [String]) {
        guard let attachments, let scratch = try? staging.scratchDirectory() else {
            return ([], message.attachmentNames)
        }
        let answers = await attachments.take(message, into: scratch)

        var works: [Work] = []
        var missing: [String] = []
        var answered = Set<String>()
        let origine = Self.origine(DocumentSource(app: message.source.name))
        for answer in answers {
            switch answer {
            case .missing(let name):
                answered.insert(name)
                missing.append(name)
                Self.registra(.acquisizione, "attachment not taken", origine: origine)
            case .file(let name, let url):
                answered.insert(name)
                let kind = TextExtractor.kind(of: url) == .email ? DocumentKind.other : TextExtractor.kind(of: url)
                let copy: URL
                do {
                    copy = try staging.copyFile(from: url, extension: url.pathExtension)
                } catch {
                    missing.append(name)
                    Self.registra(.acquisizione, "attachment copy failed", origine: origine)
                    continue
                }
                let hash: String
                do {
                    hash = try Fingerprint.sha256(fileAt: copy)
                } catch {
                    staging.remove(copy)
                    missing.append(name)
                    Self.registra(.acquisizione, "attachment fingerprint failed", origine: origine)
                    continue
                }
                works.append(Work(
                    kind: kind,
                    isRequired: false,
                    originalName: name,
                    copyURL: copy,
                    source: DocumentSource(app: message.source.name),
                    contentHash: hash,
                    emailID: parentID
                ))
            }
        }
        for name in message.attachmentNames where !answered.contains(name) {
            missing.append(name)
            Self.registra(.acquisizione, "attachment not answered", origine: origine)
        }
        return (works, missing)
    }

    /// The work of an email on screen in Outlook. Its receipt date is asked to OMP in its own request.
    private func emailWork(
        _ message: EmailMessage,
        source: DocumentSource,
        moment: ReadingMoment
    ) async throws -> Work {
        let displayed = message.sentAt?.trimmingCharacters(in: .whitespacesAndNewlines)
        let shown = displayed?.isEmpty == false ? displayed : nil
        var receivedAt: Date?
        if let shown {
            receivedAt = try await receiptDate(displayed: shown, moment: moment, origine: Self.origine(source))
        }
        return emailWork(
            sender: message.sender ?? "",
            recipients: message.recipients,
            subject: message.subject ?? "",
            receivedAt: receivedAt,
            displayedSentAt: shown,
            body: message.body,
            source: source,
            originalName: nil,
            copyURL: nil,
            moment: moment
        )
    }

    /// The absolute receipt date of an email, as OMP reads the text Outlook shows. Nil when OMP gives no
    /// valid answer, fails or does not answer in time: the failure is logged, and archiving goes on with
    /// the date unknown.
    private func receiptDate(displayed: String, moment: ReadingMoment, origine: String) async throws -> Date? {
        let prompt = ReceiptDate.prompt(displayed: displayed, moment: moment)
        let assistant = self.assistant
        let answer: ReceiptAnswer = await withTaskGroup(of: ReceiptAnswer.self) { group in
            group.addTask {
                do {
                    return .text(try await assistant.complete(prompt))
                } catch {
                    return .failed
                }
            }
            group.addTask {
                try? await Task.sleep(for: ReceiptDate.timeout)
                return .timedOut
            }
            let first: ReceiptAnswer = await group.next() ?? .timedOut
            group.cancelAll()
            return first
        }
        try ensureNotCancelled()
        switch answer {
        case .text(let reply):
            if let date = ReceiptDate.parse(reply) { return date }
            Self.registra(.acquisizione, "receipt date not valid", origine: origine)
        case .failed:
            Self.registra(.acquisizione, "receipt date not given: OMP failed", origine: origine)
        case .timedOut:
            Self.registra(.acquisizione, "receipt date not given: OMP timed out", origine: origine)
        }
        return nil
    }

    private func emailWork(
        sender: String,
        recipients: [String],
        subject: String,
        receivedAt: Date?,
        displayedSentAt: String?,
        body: String,
        source: DocumentSource,
        originalName: String?,
        copyURL: URL?,
        moment: ReadingMoment
    ) -> Work {
        let details = EmailDetails(
            sender: sender,
            recipients: recipients,
            subject: subject,
            sentAt: receivedAt,
            displayedSentAt: displayedSentAt
        )
        let receivedDay = receivedAt.map { Fingerprint.day(of: $0, in: moment.timeZone) }
        return Work(
            kind: .email,
            isRequired: true,
            originalName: originalName,
            copyURL: copyURL,
            source: source,
            contentHash: Fingerprint.email(
                sender: sender, receivedDay: receivedDay, subject: subject, body: body),
            email: details,
            pages: [DocumentPage(number: 1, text: body)]
        )
    }

    // MARK: Duplicates

    /// A required document already in the vault stops the archiving. A duplicate attachment is simply
    /// not stored again: it is neither archived nor missing.
    private func dropDuplicates(_ batch: inout Batch, staging: ArchiveStaging) throws {
        var seen = Set<String>()
        var kept: [Work] = []
        for work in batch.works {
            let stored = try storage { try vault.document(withContentHash: work.contentHash) }
            if let stored, work.isRequired {
                let copy = try storage { try vault.copyURL(ofDocument: stored.id) } ?? vault.filesDirectory
                throw ArchivingFailure(.giaPresente(copia: copy))
            }
            if stored != nil || !seen.insert(work.contentHash).inserted {
                staging.remove(work.copyURL)
                continue
            }
            kept.append(work)
        }
        batch.works = kept
    }

    // MARK: Text

    private func extract(_ batch: inout Batch, staging: ArchiveStaging) async throws {
        let extractor = TextExtractor(recognizer: recognizer)
        try await process(&batch, staging: staging, passo: .testo) { work in
            var work = work
            if work.pages.isEmpty, let copy = work.copyURL {
                do {
                    work.pages = try await extractor.pages(of: copy)
                } catch is TextExtractor.Failure {
                    throw ArchivingFailure(.documentoIllegibile)
                } catch {
                    // An attachment's error, whatever it is, is its failure; a required document keeps its own.
                    guard !work.isRequired else { throw error }
                    try ensureNotCancelled()
                    throw ArchivingFailure(.erroreImprevisto)
                }
            }
            guard work.pages.contains(where: { TokenEstimate.wordCount($0.text) > 0 }) else {
                throw ArchivingFailure(.testoAssente)
            }
            return work
        }
    }

    // MARK: Metadata

    private func describe(_ batch: inout Batch, staging: ArchiveStaging) async throws {
        progresso(.generazioneMetadatiIniziata)
        defer { progresso(.generazioneMetadatiFinita) }
        let vocabulary = try storage { try vault.vocabulary() }
        let generator = MetadataGenerator(
            assistant: assistant,
            contextWindowTokens: await contextWindowTokens(),
            language: interfaceLanguage
        )
        try await process(&batch, staging: staging, passo: .metadati) { work in
            var work = work
            let metadata: DocumentMetadata?
            let reference = Self.dateReference(of: work, archivedAt: now())
            do {
                metadata = try await generator.generate(pages: work.pages, vocabulary: vocabulary, reference: reference)
            } catch {
                try ensureNotCancelled()
                metadata = nil
            }
            guard let metadata else { throw ArchivingFailure(.aiNonRisponde) }
            work.metadata = metadata
            return work
        }
    }

    /// The moment a document's relative dates are resolved against: the receipt date of an email,
    /// or the archiving moment for any other document (its text may state its own date).
    private static func dateReference(of work: Work, archivedAt: Date) -> DateReference {
        guard work.kind == .email else { return .archiving(archivedAt) }
        guard let sentAt = work.email?.sentAt else { return .unknown }
        return .receipt(sentAt)
    }

    // MARK: Indexing

    private func index(_ batch: inout Batch, staging: ArchiveStaging) async throws {
        try await process(&batch, staging: staging, passo: .indicizzazione) { work in
            var work = work
            let passages = Chunker.passages(of: work.pages)
            var chunks: [DocumentChunk] = []
            var start = 0
            while start < passages.count {
                let slice = Array(passages[start..<min(start + Self.embeddingBatchSize, passages.count)])
                let vectors = try await stage(.indicizzazioneFallita) {
                    try await embedder.embed(slice.map(\.text))
                }
                guard vectors.count == slice.count else { throw ArchivingFailure(.indicizzazioneFallita) }
                chunks += zip(slice, vectors).map { pair in
                    DocumentChunk(text: pair.0.text, embedding: pair.1, page: pair.0.page)
                }
                start += Self.embeddingBatchSize
            }
            work.chunks = chunks
            return work
        }
    }

    // MARK: Commit

    /// Writes the batch in one vault transaction. Nothing runs after it, so a commit is never cut short.
    private func commit(_ batch: Batch) throws -> DocumentoNelVault {
        guard let primary = batch.works.first(where: { $0.id == batch.primaryID }),
              let primaryMetadata = primary.metadata
        else { throw ArchivingFailure(.erroreImprevisto) }

        let archivedAt = now()
        let documents = try batch.works.map { work -> ArchivedDocument in
            guard let metadata = work.metadata else { throw ArchivingFailure(.aiNonRisponde) }
            var email: EmailDetails?
            if var details = work.email {
                details.missingAttachmentNames = batch.missing
                email = details
            }
            return ArchivedDocument(
                id: work.id,
                title: metadata.title,
                kind: work.kind,
                originalName: work.originalName,
                copyPath: work.copyURL?.lastPathComponent,
                pdfMissing: work.pdfMissing,
                source: work.source,
                contentHash: work.contentHash,
                documentDate: metadata.documentDate,
                archivedAt: archivedAt,
                language: metadata.language,
                summary: metadata.summary,
                tags: metadata.tags,
                pages: work.pages,
                chunks: work.chunks,
                citedDates: metadata.citedDates,
                email: email,
                emailID: work.emailID
            )
        }

        try Task.checkCancellation()
        try storage { try vault.archive(documents) }

        return DocumentoNelVault(
            titolo: primaryMetadata.title,
            tag: primaryMetadata.tags,
            allegatiNonPresi: batch.missing,
            copia: primary.copyURL ?? vault.filesDirectory,
            pdfNonPresente: primary.pdfMissing,
            dataRicezioneSconosciuta: batch.works.contains { $0.kind == .email && $0.email?.sentAt == nil }
        )
    }

    // MARK: Helpers

    /// Runs a step on every work. A required work's failure stops the archiving; an attachment's
    /// failure removes its copy, lists it as missing and is logged.
    private func process(
        _ batch: inout Batch,
        staging: ArchiveStaging,
        passo: Passo,
        _ body: (Work) async throws -> Work
    ) async throws {
        var kept: [Work] = []
        for work in batch.works {
            do {
                kept.append(try await body(work))
            } catch let failure as ArchivingFailure where !work.isRequired {
                Self.registra(passo, failure.motivo.nome, origine: Self.origine(work.source))
                staging.remove(work.copyURL)
                if let name = work.originalName {
                    batch.missing.append(name)
                }
            }
        }
        batch.works = kept
    }

    /// Runs a step that calls a service: its failure becomes `motivo`, a cancellation stays a cancellation.
    private func stage<T>(_ motivo: MotivoNonArchiviato, _ body: () async throws -> T) async throws -> T {
        do {
            return try await body()
        } catch let failure as ArchivingFailure {
            throw failure
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try ensureNotCancelled()
            throw ArchivingFailure(motivo)
        }
    }

    /// Runs a vault call: any error the vault raises is an unexpected error.
    private func storage<T>(_ body: () throws -> T) throws -> T {
        do {
            return try body()
        } catch {
            throw ArchivingFailure(.erroreImprevisto)
        }
    }

    private func ensureNotCancelled() throws {
        if Task.isCancelled { throw CancellationError() }
    }
}

/// The files an archiving writes: copies in the vault's folder and a scratch folder for attachments.
/// What is not committed is removed; the scratch folder is removed in any case.
private final class ArchiveStaging {
    private let filesDirectory: URL
    private let scratch: URL
    /// Copies written in the files folder by this archiving.
    private var copies: [URL] = []
    private var scratchCreated = false

    init(filesDirectory: URL) {
        self.filesDirectory = filesDirectory
        scratch = FileManager.default.temporaryDirectory
            .appendingPathComponent("axi-archive-\(UUID().uuidString)", isDirectory: true)
    }

    /// `<uuid>.<extension>` in the files folder; the extension is kept in lowercase.
    private func newCopyURL(extension ext: String) -> URL {
        let name = ext.isEmpty ? UUID().uuidString : "\(UUID().uuidString).\(ext.lowercased())"
        let url = filesDirectory.appendingPathComponent(name)
        copies.append(url)
        return url
    }

    func copyFile(from source: URL, extension ext: String) throws -> URL {
        let destination = newCopyURL(extension: ext)
        do {
            try FileManager.default.copyItem(at: source, to: destination)
        } catch {
            remove(destination)
            throw error
        }
        return destination
    }

    func write(_ data: Data, extension ext: String) throws -> URL {
        let destination = newCopyURL(extension: ext)
        do {
            try data.write(to: destination)
        } catch {
            remove(destination)
            throw error
        }
        return destination
    }

    func remove(_ url: URL?) {
        guard let url else { return }
        try? FileManager.default.removeItem(at: url)
        copies.removeAll { $0 == url }
    }

    func scratchDirectory() throws -> URL {
        if !scratchCreated {
            try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
            scratchCreated = true
        }
        return scratch
    }

    /// After a commit: the copies stay, the scratch folder goes.
    func releaseScratch() {
        try? FileManager.default.removeItem(at: scratch)
    }

    /// After a failure: nothing of the archiving stays.
    func discard() {
        for url in copies {
            try? FileManager.default.removeItem(at: url)
        }
        copies = []
        releaseScratch()
    }
}

/// The steps of an archiving, as the log names them.
fileprivate enum Passo: String {
    case acquisizione, duplicati, testo, metadati, indicizzazione, salvataggio
}

/// The answer of OMP to the receipt date request: a text, a failure, or no answer in time.
fileprivate enum ReceiptAnswer {
    case text(String)
    case failed
    case timedOut
}

/// The log of the archiving: the failed steps, with their reason and origin.
private let logArchiviazione = Logger(subsystem: "Axi", category: "archiviazione")

extension ArchivingPipeline {
    /// Records a failed step with its reason and origin. Never the document text, nor full addresses.
    fileprivate static func registra(_ passo: Passo, _ motivo: String, origine: String) {
        logArchiviazione.error(
            "Step \(passo.rawValue, privacy: .public) failed: \(motivo, privacy: .public); origin \(origine, privacy: .public)"
        )
    }

    /// The kind of an error, without its details: they may carry addresses or paths.
    fileprivate static func descrizione(_ error: Error) -> String {
        if let failure = error as? WebPageRenderer.Failure {
            return "\(failure)"
        }
        return "unexpected error"
    }

    /// The application, and the domain of a web page: no path and no full address.
    static func origine(_ source: DocumentSource) -> String {
        let app = source.app ?? "unknown application"
        guard let url = source.url, let host = URL(string: url)?.host() else { return app }
        return "\(app), \(host)"
    }

    static func origine(_ candidate: DocumentCandidate) -> String {
        switch candidate {
        case .file(let file): origine(DocumentSource(app: file.source.name))
        case .email(let email): origine(DocumentSource(app: email.source.name))
        case .webPage(let page): origine(DocumentSource(app: page.source.name, url: page.address.absoluteString))
        }
    }
}

extension MotivoNonArchiviato {
    /// The name of the reason in the log.
    fileprivate var nome: String {
        switch self {
        case .giaPresente: "already present"
        case .ompNonPronto: "OMP not ready"
        case .ompFermato: "OMP stopped"
        case .benvenutoNonCompletato: "welcome not completed"
        case .documentoIllegibile: "document unreadable"
        case .testoAssente: "no text"
        case .aiNonRisponde: "AI did not answer validly"
        case .indicizzazioneFallita: "indexing failed"
        case .pdfNonScaricato: "web PDF not downloaded"
        case .pdfTroppoGrande: "web PDF too large"
        case .erroreImprevisto: "unexpected error"
        }
    }
}

extension WebPageDownloadFailure {
    /// The reason the user is shown: a PDF too large, or any other PDF not downloaded.
    fileprivate var motivo: MotivoNonArchiviato {
        self == .tooLarge ? .pdfTroppoGrande : .pdfNonScaricato
    }

    /// The cause in the log, without details: they may carry addresses.
    fileprivate var causa: String {
        switch self {
        case .timedOut: "timed out"
        case .network: "network or server error"
        case .notPDF: "response is not a PDF"
        case .tooLarge: "too large"
        }
    }
}
