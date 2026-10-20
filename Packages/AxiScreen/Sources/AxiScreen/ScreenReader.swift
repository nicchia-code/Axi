import CoreGraphics
import Foundation
import os

/// Why a reading was asked for.
public enum ReadingPurpose: Sendable, Equatable {
    case archiving
    case chat
}

/// One user request to read the screen.
public struct ReadingRequest: Sendable, Equatable {
    public var purpose: ReadingPurpose
    /// The application that was in front when the user asked, captured before Axi took the focus.
    public var target: ApplicationSnapshot

    public init(purpose: ReadingPurpose, target: ApplicationSnapshot) {
        self.purpose = purpose
        self.target = target
    }
}

/// When a reading was made: the instant and the time zone of the Mac at that moment, so that the relative
/// dates on screen ("2 hours ago", "tomorrow") can be made absolute.
public struct ReadingMoment: Sendable, Equatable {
    public var date: Date
    public var timeZone: TimeZone

    public init(date: Date, timeZone: TimeZone) {
        self.date = date
        self.timeZone = timeZone
    }

    /// The moment of the call, with the time zone of the Mac.
    public static var now: ReadingMoment {
        ReadingMoment(date: Date(), timeZone: .current)
    }
}

/// Where the text of a context came from.
public enum TextSource: Sendable, Equatable {
    case accessibility
    case vision
    case azure
}

/// What the chat needs to know about the screen.
public struct ScreenContext: Sendable, Equatable {
    public var application: ApplicationSnapshot
    public var windowTitle: String?
    public var document: DocumentCandidate?
    public var visibleText: String
    public var textSource: TextSource
    public var moment: ReadingMoment

    public init(
        application: ApplicationSnapshot,
        windowTitle: String?,
        document: DocumentCandidate?,
        visibleText: String,
        textSource: TextSource,
        moment: ReadingMoment
    ) {
        self.application = application
        self.windowTitle = windowTitle
        self.document = document
        self.visibleText = visibleText
        self.textSource = textSource
        self.moment = moment
    }
}

/// Why the reading of the context failed (`lettura-schermo.LETTURA_FALLITA`).
public enum ReadingFailure: Sendable, Equatable {
    /// The permissions the reading lacks, never empty: Screen Recording, and Accessibility too when it is missing as well.
    case permissionMissing([Permissions.Permission])
    /// The window could not be captured.
    case captureFailed
    /// The recognized text is empty.
    case noText
    /// The text could not be recognized.
    case recognitionFailed
}

/// Why the search found no document to archive (`lettura-schermo.NESSUN_DOCUMENTO`).
public enum NoDocumentReason: Error, Sendable, Equatable {
    /// Nothing archivable in front: no file, email or web page.
    case nothingInFront
    /// A web page is in front, but its address cannot be read.
    case addressUnreadable
    /// A web page is in front, but the Automation that reads its address is missing for this browser (its name as the user knows it).
    case browserAutomationMissing(browser: String)
    /// A permission the search needs is missing.
    case permissionMissing(Permissions.Permission)
    /// The search stopped on an error no other reason foresees.
    case unexpectedError
}

/// The events of the screen-reading machine.
public enum ScreenReadingEvent: Sendable, Equatable {
    /// `DOCUMENTO_INDIVIDUATO`, with the documents in order and the moment of the reading: a Finder selection gives all its files.
    case documentFound([DocumentCandidate], at: ReadingMoment)
    /// `NESSUN_DOCUMENTO`, with the reason
    case noDocument(NoDocumentReason)
    /// `CONTESTO_LETTO`
    case contextRead(ScreenContext)
    /// `TESTO_NON_ACCESSIBILE`
    case textNotAccessible
    /// `LETTURA_FALLITA`
    case readingFailed(ReadingFailure)
}

/// Reads the Accessibility tree of an application.
public protocol AccessibilityReading: Sendable {
    /// Throws when the tree cannot be read for a reason no other outcome explains.
    func snapshot(of application: ApplicationSnapshot) async throws -> AccessibilitySnapshot?
    /// Performs `action` on the first element of the application's main window named `name` that accepts it.
    /// False when no such element exists or the action fails.
    func perform(action: String, onElementNamed name: String, in application: ApplicationSnapshot) async -> Bool
}

/// Captures the main window of an application as an image.
public protocol WindowCapturing: Sendable {
    func capture(of application: ApplicationSnapshot) async throws -> CGImage
}

