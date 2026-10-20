import Foundation
import Testing
@testable import AxiCore

@Suite("Impronte e corrispondenze dell'archiviazione")
struct ArchiveFingerprintTests {
    @Test("Il SHA-256 di un contenuto è quello standard")
    func sha256OfKnownContent() {
        #expect(Fingerprint.sha256(Data("abc".utf8))
            == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    @Test("La stessa email con spazi e maiuscole diverse dà la stessa impronta")
    func emailFingerprintIgnoresSpacingAndCase() {
        let first = Fingerprint.email(sender: "Mario Rossi", receivedDay: "2025-10-06", subject: "Ciao", body: "Un  testo")
        let second = Fingerprint.email(sender: "mario rossi", receivedDay: "2025-10-06", subject: "CIAO", body: "un testo")

        #expect(first == second)
    }

    @Test("Un'email con corpo diverso dà un'impronta diversa")
    func emailFingerprintFollowsBody() {
        let first = Fingerprint.email(sender: "Mario", receivedDay: nil, subject: "Ciao", body: "uno")
        let second = Fingerprint.email(sender: "Mario", receivedDay: nil, subject: "Ciao", body: "due")

        #expect(first != second)
    }

    @Test("Il giorno di ricezione assoluto conta: due giorni diversi danno impronte diverse")
    func emailFingerprintFollowsReceiptDay() {
        let first = Fingerprint.email(sender: "Mario", receivedDay: "2025-10-06", subject: "Ciao", body: "uno")
        let second = Fingerprint.email(sender: "Mario", receivedDay: "2025-10-07", subject: "Ciao", body: "uno")

        #expect(first != second)
    }

    @Test("Il giorno di un istante dipende dal fuso orario in cui si legge")
    func receiptDayFollowsTimeZone() {
        // 23:30 UTC on 6 October 2025 is already 7 October in Rome (UTC+2).
        let instant = Date(timeIntervalSince1970: 1_759_793_400)
        #expect(Fingerprint.day(of: instant, in: TimeZone(identifier: "UTC")!) == "2025-10-06")
        #expect(Fingerprint.day(of: instant, in: TimeZone(identifier: "Europe/Rome")!) == "2025-10-07")
    }

    @Test("Una pagina è uguale alla PDF se almeno l'80% delle sue parole sta nel testo della PDF")
    func webPageMatchesAtThreshold() {
        let visible = "uno due tre quattro cinque"

        #expect(WebPageMatch.matches(visibleText: visible, pdfText: "uno due tre quattro altro"))
        #expect(!WebPageMatch.matches(visibleText: visible, pdfText: "uno due tre altro altro"))
    }

    @Test("Una pagina senza parole visibili non corrisponde a nulla")
    func emptyVisibleTextDoesNotMatch() {
        #expect(!WebPageMatch.matches(visibleText: "  ", pdfText: "uno due"))
    }
}

@Suite("Brani e stima dei token")
struct ArchiveChunkTests {
    @Test("Un brano non attraversa mai una pagina")
    func passagesKeepTheirPage() {
        let pages = [
            DocumentPage(number: 1, text: "prima pagina con alcune parole"),
            DocumentPage(number: 2, text: "seconda pagina"),
        ]

        let passages = Chunker.passages(of: pages)

        #expect(passages.contains { $0.page == 1 && $0.text.contains("prima") })
        #expect(passages.contains { $0.page == 2 && $0.text.contains("seconda") })
        #expect(passages.allSatisfy { $0.page == 1 || $0.page == 2 })
    }

    @Test("Un testo lungo si divide in brani non più grandi della finestra")
    func longTextIsSplit() {
        let words = (1...3000).map { "parola\($0)" }.joined(separator: " ")
        let limit = TokenEstimate.words(fitting: Chunker.targetTokens)

        let passages = Chunker.passages(of: [DocumentPage(number: 1, text: words)])

        #expect(passages.count > 1)
        #expect(passages.allSatisfy { TokenEstimate.wordCount($0.text) <= limit })
    }

