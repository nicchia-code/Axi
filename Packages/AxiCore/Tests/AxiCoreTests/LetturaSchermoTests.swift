import AxiScreen
import CoreGraphics
import Foundation
import Testing
@testable import AxiCore

private let letturaEditor = ApplicationSnapshot(bundleIdentifier: "com.apple.TextEdit", name: "TextEdit", processIdentifier: 40)
private let letturaFile = URL(fileURLWithPath: "/tmp/lettura-schermo-test.pdf")
private let letturaMomento = ReadingMoment(date: Date(timeIntervalSince1970: 1_750_000_000), timeZone: TimeZone(identifier: "Europe/Rome")!)
private let letturaContesto = ScreenContext(
    application: letturaEditor,
    windowTitle: "Bolletta",
    document: nil,
    visibleText: "Totale 42 euro",
    textSource: .accessibility,
    moment: letturaMomento)

@Suite("Machine lettura-schermo")
struct LetturaSchermoMachineTests {
    @Test("CHIEDE_ARCHIVIAZIONE and APRE_CHAT from Inattiva start their reading; other Events change nothing")
    func startsOnlyTheReadings() {
        var macchina = LetturaSchermo()
        #expect(macchina.stato == .inattiva)
        let chiudeMenu = macchina.riceve(.chiudeMenu)
        #expect(!chiudeMenu)
        #expect(macchina.stato == .inattiva)
        let apertaChat = macchina.riceve(.apreChat)
        #expect(apertaChat)
        #expect(macchina.stato == .letturaDelContesto(.accessibilita))
    }

    @Test("CHIEDE_ARCHIVIAZIONE from Inattiva starts the search")
    func startsSearch() {
        var macchina = LetturaSchermo()
        let avviata = macchina.riceve(.chiedeArchiviazione)
        #expect(avviata)
        #expect(macchina.stato == .ricercaDelDocumento)
    }

    @Test("CONTESTO_LETTO from Accessibilità goes back to Inattiva with the context")
    func contextFromAccessibility() {
        var macchina = LetturaSchermo()
        _ = macchina.riceve(.apreChat)

        #expect(macchina.concludi(.contextRead(letturaContesto)) == .contestoLetto(letturaContesto))
        #expect(macchina.stato == .inattiva)
    }

    @Test("TESTO_NON_ACCESSIBILE moves to Riconoscimento del testo, which ends with CONTESTO_LETTO or LETTURA_FALLITA")
    func contextFromRecognition() {
        var macchina = LetturaSchermo()
        _ = macchina.riceve(.apreChat)
        #expect(macchina.concludi(.textNotAccessible) == nil)
        #expect(macchina.stato == .letturaDelContesto(.riconoscimentoDelTesto))
        #expect(macchina.concludi(.readingFailed(.recognitionFailed)) == .letturaFallita(.recognitionFailed))
        #expect(macchina.stato == .inattiva)

        _ = macchina.riceve(.apreChat)
        _ = macchina.concludi(.textNotAccessible)
        #expect(macchina.concludi(.contextRead(letturaContesto)) == .contestoLetto(letturaContesto))
        #expect(macchina.stato == .inattiva)
    }

    @Test("A failure in Accessibilità changes nothing")
    func failureInAccessibilityIgnored() {
        var macchina = LetturaSchermo()
        _ = macchina.riceve(.apreChat)
        #expect(macchina.concludi(.readingFailed(.captureFailed)) == nil)
        #expect(macchina.stato == .letturaDelContesto(.accessibilita))
    }

    @Test("A new request during the search changes nothing")
    func noSecondSearchWhileSearching() {
        var macchina = LetturaSchermo()
        _ = macchina.riceve(.chiedeArchiviazione)
        let seconda = macchina.riceve(.chiedeArchiviazione)
        #expect(!seconda)
        #expect(macchina.stato == .ricercaDelDocumento)
    }

    @Test("DOCUMENTO_INDIVIDUATO goes back to Inattiva with the document")
    func documentFound() {
        var macchina = LetturaSchermo()
        _ = macchina.riceve(.chiedeArchiviazione)
        let candidato = DocumentCandidate.file(FileDocument(url: letturaFile, source: letturaEditor))

        #expect(macchina.concludi(.documentFound([candidato], at: letturaMomento)) == .documentoIndividuato([candidato], letturaMomento))
        #expect(macchina.stato == .inattiva)
    }

