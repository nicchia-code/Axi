import Foundation
import Testing
@testable import AxiCore

@Suite("Puntino Machine, menu and position")
struct PuntinoTests {
    @Test("Click on the resting dot opens the menu, and the menu closes with CHIUDE_MENU, APRE_IMPOSTAZIONI or CHIEDE_ARCHIVIAZIONE; a click on the open menu's dot has no effect")
    func menu() {
        #expect(StatoPuntino.aRiposo.dopo(.clicPuntino) == .menuAperto)
        #expect(StatoPuntino.menuAperto.dopo(.chiudeMenu) == .aRiposo)
        #expect(StatoPuntino.menuAperto.dopo(.apreImpostazioni) == .aRiposo)
        #expect(StatoPuntino.menuAperto.dopo(.chiedeArchiviazione) == .aRiposo)
        #expect(StatoPuntino.menuAperto.dopo(.clicPuntino) == .menuAperto)
    }

    @Test("The archive shortcut's Event closes the open menu and the dot returns to rest")
    func archiveShortcutClosesMenu() {
        let evento = Scorciatoia.archivia.evento(chatAperta: false)
        #expect(StatoPuntino.menuAperto.dopo(evento) == .aRiposo)
    }

    @Test("Chat expands the dot from resting and menu, and closing returns to resting")
    func chat() {
        #expect(StatoPuntino.aRiposo.dopoChat(aperta: true) == .espanso)
        #expect(StatoPuntino.menuAperto.dopoChat(aperta: true) == .espanso)
        #expect(StatoPuntino.espanso.dopoChat(aperta: false) == .aRiposo)
        #expect(StatoPuntino.aRiposo.dopoChat(aperta: false) == .aRiposo)
    }

    @Test("The radial menu has five items in the order of the Task, and only Esci has no Event")
    func voci() {
        #expect(VoceMenu.allCases == [.archivia, .chat, .impostazioni, .nascondi, .esci])
        #expect(VoceMenu.archivia.evento(chatAperta: false) == .chiedeArchiviazione)
        #expect(VoceMenu.chat.evento(chatAperta: false) == .apreChat)
        #expect(VoceMenu.chat.evento(chatAperta: true) == .chiudeChat)
        #expect(VoceMenu.impostazioni.evento(chatAperta: false) == .apreImpostazioni)
        #expect(VoceMenu.esci.evento(chatAperta: false) == nil)
        #expect(VoceMenu.nascondi.evento(chatAperta: false) == .alternaPuntino)
    }

    @Test("The menu bar menu lists Archivia, Chat, Settings and Quit after Mostra, in that order")
    func ordineBarra() {
        #expect(vociBarra == [.archivia, .chat, .impostazioni, .esci])
    }

    @Test("Shortcut items share their shortcut's Event")
    func scorciatoie() {
        for voce in VoceMenu.allCases {
            if let scorciatoia = voce.scorciatoia {
                #expect(voce.evento(chatAperta: false) == scorciatoia.evento(chatAperta: false))
            }
        }
        #expect(VoceMenu.impostazioni.scorciatoia == nil)
        #expect(VoceMenu.esci.scorciatoia == nil)
    }

    @Test("With the Spotlight and Dictation keys Axi's, Archivia shows the microphone and Chat the lens; otherwise no symbol, so the shortcut shows")
    func simboliTasti() {
        #expect(VoceMenu.archivia.simboloTasto(tastiAxi: true) == "mic")
        #expect(VoceMenu.chat.simboloTasto(tastiAxi: true) == "magnifyingglass")
        #expect(VoceMenu.archivia.simboloTasto(tastiAxi: false) == nil)
        #expect(VoceMenu.chat.simboloTasto(tastiAxi: false) == nil)
        #expect(VoceMenu.impostazioni.simboloTasto(tastiAxi: true) == nil)
        #expect(VoceMenu.esci.simboloTasto(tastiAxi: true) == nil)
    }

    @Test("The saved position survives a round trip, and a missing file gives nil")
    func posizione() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = PuntinoStore(fileURL: directory.appending(path: "puntino.json"))
        #expect(store.load() == nil)

