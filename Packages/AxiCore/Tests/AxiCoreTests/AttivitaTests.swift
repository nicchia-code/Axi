import AxiScreen
import Foundation
import Testing
@testable import AxiCore

@Suite("Attività Machine")
struct AttivitaTests {
    private let copia = URL(fileURLWithPath: "/tmp/vault/fattura.pdf")
    private var documento: DocumentoNelVault {
        DocumentoNelVault(titolo: "Fattura", tag: ["fisco"], allegatiNonPresi: ["logo.png"], copia: copia)
    }

    @Test("Starts idle, and PROSSIMO_DOCUMENTO starts the work with the queue count")
    func inizio() {
        var attivita = Attivita()
        #expect(attivita.stato == .nessuna)
        attivita.riceve(.prossimoDocumento(inCoda: 2, nome: "fattura.pdf"))
        #expect(attivita.stato == .inCorso)
        #expect(attivita.inCoda == 2)
        #expect(attivita.nomeInCorso == "fattura.pdf")
    }

    @Test("An outcome with documents still waiting keeps the work going")
    func esitoConCodaPiena() {
        var attivita = Attivita()
        attivita.riceve(.prossimoDocumento(inCoda: 1, nome: nil))
        attivita.riceve(.archiviato(documento, inCoda: 1))
        #expect(attivita.stato == .inCorso)
        #expect(attivita.nuvoletta == .archiviato(documento, nome: nil))
    }

    @Test("The outcome carries the origin name received with the document")
    func esitoConNomeDOrigine() {
        var attivita = Attivita()
        let documento = DocumentoNelVault(titolo: "Fattura", tag: [], allegatiNonPresi: [], copia: URL(fileURLWithPath: "/tmp/fattura.pdf"))
        attivita.riceve(.prossimoDocumento(inCoda: 0, nome: "fattura.pdf"))
        attivita.riceve(.archiviato(documento, inCoda: 0))
        #expect(attivita.nuvoletta == .archiviato(documento, nome: "fattura.pdf"))
        #expect(attivita.nomeInCorso == nil)
    }

    @Test("An outcome with an empty queue leads to Esito")
    func esitoConCodaVuota() {
        var attivita = Attivita()
        attivita.riceve(.prossimoDocumento(inCoda: 0, nome: nil))
        attivita.riceve(.nonArchiviato(.ompNonPronto, inCoda: 0))
        #expect(attivita.stato == .esito)
        #expect(attivita.nuvoletta == .nonArchiviato(.ompNonPronto, nome: nil))
    }

    @Test("A PDF of a web page that was not downloaded or is too large goes to Esito with its reason")
    func esitoPdfNonScaricato() {
        var attivita = Attivita()
        attivita.riceve(.prossimoDocumento(inCoda: 0, nome: nil))
        attivita.riceve(.nonArchiviato(.pdfNonScaricato, inCoda: 0))
        #expect(attivita.stato == .esito)
        #expect(attivita.nuvoletta == .nonArchiviato(.pdfNonScaricato, nome: nil))

        attivita.riceve(.prossimoDocumento(inCoda: 1, nome: nil))
        attivita.riceve(.nonArchiviato(.pdfTroppoGrande, inCoda: 1))
        #expect(attivita.stato == .inCorso)
        #expect(attivita.nuvoletta == .nonArchiviato(.pdfTroppoGrande, nome: nil))
    }

    @Test("Outcomes outside In corso change nothing")
    func esitiFuoriDaInCorso() {
        var attivita = Attivita()
        attivita.riceve(.archiviato(documento, inCoda: 0))
        #expect(attivita == Attivita())
    }

    @Test("An email archived without a receipt date keeps the mark in the bubble, also while In corso")
    func dataRicezioneSconosciutaRestaNellaNuvoletta() {
        let email = DocumentoNelVault(
            titolo: "Email", tag: [], allegatiNonPresi: [], copia: copia, dataRicezioneSconosciuta: true
        )
        var attivita = Attivita()
        attivita.riceve(.prossimoDocumento(inCoda: 1, nome: nil))
        attivita.riceve(.archiviato(email, inCoda: 1))
        #expect(attivita.stato == .inCorso)
        #expect(attivita.nuvoletta == .archiviato(email, nome: nil))
        #expect(email.dataRicezioneSconosciuta)
        #expect(!documento.dataRicezioneSconosciuta)
    }

    @Test("NESSUN_DOCUMENTO and NON_DISPONIBILE from idle or Esito lead to Esito")
    func spiegazioniDaNessunaEsito() {
        var attivita = Attivita()
        attivita.riceve(.nessunDocumento(.nothingInFront))
        #expect(attivita.stato == .esito)
        #expect(attivita.nuvoletta == .nessunDocumento(.nothingInFront))

        attivita.riceve(.chatNonDisponibile)
        #expect(attivita.stato == .esito)
        #expect(attivita.nuvoletta == .chatNonDisponibile)
    }