    @Test("DOCUMENTO_INDIVIDUATO keeps every file of a Finder selection, in order")
    func documentsFoundInOrder() {
        var macchina = LetturaSchermo()
        _ = macchina.riceve(.chiedeArchiviazione)
        let primo = DocumentCandidate.file(FileDocument(url: letturaFile, source: letturaEditor))
        let secondo = DocumentCandidate.file(FileDocument(url: URL(fileURLWithPath: "/tmp/secondo.txt"), source: letturaEditor))

        #expect(macchina.concludi(.documentFound([primo, secondo], at: letturaMomento)) == .documentoIndividuato([primo, secondo], letturaMomento))
    }

    @Test("NESSUN_DOCUMENTO goes back to Inattiva")
    func noDocument() {
        var macchina = LetturaSchermo()
        _ = macchina.riceve(.chiedeArchiviazione)

        #expect(macchina.concludi(.noDocument(.nothingInFront)) == .nessunDocumento(.nothingInFront))
        #expect(macchina.stato == .inattiva)
    }

    @Test("Results of the chat reading and no search running emit nothing")
    func unrelatedResultsEmitNothing() {
        var macchina = LetturaSchermo()
        #expect(macchina.concludi(.noDocument(.nothingInFront)) == nil)
        #expect(macchina.stato == .inattiva)

        _ = macchina.riceve(.chiedeArchiviazione)
        #expect(macchina.concludi(.textNotAccessible) == nil)
        #expect(macchina.concludi(.readingFailed(.captureFailed)) == nil)
        #expect(macchina.stato == .ricercaDelDocumento)
    }
}

/// Accessibility that answers with a fixed snapshot per process.
private struct LetturaFakeAccessibility: AccessibilityReading {
    var snapshots: [Int32: AccessibilitySnapshot] = [:]
    func snapshot(of application: ApplicationSnapshot) async -> AccessibilitySnapshot? {
        snapshots[application.processIdentifier]
    }
    func perform(action: String, onElementNamed name: String, in application: ApplicationSnapshot) async -> Bool {
        false
    }
}

private struct LetturaFakePermissions: ScreenPermissions {
    var accessibilityGranted = true
    var screenRecordingGranted = true
    func browserAutomationMissing(bundleIdentifier: String) -> Bool {
        false
    }
}

private struct LetturaFakeCapturer: WindowCapturing {
    func capture(of application: ApplicationSnapshot) async throws -> CGImage {
        throw CocoaError(.fileReadUnknown)
    }
}

@MainActor
@Suite("Servizio lettura-schermo")
struct LetturaSchermoServiceTests {
    private func service(
        accessibility: LetturaFakeAccessibility = LetturaFakeAccessibility(),
        permissions: LetturaFakePermissions = LetturaFakePermissions()
    ) -> LetturaSchermoService {
        LetturaSchermoService(
            accessibility: accessibility,
            capturer: LetturaFakeCapturer(),
            permissions: permissions,
            makeRecognizer: { FailingRecognizer() },
            clock: { letturaMomento })
    }

    @Test("APRE_CHAT reads the visible text of the app in front and returns CONTESTO_LETTO")
    func contextFromFrontApplication() async {
        let window = AccessibilityNode(
            role: "AXWindow",
            title: "Bolletta",
            url: letturaFile,
            children: [AccessibilityNode(role: AccessibilityRole.staticText, value: "Totale 42 euro")])
        let snapshot = AccessibilitySnapshot(application: letturaEditor, window: window)
        let sut = service(accessibility: LetturaFakeAccessibility(snapshots: [40: snapshot]))
        var esiti = sut.esiti.makeAsyncIterator()

        let letto = await sut.leggeContesto(target: letturaEditor)

        let atteso = ScreenContext(
            application: letturaEditor,
            windowTitle: "Bolletta",
            document: .file(FileDocument(url: letturaFile, source: letturaEditor)),
            visibleText: "Totale 42 euro",
            textSource: .accessibility,
            moment: letturaMomento)
        #expect(letto == .contestoLetto(atteso))
        #expect(await esiti.next() == .contestoLetto(atteso))
    }

    @Test("A context reading that cannot read the screen returns LETTURA_FALLITA")
    func contextUnreadable() async {
        let sut = service(permissions: LetturaFakePermissions(accessibilityGranted: false))

        let letto = await sut.leggeContesto(target: letturaEditor)

        #expect(letto == .letturaFallita(.captureFailed))
    }

    @Test("A context reading without Screen Recording returns LETTURA_FALLITA naming the missing permissions")
    func contextWithoutScreenRecording() async {
        let sut = service(permissions: LetturaFakePermissions(accessibilityGranted: false, screenRecordingGranted: false))

        let letto = await sut.leggeContesto(target: letturaEditor)

        #expect(letto == .letturaFallita(.permissionMissing([.screenRecording, .accessibility])))
    }

    @Test("APRE_CHAT without an application in front starts nothing")
    func contextWithoutTarget() async {
        let sut = service()

        #expect(await sut.leggeContesto(target: nil) == nil)
    }

