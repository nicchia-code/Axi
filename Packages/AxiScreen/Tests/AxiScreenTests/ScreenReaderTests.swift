import CoreGraphics
import Foundation
import Testing
@testable import AxiScreen

private let editor = ApplicationSnapshot(bundleIdentifier: "com.apple.TextEdit", name: "TextEdit", processIdentifier: 20)
private let outlookApp = ApplicationSnapshot(bundleIdentifier: "com.microsoft.Outlook", name: "Outlook", processIdentifier: 21)
private let momentoLettura = ReadingMoment(date: Date(timeIntervalSince1970: 1_750_000_000), timeZone: TimeZone(identifier: "Europe/Rome")!)

private struct FakePermissions: ScreenPermissions {
    var accessibilityGranted = true
    var screenRecordingGranted = true
    var automationMissing = false
    func browserAutomationMissing(bundleIdentifier: String) -> Bool {
        automationMissing
    }
}

private struct FakeFailure: Error {}

private struct FakeAccessibility: AccessibilityReading {
    var snapshots: [Int32: AccessibilitySnapshot] = [:]
    var failure: Error?
    func snapshot(of application: ApplicationSnapshot) async throws -> AccessibilitySnapshot? {
        if let failure { throw failure }
        return snapshots[application.processIdentifier]
    }
    func perform(action: String, onElementNamed name: String, in application: ApplicationSnapshot) async -> Bool {
        false
    }
}

private struct FakeCapturer: WindowCapturing {
    var fails = false
    func capture(of application: ApplicationSnapshot) async throws -> CGImage {
        if fails { throw CocoaError(.fileReadUnknown) }
        return try makeImage()
    }
}

private struct FakeRecognizer: TextRecognizing {
    var source: TextSource = .vision
    var result: Result<String, Error> = .success("testo riconosciuto")
    func recognizeText(in image: CGImage) async throws -> String {
        try result.get()
    }
}

private struct FakeFinderSelection: FinderSelectionReading {
    var urls: [URL]? = nil
    func selectedURLs() async -> [URL]? {
        urls
    }
}

/// Collects the events emitted by a reader.
private final class EventLog: @unchecked Sendable {
    private let lock = NSLock()
    private var events: [ScreenReadingEvent] = []
    func append(_ event: ScreenReadingEvent) {
        lock.lock()
        defer { lock.unlock() }
        events.append(event)
    }
    var all: [ScreenReadingEvent] {
        lock.lock()
        defer { lock.unlock() }
        return events
    }
}

private func makeImage() throws -> CGImage {
    let context = try #require(CGContext(
        data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    return try #require(context.makeImage())
}

private func reader(
    accessibility: FakeAccessibility = FakeAccessibility(),
    permissions: FakePermissions = FakePermissions(),
    finderSelection: FakeFinderSelection = FakeFinderSelection(),
    capturer: FakeCapturer = FakeCapturer(),
    recognizer: FakeRecognizer = FakeRecognizer(),
    moment: ReadingMoment = momentoLettura,
    log: EventLog
) -> ScreenReader {
    ScreenReader(
        accessibility: accessibility,
        capturer: capturer,
        permissions: permissions,
        finderSelection: finderSelection,
        makeRecognizer: { recognizer },
        clock: { moment },
        emit: { log.append($0) })
}

private let textEditWithText = AccessibilitySnapshot(
    application: editor,
    window: AccessibilityNode(role: "AXWindow", title: "Note", children: [
        AccessibilityNode(role: AccessibilityRole.textArea, value: "Riga uno\nRiga due"),
    ]))

@Test func archivingFindsDocumentInFrontWindow() async throws {
    let file = URL(fileURLWithPath: "/tmp/a.pdf")
    let snapshot = AccessibilitySnapshot(application: editor, window: AccessibilityNode(role: "AXWindow", url: file))
    let log = EventLog()
    let sut = reader(accessibility: FakeAccessibility(snapshots: [20: snapshot]), log: log)

    await sut.handle(ReadingRequest(purpose: .archiving, target: editor))

    #expect(log.all == [.documentFound([.file(FileDocument(url: file, source: editor))], at: momentoLettura)])
}

@Test func archivingWithoutDocumentEmitsNoDocument() async throws {
    let log = EventLog()
    await reader(log: log).handle(ReadingRequest(purpose: .archiving, target: editor))
    #expect(log.all == [.noDocument(.nothingInFront)])
}