    @Test("La stima dei token cresce con le parole")
    func tokenEstimateGrowsWithWords() {
        #expect(TokenEstimate.tokens("") == 0)
        #expect(TokenEstimate.tokens("uno due tre") == 4)
        #expect(TokenEstimate.words(fitting: 500) == 375)
    }
}

@Suite("Metadati del documento")
struct ArchiveMetadataTests {
    @Test("Una risposta JSON con testo intorno è letta")
    func parsesAnswerWrappedInText() throws {
        let reply = "Ecco la risposta: {\"title\": \" Fattura \", \"summary\": \"Riassunto.\", "
            + "\"tags\": [\"fattura\"], \"documentDate\": \"2025-10-06\", \"language\": \"it\"} Fine."

        let metadata = try #require(MetadataParser.parse(reply, reference: .archiving(Date())))

        #expect(metadata.title == "Fattura")
        #expect(metadata.summary == "Riassunto.")
        #expect(metadata.tags == ["fattura"])
        #expect(metadata.documentDate != nil)
        #expect(metadata.language == "it")
    }

    @Test("Il prompt chiede tag in minuscolo e al singolare, e il parser li mette in minuscolo")
    func tagsAreLowercaseSingularAndParsedLowercase() throws {
        let prompt = MetadataPrompts.whole(text: "testo", vocabulary: ["fattura"], language: "it", reference: .archiving(Date()))
        #expect(prompt.contains("lowercase"))
        #expect(prompt.contains("in the singular"))

        let reply = "{\"title\": \"Fattura\", \"summary\": \"Riassunto.\", \"tags\": [\"Fattura\", \"CONTRATTO\"]}"
        let metadata = try #require(MetadataParser.parse(reply, reference: .archiving(Date())))
        #expect(metadata.tags == ["fattura", "contratto"])
    }

    @Test("Una risposta senza JSON non dà metadati")
    func rejectsAnswerWithoutJSON() {
        #expect(MetadataParser.parse("Non so rispondere.", reference: .archiving(Date())) == nil)
    }

    @Test("Le date citate non valide si scartano, le altre restano")
    func dropsInvalidCitedDates() throws {
        let reply = """
        {"title": "Contratto", "summary": "Riassunto.", "tags": ["contratto"],
         "citedDates": [
           {"date": "2025-10-10", "about": "scadenza", "originalText": "entro il 10 ottobre"},
           {"date": "10 ottobre", "about": "scadenza", "originalText": "10 ottobre"},
           {"date": "2025-10-12T09:30:00+02:00", "about": "incontro", "originalText": "alle 9:30 di domenica"},
           {"date": "2025-10-12T09:30:00", "about": "senza offset", "originalText": "alle 9:30"},
           {"date": null, "about": "senza data", "originalText": "domani"}
         ]}
        """
        let metadata = try #require(MetadataParser.parse(reply, reference: .archiving(Date())))

        #expect(metadata.citedDates.count == 2)
        #expect(metadata.citedDates.first?.about == "scadenza")
        if case .day? = metadata.citedDates.first?.date {} else { Issue.record("La scadenza dovrebbe essere un giorno") }
        if case .instant? = metadata.citedDates.last?.date {} else { Issue.record("L'incontro dovrebbe avere l'ora") }
    }

    @Test("Una data senza giorno è ammessa solo per un'email con data di ricezione sconosciuta")
    func undatedCitedDateNeedsUnknownReceipt() throws {
        let reply = "{\"title\": \"Mail\", \"summary\": \"Riassunto.\", \"tags\": [\"mail\"], "
            + "\"citedDates\": [{\"date\": null, \"about\": \"riunione\", \"originalText\": \"domani\"}]}"

        let known = try #require(MetadataParser.parse(reply, reference: .receipt(Date())))
        #expect(known.citedDates.isEmpty)

        let unknown = try #require(MetadataParser.parse(reply, reference: .unknown))
        #expect(unknown.citedDates == [CitedDate(date: nil, about: "riunione", originalText: "domani")])
    }