    @Test("Asking for the archiving searches the app in front and publishes the document")
    func documentFromFrontApplication() async {
        let snapshot = AccessibilitySnapshot(
            application: letturaEditor,
            window: AccessibilityNode(role: "AXWindow", url: letturaFile))
        let sut = service(accessibility: LetturaFakeAccessibility(snapshots: [40: snapshot]))
        var esiti = sut.esiti.makeAsyncIterator()

        sut.riceve(.chiedeArchiviazione, target: letturaEditor)

        #expect(await esiti.next() == .documentoIndividuato([.file(FileDocument(url: letturaFile, source: letturaEditor))], letturaMomento))
    }

    @Test("No document in the app in front publishes NESSUN_DOCUMENTO")
    func noDocumentInFrontApplication() async {
        let sut = service()
        var esiti = sut.esiti.makeAsyncIterator()

        sut.riceve(.chiedeArchiviazione, target: letturaEditor)

        #expect(await esiti.next() == .nessunDocumento(.nothingInFront))
    }

    @Test("Missing accessibility permission publishes NESSUN_DOCUMENTO")
    func withoutAccessibility() async {
        let sut = service(permissions: LetturaFakePermissions(accessibilityGranted: false))
        var esiti = sut.esiti.makeAsyncIterator()

        sut.riceve(.chiedeArchiviazione, target: letturaEditor)

        #expect(await esiti.next() == .nessunDocumento(.permissionMissing(.accessibility)))
    }

    @Test("No application in front publishes NESSUN_DOCUMENTO without reading the screen")
    func noTarget() async {
        let sut = service()
        var esiti = sut.esiti.makeAsyncIterator()

        sut.riceve(.chiedeArchiviazione, target: nil)

        #expect(await esiti.next() == .nessunDocumento(.nothingInFront))
    }

    @Test("Other Events do not start a search")
    func otherEventsIgnored() async {
        let sut = service()
        var esiti = sut.esiti.makeAsyncIterator()

        sut.riceve(.apreChat, target: letturaEditor)
        sut.riceve(.chiedeArchiviazione, target: nil)

        #expect(await esiti.next() == .nessunDocumento(.nothingInFront))
    }

    @Test("A search asked while another reading runs is served after it, in arrival order")
    func searchWaitsForReadingInProgress() async {
        let snapshot = AccessibilitySnapshot(
            application: letturaEditor,
            window: AccessibilityNode(role: "AXWindow", url: letturaFile))
        let sut = service(accessibility: LetturaFakeAccessibility(snapshots: [40: snapshot]))
        var esiti = sut.esiti.makeAsyncIterator()
        let altraApp = ApplicationSnapshot(bundleIdentifier: "com.apple.Safari", name: "Safari", processIdentifier: 41)

        sut.riceve(.chiedeArchiviazione, target: letturaEditor)
        sut.riceve(.chiedeArchiviazione, target: altraApp)

        #expect(await esiti.next() == .documentoIndividuato([.file(FileDocument(url: letturaFile, source: letturaEditor))], letturaMomento))
        #expect(await esiti.next() == .nessunDocumento(.nothingInFront))
    }

    @Test("A context request asked during a search waits for it and returns the context")
    func contextWaitsForSearchInProgress() async {
        let window = AccessibilityNode(
            role: "AXWindow",
            title: "Bolletta",
            url: letturaFile,
            children: [AccessibilityNode(role: AccessibilityRole.staticText, value: "Totale 42 euro")])
        let snapshot = AccessibilitySnapshot(application: letturaEditor, window: window)
        let sut = service(accessibility: LetturaFakeAccessibility(snapshots: [40: snapshot]))
        var esiti = sut.esiti.makeAsyncIterator()
        let documento = DocumentCandidate.file(FileDocument(url: letturaFile, source: letturaEditor))

        sut.riceve(.chiedeArchiviazione, target: letturaEditor)
        let letto = await sut.leggeContesto(target: letturaEditor)

        let atteso = ScreenContext(
            application: letturaEditor,
            windowTitle: "Bolletta",
            document: documento,
            visibleText: "Totale 42 euro",
            textSource: .accessibility,
            moment: letturaMomento)
        #expect(letto == .contestoLetto(atteso))
        #expect(await esiti.next() == .documentoIndividuato([documento], letturaMomento))
        #expect(await esiti.next() == .contestoLetto(atteso))
    }
}

/// Fails if asked to recognize text: the search never does OCR.
private struct FailingRecognizer: TextRecognizing {
    var source: TextSource { .vision }
    func recognizeText(in image: CGImage) async throws -> String {
        throw CocoaError(.fileReadUnknown)
    }
}
