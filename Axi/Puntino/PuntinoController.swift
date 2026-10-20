import AppKit
import AxiCore
import AxiScreen
import SwiftUI

/// Owns the dot, its radial menu and its bubble. It turns clicks, drops and menu choices into
/// `EventoUtente` for the rest of the app, and shows the `EventoAttivita` it receives.
///
/// Two input paths:
/// - `riceveChat`, `riceveAttivita`: events from the rest of the app. Nothing is emitted.
/// - `sink`: events produced by the dot itself. They are applied here first, then forwarded once.
///   The composition root must route `sink` to the other consumers and NOT back into the controller.
@MainActor
final class PuntinoController {
    /// Window of the dot: 1.75 times the character (84 pt for 48 pt), so it keeps the room the character needs
    /// while it grows on file drops and bounces. The window grows from its bottom-left corner.
    static let dimensionePuntino = NSSize(width: 84, height: 84)
    /// How long a bubble stays on screen while the pointer is not over it.
    private static let durataNuvoletta: Duration = .seconds(5)
    /// Pause between the menu closing and its window going away, so its animation can play.
    private static let durataChiusuraMenu: Duration = .milliseconds(300)

    private let modello: PuntinoModello
    private let store: PuntinoStore
    private let chatAperta: @MainActor () -> Bool
    private let chatFrame: @MainActor () -> NSRect
    private let tastiAssegnati: @MainActor () -> Bool
    private let sink: @MainActor (EventoUtente) -> Void

    private let puntino: PannelloPuntino
    private let superficiePuntino: Superficie<PuntinoVista>
    private let menu: PannelloPuntino
    private let superficieMenu: Superficie<MenuRadialeVista>
    private let nuvoletta: PannelloPuntino
    private let superficieNuvoletta: Superficie<NuvolettaVista>

    private var timerNuvoletta: Task<Void, Never>?
    private var chiusuraMenu: Task<Void, Never>?
    private var restante: Duration = PuntinoController.durataNuvoletta
    private var inizioTimer: ContinuousClock.Instant?
    private var puntatoreSopraNuvoletta = false
    private var monitorClic: [Any] = []
    private var osservatoreSpostamento: NSObjectProtocol?
    private var elementoBarra: ElementoBarra?
    /// The tail the bubble shows now; nil when it has none (over the open chat). The panel carries its strip.
    private var codaNuvoletta: CodaNuvoletta?
    /// Whether the dot was hidden at the last update, so the mini-chat follows it only when that changes.
    private var nascostoAggiornato: Bool?

    /// - Parameters:
    ///   - chatAperta: whether the mini-chat is open; decides between "Chat" opening and closing.
    ///   - chatFrame: where the open mini-chat sits now; the bubble overlays its top.
    ///   - tastiAssegnati: whether the Spotlight and Dictation keys are Axi's. The menu shows their symbols
    ///     only when this is `true` and Accessibility is granted, checked at each opening.
    ///   - sink: receives every event the dot produces, after the dot has applied it.
    init(
        store: PuntinoStore = PuntinoStore(fileURL: PuntinoStore.defaultFileURL),
        chatAperta: @escaping @MainActor () -> Bool,
        chatFrame: @escaping @MainActor () -> NSRect,
        tastiAssegnati: @escaping @MainActor () -> Bool,
        sink: @escaping @MainActor (EventoUtente) -> Void
    ) {
        let modello = PuntinoModello()
        self.modello = modello
        self.store = store
        self.chatAperta = chatAperta
        self.chatFrame = chatFrame
        self.tastiAssegnati = tastiAssegnati
        self.sink = sink

        puntino = PannelloPuntino(size: Self.dimensionePuntino)
        superficiePuntino = Superficie(rootView: PuntinoVista(modello: modello, sulloSchermo: true))
        menu = PannelloPuntino(size: NSSize(width: MenuRadialeVista.lato, height: MenuRadialeVista.lato))
        // Placeholder callbacks: replaced in `configura()` once `self` exists.
        superficieMenu = Superficie(rootView: MenuRadialeVista(modello: modello, scegli: { _ in }))
        nuvoletta = PannelloPuntino(size: NSSize(width: 280, height: 80))
        superficieNuvoletta = Superficie(rootView: NuvolettaVista(modello: modello, alPassaggio: { _ in }, alClic: {}))

        configura()
    }