@Test func archivingWithoutAccessibilityEmitsNoDocument() async throws {
    let log = EventLog()
    let sut = reader(
        accessibility: FakeAccessibility(snapshots: [20: textEditWithText]),
        permissions: FakePermissions(accessibilityGranted: false),
        log: log)
    await sut.handle(ReadingRequest(purpose: .archiving, target: editor))
    #expect(log.all == [.noDocument(.permissionMissing(.accessibility))])
}

@Test func archivingWithUnreadableSafariAddressWithoutAutomationAsksForAutomation() async throws {
    let safari = ApplicationSnapshot(bundleIdentifier: "com.apple.Safari", name: "Safari", processIdentifier: 30)
    let window = AccessibilitySnapshot(application: safari, window: AccessibilityNode(role: "AXWindow", title: "Pagina"))
    let log = EventLog()
    let sut = reader(
        accessibility: FakeAccessibility(snapshots: [30: window]),
        permissions: FakePermissions(automationMissing: true),
        log: log)
    await sut.handle(ReadingRequest(purpose: .archiving, target: safari))
    #expect(log.all == [.noDocument(.browserAutomationMissing(browser: "Safari"))])
}

@Test func archivingWithUnreadableChromeAddressNamesChromeWithoutAutomation() async throws {
    let chrome = ApplicationSnapshot(bundleIdentifier: "com.google.Chrome", name: "Google Chrome", processIdentifier: 33)
    let window = AccessibilitySnapshot(application: chrome, window: AccessibilityNode(role: "AXWindow", title: "Pagina"))
    let log = EventLog()
    let sut = reader(
        accessibility: FakeAccessibility(snapshots: [33: window]),
        permissions: FakePermissions(automationMissing: true),
        log: log)
    await sut.handle(ReadingRequest(purpose: .archiving, target: chrome))
    #expect(log.all == [.noDocument(.browserAutomationMissing(browser: "Chrome"))])
}

@Test func archivingWithUnreadableSafariAddressWithAutomationReportsAddressUnreadable() async throws {
    let safari = ApplicationSnapshot(bundleIdentifier: "com.apple.Safari", name: "Safari", processIdentifier: 30)
    let window = AccessibilitySnapshot(application: safari, window: AccessibilityNode(role: "AXWindow", title: "Pagina"))
    let log = EventLog()
    let sut = reader(
        accessibility: FakeAccessibility(snapshots: [30: window]),
        permissions: FakePermissions(automationMissing: false),
        log: log)
    await sut.handle(ReadingRequest(purpose: .archiving, target: safari))
    #expect(log.all == [.noDocument(.addressUnreadable)])
}

private let finder = ApplicationSnapshot(bundleIdentifier: "com.apple.finder", name: "Finder", processIdentifier: 40)

@Test func archivingReadsFinderSelectionThroughAccessibilityFirst() async throws {
    let first = URL(fileURLWithPath: "/tmp/t26-primo.pdf")
    let second = URL(fileURLWithPath: "/tmp/t26-secondo.txt")
    let snapshot = AccessibilitySnapshot(application: finder, window: AccessibilityNode(role: "AXWindow", title: "Scrivania", selectedURLs: [first, second]))
    let log = EventLog()
    let sut = reader(
        accessibility: FakeAccessibility(snapshots: [40: snapshot]),
        finderSelection: FakeFinderSelection(urls: [URL(fileURLWithPath: "/tmp/t26-automazione.pdf")]),
        log: log)
    await sut.handle(ReadingRequest(purpose: .archiving, target: finder))
    #expect(log.all == [.documentFound([
        .file(FileDocument(url: first, source: finder)),
        .file(FileDocument(url: second, source: finder)),
    ], at: momentoLettura)])
}

@Test func archivingReadsFinderSelectionThroughAutomationWhenAccessibilityGivesNone() async throws {
    let picked = URL(fileURLWithPath: "/tmp/t26-automazione.pdf")
    let log = EventLog()
    let sut = reader(finderSelection: FakeFinderSelection(urls: [picked]), log: log)
    await sut.handle(ReadingRequest(purpose: .archiving, target: finder))
    #expect(log.all == [.documentFound([.file(FileDocument(url: picked, source: finder))], at: momentoLettura)])
}