        let salvata = PosizionePuntino(x: 1200.5, y: 80, schermo: 3, nascosto: true)
        try store.save(salvata)
        #expect(store.load() == salvata)
    }

    @Test("A saved position written before the hidden flag existed loads as visible")
    func posizioneSenzaNascosto() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appending(path: "puntino.json")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data(#"{"x":10,"y":20,"schermo":3}"#.utf8).write(to: file)
        #expect(PuntinoStore(fileURL: file).load() == PosizionePuntino(x: 10, y: 20, schermo: 3, nascosto: false))
    }

    @Test("With the dot hidden in the menu bar, the chat opens under the icon and closing returns to the icon at rest; a click on the icon has no Transition")
    func chatSottoBarra() {
        #expect(StatoPuntino.nellaBarra.dopoChat(aperta: true) == .chatSottoBarra)
        #expect(StatoPuntino.chatSottoBarra.dopoChat(aperta: false) == .nellaBarra)
        #expect(StatoPuntino.nellaBarra.dopoChat(aperta: false) == .nellaBarra)
        #expect(StatoPuntino.chatSottoBarra.dopoChat(aperta: true) == .chatSottoBarra)
        #expect(StatoPuntino.chatSottoBarra.dopo(.clicPuntino) == .chatSottoBarra)
    }

    @Test("The hidden states, menu bar menu included, are flagged as the dot living in the menu bar")
    func nascosto() {
        #expect(StatoPuntino.nellaBarra.nascosto)
        #expect(StatoPuntino.menuBarra.nascosto)
        #expect(StatoPuntino.chatSottoBarra.nascosto)
        #expect(!StatoPuntino.aRiposo.nascosto)
        #expect(!StatoPuntino.menuAperto.nascosto)
        #expect(!StatoPuntino.espanso.nascosto)
    }

    @Test("Hide and show alternate from resting, menu, chat and the menu bar, as the Model says")
    func alternaPuntino() {
        #expect(StatoPuntino.aRiposo.dopo(.alternaPuntino) == .nellaBarra)
        #expect(StatoPuntino.menuAperto.dopo(.alternaPuntino) == .nellaBarra)
        #expect(StatoPuntino.espanso.dopo(.alternaPuntino) == .chatSottoBarra)
        #expect(StatoPuntino.nellaBarra.dopo(.alternaPuntino) == .aRiposo)
        #expect(StatoPuntino.menuBarra.dopo(.alternaPuntino) == .aRiposo)
        #expect(StatoPuntino.chatSottoBarra.dopo(.alternaPuntino) == .espanso)
    }

    @Test("A click on the icon opens the menu bar menu; its menu closing or Archivia or Settings return the dot to the icon")
    func menuBarra() {
        #expect(StatoPuntino.nellaBarra.dopo(.clicPuntino) == .menuBarra)
        #expect(StatoPuntino.menuBarra.dopo(.chiudeMenu) == .nellaBarra)
        #expect(StatoPuntino.menuBarra.dopo(.chiedeArchiviazione) == .nellaBarra)
        #expect(StatoPuntino.menuBarra.dopo(.apreImpostazioni) == .nellaBarra)
        #expect(StatoPuntino.menuBarra.dopoChat(aperta: true) == .chatSottoBarra)
        #expect(StatoPuntino.menuBarra.dopoChat(aperta: false) == .menuBarra)
    }

    @Test("Files dropped on the icon in the menu bar are archived without moving the dot: the icon stays where it is")
    func rilasciaFileNellaBarra() {
        let file = [URL(fileURLWithPath: "/tmp/documento.pdf")]
        #expect(StatoPuntino.nellaBarra.dopo(.rilasciaFile(urls: file)) == .nellaBarra)
        #expect(StatoPuntino.menuBarra.dopo(.rilasciaFile(urls: file)) == .menuBarra)
    }

    @Test("The Hide shortcut produces the Event that alternates the dot")
    func scorciatoiaAlterna() {
        #expect(Scorciatoia.alterna.evento(chatAperta: false) == .alternaPuntino)
        #expect(Scorciatoia.alterna.evento(chatAperta: true) == .alternaPuntino)
    }
}