    @Test("Una parte a sezioni non conta le date relative: le lascia senza data per la sintesi finale")
    func sectionLeavesRelativeDatesForTheFinalStep() throws {
        let section = Section(text: "Ci vediamo domani.", firstPage: 1, lastPage: 1)
        let prompt = MetadataPrompts.section(section, language: "it")
        #expect(!prompt.contains("documentDate"))

        let reply = "{\"summary\": \"Incontro domani.\", "
            + "\"citedDates\": [{\"date\": null, \"about\": \"incontro\", \"originalText\": \"domani\"}]}"
        let part = try #require(MetadataParser.parseSection(reply))
        #expect(part.citedDates == [CitedDate(date: nil, about: "incontro", originalText: "domani")])
    }

    @Test("La sintesi finale ha le date delle parti e risolve le relative dalla data del documento")
    func finalStepGetsSectionDates() {
        let dates = [CitedDate(date: nil, about: "incontro", originalText: "domani")]
        let prompt = MetadataPrompts.combined(
            summaries: ["Pagine 1-2: Incontro domani."], citedDates: dates, vocabulary: [], language: "it", reference: .archiving(Date())
        )
        #expect(prompt.contains("documentDate"))
        #expect(prompt.contains("original text: domani"))
        #expect(prompt.contains("\"citedDates\""))
    }

    @Test("Le date citate sono al massimo venti, senza doppioni")
    func capsCitedDates() {
        let items = (1...25).map { "{\"date\": \"2025-10-\(String(format: "%02d", $0))\", \"about\": \"a\", \"originalText\": \"t\"}" }
        let reply = "{\"title\": \"Agenda\", \"summary\": \"S.\", \"tags\": [\"agenda\"], \"citedDates\": [\(items.joined(separator: ","))]}"
        let metadata = MetadataParser.parse(reply, reference: .archiving(Date()))

        #expect(metadata?.citedDates.count == 20)
    }

    @Test("Una data impossibile non è accettata")
    func rejectsImpossibleDate() {
        #expect(MetadataParser.date("2025-02-30") == nil)
        #expect(MetadataParser.date("6 ottobre 2025") == nil)
        #expect(MetadataParser.date("2025-10-06") != nil)
    }

    @Test("Un documento corto va in un solo prompt, uno lungo a sezioni")
    func plansWholeOrSections() {
        let short = [DocumentPage(number: 1, text: "poche parole")]
        let long = (1...40).map { DocumentPage(number: $0, text: Array(repeating: "parola", count: 400).joined(separator: " ")) }

        if case .whole = MetadataPlanner.plan(pages: short, contextWindowTokens: 32_000) {} else {
            Issue.record("Il documento corto dovrebbe andare in un solo prompt")
        }
        if case .sections(let sections) = MetadataPlanner.plan(pages: long, contextWindowTokens: 4_000) {
            #expect(sections.count > 1)
            #expect(sections.first?.firstPage == 1)
            #expect(sections.last?.lastPage == 40)
        } else {
            Issue.record("Il documento lungo dovrebbe andare a sezioni")
        }
    }
}

@Suite("Lettura delle email .eml")
struct EmlParserTests {
    @Test("Il file di esempio dà mittente, oggetto e corpo")
    func parsesFixtureEmail() throws {
        let data = try Data(contentsOf: ArchiveFixtures.url("email.eml"))

        let email = try #require(EmlParser.parse(data))

        #expect(email.subject == "Riepilogo del progetto Axi")
        #expect(email.sender.contains("mario.rossi@example.com"))
        #expect(!email.body.isEmpty)
        #expect(email.sentAt != nil)
    }

    @Test("La data di un'email si legge nel formato delle intestazioni")
    func parsesEmailDate() {
        #expect(EmailDate.parse("Mon, 6 Oct 2025 09:30:00 +0200") != nil)
        #expect(EmailDate.parse("non una data") == nil)
    }
}
