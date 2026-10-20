import AxiScreen
import Testing
@testable import AxiCore

@Suite("Permessi Machine")
struct PermessiMachineTests {
    @Test("Window starts closed and opens with APRE_PERMESSI")
    func apreDaChiuse() {
        #expect(StatoPermessi.chiuse.dopo(.apriPermessi) == .aperte)
    }

    @Test("Opening an open window keeps it open")
    func apreDaAperte() {
        #expect(StatoPermessi.aperte.dopo(.apriPermessi) == .aperte)
    }

    @Test("CHIUDE_PERMESSI closes the window, and is a no-op when closed")
    func chiude() {
        #expect(StatoPermessi.aperte.dopo(.chiudePermessi) == .chiuse)
        #expect(StatoPermessi.chiuse.dopo(.chiudePermessi) == .chiuse)
    }

    @Test("CHIEDE_PERMESSO keeps the window open, and does nothing when closed")
    func chiede() {
        #expect(StatoPermessi.aperte.dopo(.chiedePermesso(.screenRecording)) == .aperte)
        #expect(StatoPermessi.chiuse.dopo(.chiedePermesso(.accessibility)) == .chiuse)
    }

    @Test("RIAPRE_AXI ends the run: the new run starts again from Controllo")
    func riapreAxi() {
        #expect(StatoPermessi.aperte.dopo(.riapreAxi) == .controllo)
        #expect(StatoPermessi.chiuse.dopo(.riapreAxi) == .chiuse)
    }

    @Test("Controllo ignores the utente Events: the window waits for the launch check")
    func controlloIgnoraUtente() {
        #expect(StatoPermessi.controllo.dopo(.apriPermessi) == .controllo)
        #expect(StatoPermessi.controllo.dopo(.chiudePermessi) == .controllo)
        #expect(StatoPermessi.controllo.dopo(.chiedePermesso(.accessibility)) == .controllo)
    }

    @Test("PERMESSI_MANCANTI at launch opens the window, and only from Controllo")
    func mancantiAllAvvio() {
        let mancanti = EventoPermessi.mancanti([.accessibility])
        #expect(StatoPermessi.controllo.dopo(mancanti) == .aperte)
        #expect(StatoPermessi.chiuse.dopo(mancanti) == .chiuse)
        #expect(StatoPermessi.aperte.dopo(mancanti) == .aperte)
    }

    @Test("PERMESSI_CONCESSI closes the window from any state, Controllo included")
    func concessi() {
        #expect(StatoPermessi.controllo.dopo(.concessi) == .chiuse)
        #expect(StatoPermessi.aperte.dopo(.concessi) == .chiuse)
        #expect(StatoPermessi.chiuse.dopo(.concessi) == .chiuse)
    }
}
