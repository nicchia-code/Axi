import AppKit
import AxiCore
import AxiOMP
import AxiScreen
import SwiftUI

/// Runs the `impostazioni` Machine: the window is closed or open, and the window
/// shows the settings. Events for other Machines leave through `sink`.
@MainActor
final class ImpostazioniController: NSObject, NSWindowDelegate {
    private(set) var stato: StatoImpostazioni = .chiuse
    private let modello: ImpostazioniModel
    private var finestra: NSWindow?

    init(
        store: ImpostazioniStore,
        omp: OMPConnection,
        provaAzure: @escaping @MainActor (_ endpoint: String, _ chiave: String) async throws -> Void,
        sink: @escaping @MainActor (EventoUtente) -> Void,
        permessi: PermessiModel
    ) {
        self.modello = ImpostazioniModel(store: store, omp: omp, provaAzure: provaAzure, sink: sink, permessi: permessi)
    }

    /// Receives a `utente` Event of this Machine: `apreImpostazioni`, `chiudeImpostazioni` or `riapreAxi`.
    /// Other Events are ignored, as the Model has no Transition for them.
    func riceve(_ evento: EventoUtente) {
        let nuovo = stato.dopo(evento)
        switch evento {
        case .apreImpostazioni:
            mostra()
        case .chiudeImpostazioni, .riapreAxi:
            chiudi()
        default:
            return
        }
        stato = nuovo
    }

    /// The window was closed by the user, which is `utente.CHIUDE_IMPOSTAZIONI`.
    func windowWillClose(_ notification: Notification) {
        stato = stato.dopo(.chiudeImpostazioni)
        finestra = nil
    }

    private func mostra() {
        if let finestra {
            // Already open: bring it to the front, state unchanged.
            NSApp.activate()
            finestra.makeKeyAndOrderFront(nil)
            return
        }
        let vista = ImpostazioniView(modello: modello)
        let nuova = NSWindow(contentViewController: NSHostingController(rootView: vista))
        nuova.title = String(localized: "Impostazioni")
        nuova.styleMask = [.titled, .closable, .miniaturizable]
        nuova.setContentSize(NSSize(width: 520, height: 560))
        nuova.isReleasedWhenClosed = false
        nuova.delegate = self
        nuova.center()
        finestra = nuova
        NSApp.activate()
        nuova.makeKeyAndOrderFront(nil)
    }

    private func chiudi() {
        finestra?.delegate = nil
        finestra?.close()
        finestra = nil
    }

    /// The Azure check of the settings window: sends the endpoint and key to Azure Document
    /// Intelligence. Throws when the endpoint is not a URL or the connection fails.
    static func provaAzure(endpoint: String, chiave: String) async throws {
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        try await AzureDocumentIntelligenceClient.checkConnection(
            configuration: AzureDocumentIntelligenceConfiguration(endpoint: url, apiKey: chiave)
        )
    }
}
