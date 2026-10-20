import AxiScreen
import Testing
@testable import AxiCore

@Suite("Impostazioni Machine and shortcuts")
struct ImpostazioniMachineTests {
    @Test("Window starts closed and opens with APRE_IMPOSTAZIONI")
    func apreDaChiuse() {
        #expect(StatoImpostazioni.chiuse.dopo(.apreImpostazioni) == .aperte)
    }

    @Test("Opening an open window keeps it open")
    func apreDaAperte() {
        #expect(StatoImpostazioni.aperte.dopo(.apreImpostazioni) == .aperte)
    }

    @Test("CHIUDE_IMPOSTAZIONI closes the window, and is a no-op when closed")
    func chiude() {
        #expect(StatoImpostazioni.aperte.dopo(.chiudeImpostazioni) == .chiuse)
        #expect(StatoImpostazioni.chiuse.dopo(.chiudeImpostazioni) == .chiuse)
    }

    @Test("CHIEDE_PERMESSO keeps the window open, and RIAPRE_AXI closes it")
    func permessiERiapre() {
        #expect(StatoImpostazioni.aperte.dopo(.chiedePermesso(.screenRecording)) == .aperte)
        #expect(StatoImpostazioni.aperte.dopo(.riapreAxi) == .chiuse)
        #expect(StatoImpostazioni.chiuse.dopo(.riapreAxi) == .chiuse)
    }

    @Test("Archivia produces CHIEDE_ARCHIVIAZIONE")
    func archivia() {
        #expect(Scorciatoia.archivia.evento(chatAperta: false) == .chiedeArchiviazione)
        #expect(Scorciatoia.archivia.evento(chatAperta: true) == .chiedeArchiviazione)
    }

    @Test("Chat opens the closed chat and closes the open one")
    func chat() {
        #expect(Scorciatoia.chat.evento(chatAperta: false) == .apreChat)
        #expect(Scorciatoia.chat.evento(chatAperta: true) == .chiudeChat)
    }

    @Test("Each shortcut produces exactly one Event")
    func unEventoCiascuna() {
        #expect(Scorciatoia.allCases.count == 3)
    }
}