@Test func archivingFinderFolderSelectionFindsNothingWithoutAutomation() async throws {
    let folder = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    let snapshot = AccessibilitySnapshot(application: finder, window: AccessibilityNode(role: "AXWindow", title: "Scrivania", selectedURLs: [folder]))
    let log = EventLog()
    let sut = reader(
        accessibility: FakeAccessibility(snapshots: [40: snapshot]),
        finderSelection: FakeFinderSelection(urls: [URL(fileURLWithPath: "/tmp/t26-automazione.pdf")]),
        log: log)
    await sut.handle(ReadingRequest(purpose: .archiving, target: finder))
    #expect(log.all == [.noDocument(.nothingInFront)])
}

@Test func archivingFinderSelectionWithoutAutomationAsksForFinderAutomation() async throws {
    let log = EventLog()
    let sut = reader(
        permissions: FakePermissions(automationMissing: true),
        finderSelection: FakeFinderSelection(urls: [URL(fileURLWithPath: "/tmp/t26-automazione.pdf")]),
        log: log)
    await sut.handle(ReadingRequest(purpose: .archiving, target: finder))
    #expect(log.all == [.noDocument(.permissionMissing(.finderAutomation))])
}

@Test func archivingFinderSelectionUnreadableThroughAutomationEmitsUnexpectedError() async throws {
    let log = EventLog()
    let sut = reader(finderSelection: FakeFinderSelection(urls: nil), log: log)
    await sut.handle(ReadingRequest(purpose: .archiving, target: finder))
    #expect(log.all == [.noDocument(.unexpectedError)])
}

@Test func archivingWithUnreadableFirefoxAddressReportsAddressUnreadable() async throws {
    let firefox = ApplicationSnapshot(bundleIdentifier: "org.mozilla.firefox", name: "Firefox", processIdentifier: 31)
    let window = AccessibilitySnapshot(application: firefox, window: AccessibilityNode(role: "AXWindow", title: "Pagina"))
    let log = EventLog()
    let sut = reader(
        accessibility: FakeAccessibility(snapshots: [31: window]),
        permissions: FakePermissions(automationMissing: true),
        log: log)
    await sut.handle(ReadingRequest(purpose: .archiving, target: firefox))
    #expect(log.all == [.noDocument(.addressUnreadable)])
}

@Test func archivingWhenAccessibilityTreeFailsEmitsUnexpectedError() async throws {
    let log = EventLog()
    let sut = reader(accessibility: FakeAccessibility(failure: FakeFailure()), log: log)
    await sut.handle(ReadingRequest(purpose: .archiving, target: editor))
    #expect(log.all == [.noDocument(.unexpectedError)])
}

@Test func chatReadsContextFromAccessibilityWithoutOCR() async throws {
    let log = EventLog()
    let sut = reader(accessibility: FakeAccessibility(snapshots: [20: textEditWithText]), log: log)

    await sut.handle(ReadingRequest(purpose: .chat, target: editor))

    #expect(log.all == [.contextRead(ScreenContext(
        application: editor,
        windowTitle: "Note",
        document: nil,
        visibleText: "Riga uno\nRiga due",
        textSource: .accessibility,
        moment: momentoLettura))])
}

@Test func chatFallsBackToTextRecognitionWhenTextNotAccessible() async throws {
    let emptyWindow = AccessibilitySnapshot(
        application: editor,
        window: AccessibilityNode(role: "AXWindow", title: "Scansione"))
    let log = EventLog()
    let sut = reader(
        accessibility: FakeAccessibility(snapshots: [20: emptyWindow]),
        recognizer: FakeRecognizer(source: .azure, result: .success("  Testo dallo schermo \n")),
        log: log)

    await sut.handle(ReadingRequest(purpose: .chat, target: editor))

    #expect(log.all == [
        .textNotAccessible,
        .contextRead(ScreenContext(
            application: editor,
            windowTitle: "Scansione",
            document: nil,
            visibleText: "Testo dallo schermo",
            textSource: .azure,
            moment: momentoLettura)),
    ])
}

@Test func missingScreenRecordingPermissionFailsReading() async throws {
    let log = EventLog()
    let sut = reader(
        permissions: FakePermissions(screenRecordingGranted: false),
        log: log)
    await sut.handle(ReadingRequest(purpose: .chat, target: editor))
    #expect(log.all == [.textNotAccessible, .readingFailed(.permissionMissing([.screenRecording]))])
}