    @Test("NESSUN_DOCUMENTO and NON_DISPONIBILE from In corso stay In corso")
    func spiegazioniDaInCorso() {
        var attivita = Attivita()
        attivita.riceve(.prossimoDocumento(inCoda: 3, nome: nil))
        attivita.riceve(.nessunDocumento(.nothingInFront))
        #expect(attivita.stato == .inCorso)
        #expect(attivita.nuvoletta == .nessunDocumento(.nothingInFront))
        attivita.riceve(.chatNonDisponibile)
        #expect(attivita.stato == .inCorso)
        #expect(attivita.inCoda == 3)
    }

    @Test("NUVOLETTA_SCADUTA from Esito leads to Nessuna, and from In corso only hides the bubble")
    func scaduta() {
        var attivita = Attivita()
        attivita.riceve(.chatNonDisponibile)
        attivita.riceve(.nuvolettaScaduta)
        #expect(attivita.stato == .nessuna)
        #expect(attivita.nuvoletta == nil)

        attivita.riceve(.prossimoDocumento(inCoda: 1, nome: nil))
        #expect(attivita.nuvoletta == .archiviando(nome: nil))
        attivita.riceve(.nessunDocumento(.nothingInFront))
        attivita.riceve(.nuvolettaScaduta)
        #expect(attivita.stato == .inCorso)
        #expect(attivita.fase == .avvio)
        #expect(attivita.nuvoletta == .archiviando(nome: nil))
    }

    @Test("A click on the bubble from Esito leads to Nessuna and exposes the vault copy")
    func clic() {
        var attivita = Attivita()
        attivita.riceve(.prossimoDocumento(inCoda: 0, nome: nil))
        attivita.riceve(.archiviato(documento, inCoda: 0))
        #expect(attivita.nuvoletta?.copia == copia)
        attivita.riceve(.clicNuvoletta)
        #expect(attivita.stato == .nessuna)
        #expect(attivita.nuvoletta == nil)
    }

    @Test("PROSSIMO_DOCUMENTO from Esito starts the next document in Avvio, with its name in the bubble")
    func ripartenza() {
        var attivita = Attivita()
        attivita.riceve(.nessunDocumento(.nothingInFront))
        attivita.riceve(.prossimoDocumento(inCoda: 0, nome: "fattura.pdf"))
        #expect(attivita.stato == .inCorso)
        #expect(attivita.fase == .avvio)
        #expect(attivita.nuvoletta == .archiviando(nome: "fattura.pdf"))
        #expect(!attivita.nuvolettaScade)
        attivita.riceve(.nuvolettaScaduta)
        #expect(attivita.nuvoletta == .archiviando(nome: "fattura.pdf"))
    }

    @Test("An outcome with documents waiting stays in a passaggio, and when its time ends the next document starts in Avvio")
    func passaggioConNome() {
        var attivita = Attivita()
        attivita.riceve(.prossimoDocumento(inCoda: 1, nome: "a.pdf"))
        attivita.riceve(.archiviato(documento, inCoda: 1))
        #expect(attivita.fase == .passaggio)
        #expect(attivita.nuvoletta == .archiviato(documento, nome: "a.pdf"))
        #expect(attivita.nuvolettaScade)
        attivita.riceve(.prossimoDocumento(inCoda: 0, nome: "b.pdf"))
        #expect(attivita.nuvoletta == .archiviato(documento, nome: "a.pdf"))
        attivita.riceve(.nuvolettaScaduta)
        #expect(attivita.fase == .avvio)
        #expect(attivita.nuvoletta == .archiviando(nome: "b.pdf"))
        #expect(!attivita.nuvolettaScade)
    }

    @Test("A click on the start bubble closes it, and the outcome still shows in the bubble")
    func clicSulloAvvio() {
        var attivita = Attivita()
        attivita.riceve(.prossimoDocumento(inCoda: 0, nome: "a.pdf"))
        attivita.riceve(.clicNuvoletta)
        #expect(attivita.fase == .senzaNuvoletta)
        #expect(attivita.nuvoletta == nil)
        #expect(!attivita.nuvolettaScade)
        attivita.riceve(.archiviato(documento, inCoda: 0))
        #expect(attivita.stato == .esito)
        #expect(attivita.nuvoletta == .archiviato(documento, nome: "a.pdf"))
    }

    @Test("A click on an outcome in passaggio shows the start of the next document again")
    func clicInPassaggio() {
        var attivita = Attivita()
        attivita.riceve(.prossimoDocumento(inCoda: 1, nome: "a.pdf"))
        attivita.riceve(.archiviato(documento, inCoda: 1))
        attivita.riceve(.prossimoDocumento(inCoda: 0, nome: "b.pdf"))
        attivita.riceve(.clicNuvoletta)
        #expect(attivita.fase == .avvio)
        #expect(attivita.nuvoletta == .archiviando(nome: "b.pdf"))
    }

