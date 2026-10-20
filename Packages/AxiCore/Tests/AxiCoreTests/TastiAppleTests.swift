import Testing
@testable import AxiCore

@Suite("Apple keys Spotlight and Dictation")
struct TastiAppleTests {
    /// Builds the `data1` field of a system event: key code in the high 16 bits, key state and repeat flag below.
    private func data1(codice: Int, stato: Int, ripetizione: Bool = false) -> Int {
        (codice << 16) | (stato << 8) | (ripetizione ? 1 : 0)
    }

    @Test("Spotlight opens the chat when closed and closes it when open; Dictation asks for archiving")
    func evento() {
        #expect(TastoApple.spotlight.evento(chatAperta: false) == .apreChat)
        #expect(TastoApple.spotlight.evento(chatAperta: true) == .chiudeChat)
        #expect(TastoApple.dettatura.evento(chatAperta: false) == .chiedeArchiviazione)
        #expect(TastoApple.dettatura.evento(chatAperta: true) == .chiedeArchiviazione)
    }

    @Test("A system event is decoded into its key code and key state")
    func decodificaTastoSistema() {
        let giu = TastoSistema(data1: data1(codice: 0x0042, stato: 0x0A))
        #expect(giu.codice == 0x0042)
        #expect(giu.fase == .premuto)

        let ripetuto = TastoSistema(data1: data1(codice: 0x0042, stato: 0x0A, ripetizione: true))
        #expect(ripetuto.fase == .ripetuto)

        let su = TastoSistema(data1: data1(codice: 0x0042, stato: 0x0B))
        #expect(su.fase == .rilasciato)

        let altro = TastoSistema(data1: data1(codice: 0x0042, stato: 0x00))
        #expect(altro.fase == .altro)
    }

    @Test("The shipped codes are unverified: nothing is matched and the tap is never complete")
    func codiciNonVerificati() {
        let codici = CodiciTastiApple.predefiniti
        #expect(codici.completi == false)
        for codice in [Int32(0), 1, 0x0001, 0x00CF] {
            #expect(codici.riconosci(codice: codice) == nil)
        }
    }

    @Test("Codes that are set are matched to their key only when both are set")
    func codiciImpostati() {
        let completi = CodiciTastiApple(spotlight: 0x1234, dettatura: 0x5678)
        #expect(completi.completi)
        #expect(completi.riconosci(codice: 0x1234) == .spotlight)
        #expect(completi.riconosci(codice: 0x5678) == .dettatura)
        #expect(completi.riconosci(codice: 0x0001) == nil)

        let parziali = CodiciTastiApple(spotlight: 0x1234, dettatura: nil)
        #expect(parziali.completi == false)
        #expect(parziali.riconosci(codice: 0x1234) == .spotlight)
    }

    @Test("One action per press: the press stores the app, the release produces the key's action")
    func unaAzionePerPressione() {
        var sequenza = SequenzaTastiApple()
        #expect(sequenza.gestisci(tasto: .spotlight, fase: .premuto) == .premi)
        #expect(sequenza.gestisci(tasto: .spotlight, fase: .ripetuto) == .ignora)
        #expect(sequenza.gestisci(tasto: .spotlight, fase: .ripetuto) == .ignora)
        #expect(sequenza.gestisci(tasto: .spotlight, fase: .rilasciato) == .rilascia(.spotlight))
    }

    @Test("A release without a press, or a release of the other key, does nothing")
    func rilasciiSenzaPremuta() {
        var sequenza = SequenzaTastiApple()
        #expect(sequenza.gestisci(tasto: .dettatura, fase: .rilasciato) == .ignora)
        #expect(sequenza.gestisci(tasto: .dettatura, fase: .premuto) == .premi)
        #expect(sequenza.gestisci(tasto: .spotlight, fase: .rilasciato) == .ignora)
        #expect(sequenza.gestisci(tasto: .dettatura, fase: .rilasciato) == .rilascia(.dettatura))
    }

    @Test("Cancelling a press in progress makes its release do nothing")
    func annulla() {
        var sequenza = SequenzaTastiApple()
        #expect(sequenza.gestisci(tasto: .dettatura, fase: .premuto) == .premi)
        sequenza.annulla()
        #expect(sequenza.gestisci(tasto: .dettatura, fase: .rilasciato) == .ignora)
    }
}