@Test func missingScreenRecordingAndAccessibilityFailsReadingNamingBoth() async throws {
    let log = EventLog()
    let sut = reader(
        permissions: FakePermissions(accessibilityGranted: false, screenRecordingGranted: false),
        log: log)
    await sut.handle(ReadingRequest(purpose: .chat, target: editor))
    #expect(log.all == [.textNotAccessible, .readingFailed(.permissionMissing([.screenRecording, .accessibility]))])
}

@Test func missingAccessibilityWithScreenRecordingStillRecognizesTheText() async throws {
    let log = EventLog()
    let sut = reader(
        permissions: FakePermissions(accessibilityGranted: false),
        recognizer: FakeRecognizer(source: .vision, result: .success("Testo dallo schermo")),
        log: log)
    await sut.handle(ReadingRequest(purpose: .chat, target: editor))
    #expect(log.all == [
        .textNotAccessible,
        .contextRead(ScreenContext(
            application: editor,
            windowTitle: nil,
            document: nil,
            visibleText: "Testo dallo schermo",
            textSource: .vision,
            moment: momentoLettura)),
    ])
}

@Test func captureErrorFailsReading() async throws {
    let log = EventLog()
    await reader(capturer: FakeCapturer(fails: true), log: log).handle(ReadingRequest(purpose: .chat, target: editor))
    #expect(log.all == [.textNotAccessible, .readingFailed(.captureFailed)])
}

@Test func recognitionErrorFailsReading() async throws {
    let log = EventLog()
    let sut = reader(recognizer: FakeRecognizer(result: .failure(CocoaError(.fileReadUnknown))), log: log)
    await sut.handle(ReadingRequest(purpose: .chat, target: editor))
    #expect(log.all == [.textNotAccessible, .readingFailed(.recognitionFailed)])
}

@Test func emptyRecognitionFailsReading() async throws {
    let log = EventLog()
    let sut = reader(recognizer: FakeRecognizer(result: .success("   ")), log: log)
    await sut.handle(ReadingRequest(purpose: .chat, target: editor))
    #expect(log.all == [.textNotAccessible, .readingFailed(.noText)])
}

@Test func concurrentRequestsAreAllServedOneAtATime() async throws {
    let log = EventLog()
    let sut = reader(accessibility: FakeAccessibility(snapshots: [20: textEditWithText]), log: log)
    let context = ScreenEventKindCheck.context

    async let a: Void = sut.handle(ReadingRequest(purpose: .chat, target: editor))
    async let b: Void = sut.handle(ReadingRequest(purpose: .archiving, target: outlookApp))
    _ = await (a, b)

    // Each request emits its own events, so the two results never interleave within one reading.
    #expect(log.all.count == 2)
    #expect(log.all.contains(context))
    #expect(log.all.contains(.noDocument(.nothingInFront)))
}

private enum ScreenEventKindCheck {
    static let context = ScreenReadingEvent.contextRead(ScreenContext(
        application: editor,
        windowTitle: "Note",
        document: nil,
        visibleText: "Riga uno\nRiga due",
        textSource: .accessibility,
        moment: momentoLettura))
}

private final class MomentSource: @unchecked Sendable {
    private let lock = NSLock()
    private var moments: [ReadingMoment]
    init(_ moments: [ReadingMoment]) {
        self.moments = moments
    }
    func next() -> ReadingMoment {
        lock.lock()
        defer { lock.unlock() }
        return moments.removeFirst()
    }
}

private func moment(of event: ScreenReadingEvent) -> ReadingMoment? {
    if case .contextRead(let context) = event { return context.moment }
    return nil
}

@Test func eachReadingRecordsTheMomentWhereItStarts() async throws {
    let first = momentoLettura
    let second = ReadingMoment(date: Date(timeIntervalSince1970: 1_750_003_600), timeZone: TimeZone(identifier: "America/New_York")!)
    let source = MomentSource([first, second])
    let log = EventLog()
    let sut = ScreenReader(
        accessibility: FakeAccessibility(snapshots: [20: textEditWithText]),
        capturer: FakeCapturer(),
        permissions: FakePermissions(),
        finderSelection: FakeFinderSelection(),
        makeRecognizer: { FakeRecognizer() },
        clock: { source.next() },
        emit: { log.append($0) })

    await sut.handle(ReadingRequest(purpose: .chat, target: editor))
    await sut.handle(ReadingRequest(purpose: .chat, target: editor))

    #expect(log.all.count == 2)
    #expect(log.all.compactMap(moment(of:)) == [first, second])
}