    @Test("A search whose bubble was closed starts its document without a bubble")
    func ricercaConNuvolettaChiusa() {
        var attivita = Attivita()
        attivita.riceve(.chiedeArchiviazione)
        attivita.riceve(.clicNuvoletta)
        #expect(attivita.stato == .inRicerca)
        #expect(attivita.nuvoletta == nil)
        attivita.riceve(.prossimoDocumento(inCoda: 0, nome: "a.pdf"))
        #expect(attivita.fase == .senzaNuvoletta)
        #expect(attivita.nuvoletta == nil)
        attivita.riceve(.archiviato(documento, inCoda: 0))
        #expect(attivita.nuvoletta == .archiviato(documento, nome: "a.pdf"))
    }

    @Test("A mini-chat notice during a search keeps the search going and leaves after its time")
    func chatInRicerca() {
        var attivita = Attivita()
        attivita.riceve(.chiedeArchiviazione)
        attivita.riceve(.chatNonDisponibile)
        #expect(attivita.stato == .inRicerca)
        #expect(attivita.nuvoletta == .chatNonDisponibile)
        #expect(attivita.nuvolettaScade)
        attivita.riceve(.nuvolettaScaduta)
        #expect(attivita.stato == .inRicerca)
        #expect(attivita.nuvoletta == .archiviando(nome: nil))
        #expect(!attivita.nuvolettaScade)
    }

    @Test("Already present documents open their copy and animate as already present")
    func giaPresente() {
        let nuvoletta = Nuvoletta.nonArchiviato(.giaPresente(copia: copia), nome: nil)
        #expect(nuvoletta.copia == copia)
        #expect(nuvoletta.esito == .giaPresente)
        #expect(Nuvoletta.nonArchiviato(.testoAssente, nome: nil).copia == nil)
        #expect(Nuvoletta.nonArchiviato(.testoAssente, nome: nil).esito == .errore)
        #expect(Nuvoletta.archiviato(documento, nome: nil).esito == .successo)
    }

    @Test("Every outcome bumps the counter, even when it repeats the previous one")
    func contatoreEsiti() {
        var attivita = Attivita()
        attivita.riceve(.prossimoDocumento(inCoda: 2, nome: nil))
        attivita.riceve(.nonArchiviato(.documentoIllegibile, inCoda: 1))
        let primo = attivita.nuvoletta
        attivita.riceve(.nonArchiviato(.documentoIllegibile, inCoda: 0))
        #expect(attivita.nuvoletta == primo)
        #expect(attivita.esiti == 2)
        attivita.riceve(.nessunDocumento(.nothingInFront))
        #expect(attivita.esiti == 3)
    }

    @Test("The metadata step shows only while In corso, and an outcome or its end clears it")
    func generazioneMetadati() {
        var attivita = Attivita()
        attivita.riceve(.generazioneMetadatiIniziata)
        #expect(!attivita.generandoMetadati)
        attivita.riceve(.prossimoDocumento(inCoda: 0, nome: nil))
        attivita.riceve(.generazioneMetadatiIniziata)
        #expect(attivita.generandoMetadati)
        attivita.riceve(.generazioneMetadatiFinita)
        #expect(!attivita.generandoMetadati)
        attivita.riceve(.generazioneMetadatiIniziata)
        attivita.riceve(.nonArchiviato(.aiNonRisponde, inCoda: 0))
        #expect(!attivita.generandoMetadati)
        #expect(attivita.stato == .esito)
    }

    @Test("A request is archiving from the request to the last outcome, with no wait for the metadata")
    func ricercaFinoAllEsito() {
        var attivita = Attivita()
        attivita.riceve(.chiedeArchiviazione)
        #expect(attivita.stato == .inRicerca)
        #expect(attivita.archiviando)
        attivita.riceve(.prossimoDocumento(inCoda: 0, nome: nil))
        #expect(attivita.stato == .inCorso)
        #expect(attivita.archiviando)
        attivita.riceve(.archiviato(documento, inCoda: 0))
        #expect(attivita.stato == .esito)
        #expect(!attivita.archiviando)
    }

    @Test("A search that finds nothing ends the archiving with an outcome")
    func ricercaSenzaDocumento() {
        var attivita = Attivita()
        attivita.riceve(.chiedeArchiviazione)
        attivita.riceve(.nessunDocumento(.nothingInFront))
        #expect(attivita.stato == .esito)
        #expect(!attivita.archiviando)
    }

    @Test("A refused search with another request waiting keeps the three dots and explains the refusal")
    func ricercaConAltraRichiesta() {
        var attivita = Attivita()
        attivita.riceve(.chiedeArchiviazione)
        attivita.riceve(.chiedeArchiviazione)
        attivita.riceve(.nessunDocumento(.nothingInFront, altreRichieste: true))
        #expect(attivita.stato == .inRicerca)
        #expect(attivita.archiviando)
        #expect(attivita.nuvoletta == .nessunDocumento(.nothingInFront))
        #expect(attivita.nuvolettaScade)
        attivita.riceve(.nuvolettaScaduta)
        #expect(attivita.nuvoletta == .archiviando(nome: nil))
        attivita.riceve(.nessunDocumento(.nothingInFront))
        #expect(attivita.stato == .esito)
        #expect(!attivita.archiviando)
    }
}