    // MARK: - Public

    /// Shows the dot at its saved place, or hidden in the menu bar when it was left hidden.
    func avvia() {
        let salvata = store.load()
        if salvata?.nascosto == true { modello.stato = .nellaBarra }
        puntino.setFrame(NSRect(origin: originePuntinoIniziale(), size: Self.dimensionePuntino), display: false)
        puntino.alphaValue = 0
        aggiorna()
    }

    /// Where the mini-chat anchors: beside the dot, or under the icon in the menu bar while the dot is hidden.
    var ancoraggioChat: AncoraggioChat {
        guard modello.stato.nascosto else { return .puntino(puntino.frame) }
        if let icona = elementoBarra?.frameSulloSchermo() { return .barra(icona) }
        // Menu bar hidden (a full screen app): the top centre of the main screen, where the icon would be.
        let schermo = NSScreen.main?.frame ?? .zero
        return .barra(NSRect(x: schermo.midX, y: schermo.maxY, width: 0, height: 0))
    }

    /// Called after the dot moved, so the open mini-chat can follow it.
    var alSpostamento: (@MainActor () -> Void)?

    /// Applies the mini-chat state. `nonDisponibile` is shown as a bubble.
    func riceveChat(_ evento: MiniChatEvent) {
        switch evento {
        case .aperta:
            modello.stato = modello.stato.dopoChat(aperta: true)
            aggiorna()
        case .chiusa:
            modello.stato = modello.stato.dopoChat(aperta: false)
            aggiorna()
        case .nonDisponibile:
            riceveAttivita(.chatNonDisponibile)
        }
    }

    /// Applies whether the mini-chat is answering: while it is, the dot shows the three dots.
    func riceveRisposta(inCorso: Bool) {
        modello.chatRisponde = inCorso
    }

    /// Applies an activity event, from the archive queue, the screen reader, the chat or the timer.
    func riceveAttivita(_ evento: EventoAttivita) {
        let prima = modello.attivita
        modello.attivita.riceve(evento)
        let dopo = modello.attivita
        if dopo.nuvolettaScade {
            // A new outcome, state or phase restarts the bubble's time; the queue moving on behind it does not.
            if dopo.stato != prima.stato || dopo.fase != prima.fase || dopo.esiti != prima.esiti { riavviaTimer() }
        } else {
            fermaTimer()
        }
        aggiorna()
    }

    /// Applies a global shortcut's Event to the dot's state before the Event is forwarded. The archive shortcut closes
    /// the open menu, and the Hide shortcut hides or shows the dot.
    func riceveScorciatoia(_ evento: EventoUtente) {
        guard [EventoUtente.chiedeArchiviazione, .alternaPuntino].contains(evento) else { return }
        modello.stato = modello.stato.dopo(evento)
        aggiorna()
    }

    // MARK: - Setup