/// Turns a captured image into text.
public protocol TextRecognizing: Sendable {
    var source: TextSource { get }
    func recognizeText(in image: CGImage) async throws -> String
}

/// The permissions the reading depends on.
public protocol ScreenPermissions: Sendable {
    var accessibilityGranted: Bool { get }
    var screenRecordingGranted: Bool { get }
    /// Whether the Automation permission of a browser or of the Finder is missing: macOS denied it or has not asked yet.
    func browserAutomationMissing(bundleIdentifier: String) -> Bool
}

/// Reads the items selected in the Finder through Apple Events, for when Accessibility gives no selection.
public protocol FinderSelectionReading: Sendable {
    /// The URLs of the selection in selection order, folders included. Nil when Apple Events fail.
    func selectedURLs() async -> [URL]?
}

/// Runs the screen-reading machine. Requests are served one at a time, in arrival order.
public actor ScreenReader {
    /// Refusals and failures, with their step, reason and app. Never the screen text nor an address.
    private let logger = Logger(subsystem: "Axi", category: "lettura-schermo")

    private let accessibility: any AccessibilityReading
    private let capturer: any WindowCapturing
    private let permissions: any ScreenPermissions
    private let finderSelection: any FinderSelectionReading
    private let makeRecognizer: @Sendable () -> any TextRecognizing
    private let clock: @Sendable () -> ReadingMoment
    private let emit: @Sendable (ScreenReadingEvent) -> Void
    private let finder = DocumentFinder()
    private var busy = false
    private var waiting: [CheckedContinuation<Void, Never>] = []

    /// - Parameter makeRecognizer: called for each reading that needs OCR, so the choice between
    ///   Azure Document Intelligence and Vision follows the current settings.
    public init(
        accessibility: any AccessibilityReading,
        capturer: any WindowCapturing,
        permissions: any ScreenPermissions,
        finderSelection: any FinderSelectionReading = LiveFinderSelection(),
        makeRecognizer: @escaping @Sendable () -> any TextRecognizing,
        clock: @escaping @Sendable () -> ReadingMoment = { .now },
        emit: @escaping @Sendable (ScreenReadingEvent) -> Void
    ) {
        self.accessibility = accessibility
        self.capturer = capturer
        self.permissions = permissions
        self.finderSelection = finderSelection
        self.makeRecognizer = makeRecognizer
        self.emit = emit
        self.clock = clock
    }

    /// Serves one request and emits its events. A request that arrives meanwhile waits for this one to end.
    public func handle(_ request: ReadingRequest) async {
        await acquire()
        let moment = clock()
        for event in await perform(request, at: moment) {
            log(event, from: request.target)
            emit(event)
        }
        release()
    }

    private func perform(_ request: ReadingRequest, at moment: ReadingMoment) async -> [ScreenReadingEvent] {
        switch request.purpose {
        case .archiving:
            return [await searchDocument(in: request.target, at: moment)]
        case .chat:
            return await readContext(of: request.target, at: moment)
        }
    }

    /// Ricerca del documento: looks for the archivable documents in the front app.
    private func searchDocument(in target: ApplicationSnapshot, at moment: ReadingMoment) async -> ScreenReadingEvent {
        guard permissions.accessibilityGranted else {
            return .noDocument(.permissionMissing(.accessibility))
        }
        do {
            let snapshot = try await accessibility.snapshot(of: target)
            if target.bundleIdentifier == DocumentFinder.finderBundleIdentifier,
               snapshot?.selectedURLs.isEmpty ?? true {
                return await searchFinderSelection(in: target, at: moment)
            }
            guard let snapshot else {
                return .noDocument(.nothingInFront)
            }
            switch finder.find(in: snapshot) {
            case .success(let candidates):
                return .documentFound(candidates, at: moment)
            case .failure(.addressUnreadable) where automationMissing(for: target):
                return .noDocument(.browserAutomationMissing(browser: browserName(of: target)))
            case .failure(let reason):
                return .noDocument(reason)
            }
        } catch {
            logger.error("Document search failed unexpectedly: \(String(describing: error), privacy: .public)")
            return .noDocument(.unexpectedError)
        }
    }

    /// The Finder selection: Accessibility gave none, so Apple Events read it (Automation).
    private func searchFinderSelection(in target: ApplicationSnapshot, at moment: ReadingMoment) async -> ScreenReadingEvent {
        guard !permissions.browserAutomationMissing(bundleIdentifier: DocumentFinder.finderBundleIdentifier) else {
            return .noDocument(.permissionMissing(.finderAutomation))
        }
        guard let urls = await finderSelection.selectedURLs() else {
            logger.error("Finder selection could not be read through Apple Events")
            return .noDocument(.unexpectedError)
        }
        return documentEvent(DocumentFinder.finderDocuments(in: urls, source: target), at: moment)
    }

    private func documentEvent(_ result: Result<[DocumentCandidate], NoDocumentReason>, at moment: ReadingMoment) -> ScreenReadingEvent {
        switch result {
        case .success(let candidates):
            .documentFound(candidates, at: moment)
        case .failure(let reason):
            .noDocument(reason)
        }
    }

    /// Whether a browser whose address Accessibility does not show lacks the Automation permission that reads it.
    /// Firefox has no such Automation, so it never counts as missing.
    private func automationMissing(for target: ApplicationSnapshot) -> Bool {
        guard let bundle = target.bundleIdentifier,
              BrowserTabAutomation.bundleIdentifiers.contains(bundle) else {
            return false
        }
        return permissions.browserAutomationMissing(bundleIdentifier: bundle)
    }

    /// The name the user knows the browser by; the browser is always one whose Automation Axi reads.
    private func browserName(of target: ApplicationSnapshot) -> String {
        target.bundleIdentifier.flatMap(Permissions.automationBrowserName(bundleIdentifier:)) ?? target.name
    }

    /// Lettura del contesto, then Riconoscimento del testo when the app does not expose its text.
    private func readContext(of target: ApplicationSnapshot, at moment: ReadingMoment) async -> [ScreenReadingEvent] {
        var snapshot: AccessibilitySnapshot?
        if permissions.accessibilityGranted {
            do {
                snapshot = try await accessibility.snapshot(of: target)
            } catch {
                logger.error("Accessibility tree not read, the text is recognized on screen: \(String(describing: error), privacy: .public)")
            }
        }
        let document = (snapshot.flatMap { try? finder.find(in: $0).get() })?.first
        if let snapshot, let text = VisibleTextReader.text(in: snapshot.window) {
            let context = ScreenContext(
                application: target,
                windowTitle: snapshot.window.title,
                document: document,
                visibleText: text,
                textSource: .accessibility,
                moment: moment)
            return [.contextRead(context)]
        }
        let recognized = await recognizeOnScreen(
            of: target,
            document: document,
            windowTitle: snapshot?.window.title,
            moment: moment)
        return [.textNotAccessible, recognized]
    }

    /// Riconoscimento del testo: captures the window and reads its text.
    private func recognizeOnScreen(
        of target: ApplicationSnapshot,
        document: DocumentCandidate?,
        windowTitle: String?,
        moment: ReadingMoment
    ) async -> ScreenReadingEvent {
        guard permissions.screenRecordingGranted else {
            var missing: [Permissions.Permission] = [.screenRecording]
            if !permissions.accessibilityGranted { missing.append(.accessibility) }
            return .readingFailed(.permissionMissing(missing))
        }
        let image: CGImage
        do {
            image = try await capturer.capture(of: target)
        } catch {
            return .readingFailed(.captureFailed)
        }
        let recognizer = makeRecognizer()
        let text: String
        do {
            text = try await recognizer.recognizeText(in: image)
        } catch {
            return .readingFailed(.recognitionFailed)
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .readingFailed(.noText) }
        return .contextRead(ScreenContext(
            application: target,
            windowTitle: windowTitle,
            document: document,
            visibleText: trimmed,
            textSource: recognizer.source,
            moment: moment))
    }

    /// Records a refusal or a failure with its step, reason and app.
    private func log(_ event: ScreenReadingEvent, from target: ApplicationSnapshot) {
        switch event {
        case .noDocument(let reason):
            logger.notice("Document search refused: reason=\(String(describing: reason), privacy: .public) app=\(target.name, privacy: .public)")
        case .readingFailed(let failure):
            logger.error("Text reading failed: reason=\(String(describing: failure), privacy: .public) app=\(target.name, privacy: .public)")
        case .documentFound, .contextRead, .textNotAccessible:
            break
        }
    }

    private func acquire() async {
        if !busy {
            busy = true
            return
        }
        await withCheckedContinuation { waiting.append($0) }
    }

    private func release() {
        if waiting.isEmpty {
            busy = false
        } else {
            waiting.removeFirst().resume()
        }
    }
}