    private func configura() {
        superficiePuntino.alClic = { [weak self] in self?.clicPuntino() }
        superficiePuntino.alTrascinata = { [weak self] in self?.salvaPosizione() }
        superficiePuntino.alPassaggioFile = { [weak self] dentro in self?.modello.riceveFile = dentro }
        superficiePuntino.alRilascioFile = { [weak self] urls in self?.agisce(.rilasciaFile(urls: urls)) }
        superficiePuntino.registerForDraggedTypes([.fileURL])
        puntino.contentView = superficiePuntino

        superficieMenu.rootView = MenuRadialeVista(modello: modello, scegli: { [weak self] voce in
            self?.sceglie(voce)
        })
        menu.contentView = superficieMenu

        superficieNuvoletta.rootView = vistaNuvoletta(coda: nil)
        nuvoletta.contentView = superficieNuvoletta

        // Moving the dot (by drag) drags the anchored menu and bubble along.
        osservatoreSpostamento = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: puntino,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.riposizionaAncorati() }
        }
    }

    // MARK: - Dot actions

    private func clicPuntino() {
        // With the menu open, a click on the dot has no effect: the menu closes only outside it.
        guard modello.stato != .menuAperto else { return }
        AppInPrimoPiano.shared.registraAppInPrimoPiano()
        agisce(.clicPuntino)
    }

    /// A click on the icon in the menu bar is applied like a click on the dot: with the chat open under it, it closes
    /// the chat. Otherwise the menu of the icon opens, and the item chosen in it is applied.
    private func clicBarra() {
        agisce(.clicPuntino)
        guard modello.stato == .menuBarra, let barra = elementoBarra else { return }
        let scelta = barra.mostraMenu(simboliTasti: tastiAssegnati() && Permissions.accessibilityGranted())
        switch scelta {
        case .some(.mostra):
            agisce(.alternaPuntino)
        case .some(.voce(.esci)):
            NSApp.terminate(nil)
        case .some(.voce(let voce)):
            if let evento = voce.evento(chatAperta: chatAperta()) { agisce(evento) }
        case nil:
            break
        }
        // A menu closed without an Event that moves the dot returns to the icon.
        if modello.stato == .menuBarra { agisce(.chiudeMenu) }
    }

    private func sceglie(_ voce: VoceMenu) {
        if voce == .esci {
            NSApp.terminate(nil)
            return
        }
        guard let evento = voce.evento(chatAperta: chatAperta()) else { return }
        agisce(evento)
    }

    /// Applies an event produced by the dot, then forwards it.
    private func agisce(_ evento: EventoUtente) {
        modello.stato = modello.stato.dopo(evento)
        aggiorna()
        sink(evento)
    }

    /// Closes the menu on a press outside both the menu and the dot. Clicks on the dot
    /// are left to `clicPuntino`, so a single press never both closes and reopens the menu.
    private func chiudeMenuSeClicFuori(_ punto: NSPoint) {
        guard modello.stato == .menuAperto,
              !menu.frame.contains(punto),
              !puntino.frame.contains(punto)
        else { return }
        agisce(.chiudeMenu)
    }

    private func clicNuvoletta() {
        guard modello.attivita.nuvoletta != nil else { return }
        if let copia = modello.attivita.nuvoletta?.copia {
            NSWorkspace.shared.open(copia)
        }
        riceveAttivita(.clicNuvoletta)
    }

    // MARK: - Rendering

    /// Brings the windows in line with the model.
    private func aggiorna() {
        animaVisibilita(puntino, visibile: !modello.stato.nascosto)
        sincronizzaBarra()
        let nascosto = modello.stato.nascosto
        if nascostoAggiornato != nascosto {
            nascostoAggiornato = nascosto
            // The mini-chat moves between the dot and the icon in the menu bar.
            alSpostamento?()
        }
        if modello.stato == .menuAperto {
            apriMenu()
        } else {
            chiudiMenu()
        }
        aggiornaNuvoletta()
        salvaPosizione()
    }

    /// The icon in the menu bar exists while the dot is hidden, and is removed when the dot shows again.
    private func sincronizzaBarra() {
        guard modello.stato.nascosto else {
            elementoBarra?.rimuovi()
            elementoBarra = nil
            return
        }
        guard elementoBarra == nil else { return }
        elementoBarra = ElementoBarra(
            modello: modello,
            onClick: { [weak self] in self?.clicBarra() },
            onApertura: { AppInPrimoPiano.shared.registraAppInPrimoPiano() },
            alPassaggioFile: { [weak self] dentro in self?.modello.riceveFile = dentro },
            alRilascioFile: { [weak self] urls in self?.agisce(.rilasciaFile(urls: urls)) }
        )
    }

    private func apriMenu() {
        chiusuraMenu?.cancel()
        guard !modello.menuVisibile else { return }
        modello.mostraSimboliTasti = tastiAssegnati() && Permissions.accessibilityGranted()
        posizionaMenu()
        menu.orderFrontRegardless()
        modello.menuVisibile = true
        installaMonitorClic()
    }

    private func chiudiMenu() {
        rimuoviMonitorClic()
        guard modello.menuVisibile else { return }
        modello.menuVisibile = false
        chiusuraMenu = Task { [weak self] in
            try? await Task.sleep(for: Self.durataChiusuraMenu)
            guard let self, !Task.isCancelled, !self.modello.menuVisibile else { return }
            self.menu.orderOut(nil)
        }
    }

    private func aggiornaNuvoletta() {
        guard modello.attivita.nuvoletta != nil else {
            puntatoreSopraNuvoletta = false
            nuvoletta.ignoresMouseEvents = true
            animaVisibilita(nuvoletta, visibile: false)
            return
        }
        // The bubble takes the pointer in every state: hovering pauses its life; only the outcome copies on click.
        nuvoletta.ignoresMouseEvents = false
        posizionaNuvoletta()
        animaVisibilita(nuvoletta, visibile: true)
    }

    /// Moves the menu, the bubble and the mini-chat after the dot moved.
    private func riposizionaAncorati() {
        if modello.menuVisibile { posizionaMenu() }
        alSpostamento?()
        if modello.attivita.nuvoletta != nil { posizionaNuvoletta() }
    }

    private func animaVisibilita(_ pannello: NSPanel, visibile: Bool) {
        if !visibile && !pannello.isVisible { return }
        if visibile { pannello.orderFrontRegardless() }
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
            pannello.alphaValue = visibile ? 1 : 0
            if !visibile { pannello.orderOut(nil) }
            return
        }
        NSAnimationContext.runAnimationGroup({ contesto in
            contesto.duration = 0.2
            pannello.animator().alphaValue = visibile ? 1 : 0
        })
        // A panel shown again during its fade-out has alphaValue 1 and stays on screen.
        guard !visibile else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            if pannello.alphaValue == 0 { pannello.orderOut(nil) }
        }
    }

    // MARK: - Placement

    private func posizionaMenu() {
        let lato = MenuRadialeVista.lato
        let area = areaVisibile(per: puntino.frame)
        var origine = NSPoint(x: puntino.frame.midX - lato / 2, y: puntino.frame.midY - lato / 2)
        origine.x = min(max(origine.x, area.minX), area.maxX - lato)
        origine.y = min(max(origine.y, area.minY), area.maxY - lato)
        menu.setFrame(NSRect(origin: origine, size: NSSize(width: lato, height: lato)), display: true)
    }

    /// With the mini-chat open, the bubble overlays the top of the chat, with no tail. Otherwise it sits beside the dot,
    /// on the side with the most free space among the four (above, below, right, left), its tail reaching the dot.
    /// While the dot is hidden, the bubble goes under its icon in the menu bar, or under the top centre of the main
    /// screen when the bar is hidden by a full screen app.
    private func posizionaNuvoletta() {
        let corpo = misuraCorpoNuvoletta()
        if chatAperta() {
            let chat = chatFrame()
            let origine = MiniChatPlacement.bubbleOrigin(
                overlayingTopOf: chat,
                size: corpo,
                visibleFrame: areaVisibile(per: chat)
            )
            impostaNuvoletta(coda: nil, rettangolo: NSRect(origin: origine, size: corpo))
            return
        }
        let ancora = ancoraggioChat.rect
        let area = areaVisibile(per: ancora)
        // The gap between the bubble and its anchor is where the tail sits.
        let distanza = CodaNuvoletta.spessore
        typealias Posto = (spazio: CGFloat, origine: NSPoint, lato: CodaNuvoletta.Lato)
        let sotto: Posto = (ancora.minY - area.minY, NSPoint(x: ancora.midX - corpo.width / 2, y: ancora.minY - distanza - corpo.height), .sopra)
        let migliore: Posto
        if modello.stato.nascosto {
            migliore = sotto
        } else {
            let lati: [Posto] = [
                (area.maxY - ancora.maxY, NSPoint(x: ancora.midX - corpo.width / 2, y: ancora.maxY + distanza), .sotto),
                sotto,
                (area.maxX - ancora.maxX, NSPoint(x: ancora.maxX + distanza, y: ancora.midY - corpo.height / 2), .sinistra),
                (ancora.minX - area.minX, NSPoint(x: ancora.minX - distanza - corpo.width, y: ancora.midY - corpo.height / 2), .destra),
            ]
            var scelta = lati[0]
            for lato in lati.dropFirst() where lato.spazio > scelta.spazio { scelta = lato }
            migliore = scelta
        }
        let x = min(max(migliore.origine.x, area.minX + 8), area.maxX - corpo.width - 8)
        let y = min(max(migliore.origine.y, area.minY + 8), area.maxY - corpo.height - 8)
        let rettangolo = NSRect(origin: NSPoint(x: x, y: y), size: corpo)
        // The tail points at the middle of the anchor, kept away from the corners of the bubble.
        let margine: CGFloat = 14
        let posizione: CGFloat
        switch migliore.lato {
        case .sopra, .sotto:
            posizione = min(max(ancora.midX - x, margine), corpo.width - margine)
        case .sinistra, .destra:
            posizione = min(max(y + corpo.height - ancora.midY, margine), corpo.height - margine)
        }
        impostaNuvoletta(coda: CodaNuvoletta(lato: migliore.lato, posizione: posizione), rettangolo: rettangolo)
    }

    /// Sets the bubble's panel to `rettangolo`, grown by the tail's strip on the side that faces the anchor, and shows
    /// the tail on that side.
    private func impostaNuvoletta(coda: CodaNuvoletta?, rettangolo: NSRect) {
        let spessore = CodaNuvoletta.spessore
        var pannello = rettangolo
        switch coda?.lato {
        case .sotto?:
            pannello.origin.y -= spessore
            pannello.size.height += spessore
        case .sopra?:
            pannello.size.height += spessore
        case .sinistra?:
            pannello.origin.x -= spessore
            pannello.size.width += spessore
        case .destra?:
            pannello.size.width += spessore
        case nil:
            break
        }
        codaNuvoletta = coda
        superficieNuvoletta.rootView = vistaNuvoletta(coda: coda)
        nuvoletta.setFrame(pannello, display: true)
    }

    /// The bubble's own size: the fitting size of its panel less the tail's strip it currently carries.
    private func misuraCorpoNuvoletta() -> NSSize {
        let misura = superficieNuvoletta.fittingSize
        let spessore = CodaNuvoletta.spessore
        switch codaNuvoletta?.lato {
        case .sopra?, .sotto?: return NSSize(width: misura.width, height: misura.height - spessore)
        case .sinistra?, .destra?: return NSSize(width: misura.width - spessore, height: misura.height)
        case nil: return misura
        }
    }

    private func vistaNuvoletta(coda: CodaNuvoletta?) -> NuvolettaVista {
        NuvolettaVista(
            modello: modello,
            coda: coda,
            alPassaggio: { [weak self] dentro in self?.puntatoreSopraNuvoletta(dentro) },
            alClic: { [weak self] in self?.clicNuvoletta() }
        )
    }

    /// Saved place if its display is still connected and the place is on screen; otherwise bottom-right of the saved
    /// display, or of the menu bar screen (the first of `NSScreen.screens`) when the saved display is gone.
    private func originePuntinoIniziale() -> NSPoint {
        let schermi = NSScreen.screens
        let rettangolo = { (origine: NSPoint) in NSRect(origin: origine, size: Self.dimensionePuntino) }
        if let salvata = store.load() {
            let origine = NSPoint(x: salvata.x, y: salvata.y)
            let schermoPresente = salvata.schermo.map { id in schermi.contains { Self.displayID($0) == id } } ?? true
            if schermoPresente, schermi.contains(where: { $0.visibleFrame.intersects(rettangolo(origine)) }) {
                return origine
            }
        }
        let schermoSalvato = store.load()?.schermo
        let schermo = schermi.first { Self.displayID($0) == schermoSalvato } ?? schermi.first
        let area = schermo?.visibleFrame ?? .zero
        return NSPoint(x: area.maxX - Self.dimensionePuntino.width - 24, y: area.minY + 24)
    }

    private func areaVisibile(per frame: NSRect) -> NSRect {
        NSScreen.screens.first { $0.visibleFrame.intersects(frame) }?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? .zero
    }

    // MARK: - Persistence

    /// Writes where the dot is. Best effort: losing the file only
    /// means the dot starts at the default place next time.
    private func salvaPosizione() {
        let frame = puntino.frame
        let posizione = PosizionePuntino(
            x: Double(frame.origin.x),
            y: Double(frame.origin.y),
            // A dot that is hidden or not yet shown has no screen: keep the display it was left on.
            schermo: puntino.screen.flatMap { Self.displayID($0) } ?? store.load()?.schermo,
            nascosto: modello.stato.nascosto
        )
        try? store.save(posizione)
    }

    /// `CGDirectDisplayID` of a screen, as stored in `PosizionePuntino.schermo`.
    private static func displayID(_ schermo: NSScreen) -> UInt32? {
        (schermo.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }

    // MARK: - Timer of the bubble

    private func riavviaTimer() {
        restante = Self.durataNuvoletta
        avviaTimer()
    }

    /// Runs the remaining time; does nothing while the pointer is over the bubble.
    private func avviaTimer() {
        timerNuvoletta?.cancel()
        guard !puntatoreSopraNuvoletta else {
            inizioTimer = nil
            return
        }
        inizioTimer = .now
        let durata = restante
        timerNuvoletta = Task { [weak self] in
            try? await Task.sleep(for: durata)
            guard !Task.isCancelled else { return }
            self?.riceveAttivita(.nuvolettaScaduta)
        }
    }

    /// Keeps the time already spent, so hovering does not restart the bubble's life.
    private func sospendiTimer() {
        guard let inizio = inizioTimer else { return }
        restante = max(.zero, restante - inizio.duration(to: .now))
        timerNuvoletta?.cancel()
        inizioTimer = nil
    }

    private func fermaTimer() {
        timerNuvoletta?.cancel()
        timerNuvoletta = nil
        inizioTimer = nil
        restante = Self.durataNuvoletta
    }

    private func puntatoreSopraNuvoletta(_ dentro: Bool) {
        puntatoreSopraNuvoletta = dentro
        if dentro {
            sospendiTimer()
        } else if modello.attivita.nuvoletta != nil {
            avviaTimer()
        }
    }

    // MARK: - Outside clicks and Esc

    private static let codiceTastoEsc: UInt16 = 53

    /// Closes the menu on Esc, like a press outside it.
    private func chiudeMenuSuEsc() {
        guard modello.stato == .menuAperto else { return }
        agisce(.chiudeMenu)
    }

    /// Clicks anywhere and Esc while the menu is open: global ones (other apps) and local ones (Axi windows).
    private func installaMonitorClic() {
        guard monitorClic.isEmpty else { return }
        let globale = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] evento in
            if evento.type == .keyDown {
                guard evento.keyCode == Self.codiceTastoEsc else { return }
                Task { @MainActor [weak self] in self?.chiudeMenuSuEsc() }
                return
            }
            let punto = NSEvent.mouseLocation
            Task { @MainActor [weak self] in self?.chiudeMenuSeClicFuori(punto) }
        }
        let locale = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] evento in
            if evento.type == .keyDown {
                if evento.keyCode == Self.codiceTastoEsc {
                    Task { @MainActor [weak self] in self?.chiudeMenuSuEsc() }
                }
                return evento
            }
            let punto = NSEvent.mouseLocation
            Task { @MainActor [weak self] in self?.chiudeMenuSeClicFuori(punto) }
            return evento
        }
        monitorClic = [globale, locale].compactMap { $0 }
    }

    private func rimuoviMonitorClic() {
        monitorClic.forEach { NSEvent.removeMonitor($0) }
        monitorClic.removeAll()
    }
}
