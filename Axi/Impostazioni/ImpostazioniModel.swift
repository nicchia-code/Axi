import AxiCore
import AxiOMP
import Observation
import SwiftUI

/// What the Settings window shows and changes. Every change is stored at once.
@Observable
@MainActor
final class ImpostazioniModel {
    enum StatoModelli: Equatable {
        case caricamento
        case pronto([OMPModel])
        case errore(String)
    }

    enum EsitoProva: Equatable {
        case nessuna
        case inCorso
        case riuscita
        case fallita(String)
    }

    let store: ImpostazioniStore
    private let omp: OMPConnection
    private let sink: @MainActor (EventoUtente) -> Void
    /// The macOS permissions shown by the settings' Permissions section; shared with the Permissions window.
    let permessi: PermessiModel
    private let provaAzure: @MainActor (_ endpoint: String, _ chiave: String) async throws -> Void

    var modelli: StatoModelli = .caricamento
    var statoOMP: OMPConnectionState = .starting
    var percorsoOMP: String
    var endpointAzure: String
    var chiaveAzure: String
    var esitoProva: EsitoProva = .nessuna
    var errorePersistenza: String?
    /// The "Tasti Apple" switch: Axi takes the Spotlight and Dictation keys while it is on. Stored at once.
    var tastiAppleAttivi: Bool {
        didSet { store.tastiAppleAttivi = tastiAppleAttivi }
    }
    /// The model OMP uses for its sessions, read after the connection is ready; nil until read or when OMP reports none.
    private(set) var modelloPredefinitoOMP: String?

    /// Model shown as selected: the user's choice, else OMP's default model, else the first model OMP lists.
    var modelloSelezionato: String? {
        if let scelto = store.modelloAI {
            return scelto
        }
        if let predefinito = modelloPredefinitoOMP {
            return predefinito
        }
        if case let .pronto(lista) = modelli {
            return lista.first?.key
        }
        return nil
    }

    init(
        store: ImpostazioniStore,
        omp: OMPConnection,
        provaAzure: @escaping @MainActor (_ endpoint: String, _ chiave: String) async throws -> Void,
        sink: @escaping @MainActor (EventoUtente) -> Void,
        permessi: PermessiModel
    ) {
        self.store = store
        self.omp = omp
        self.provaAzure = provaAzure
        self.sink = sink
        self.permessi = permessi
        self.percorsoOMP = store.percorsoOMP ?? ""
        self.endpointAzure = store.endpointAzure
        self.chiaveAzure = (try? store.chiaveAzure.leggi()) ?? ""
        self.tastiAppleAttivi = store.tastiAppleAttivi
    }

    /// Sends an Event of this window to the Machine that consumes it, through the app.
    func invia(_ evento: EventoUtente) {
        sink(evento)
    }

    /// Reads the permissions every second while the window is open, as the Permissions window does.
    func seguePermessi() async {
        while !Task.isCancelled {
            permessi.refresh()
            try? await Task.sleep(for: .seconds(1))
        }
    }

    /// Loads the model list, then follows the OMP connection state while the window is open.
    /// Subscribes before reading the state, so a change during the load is not lost; each time OMP becomes ready, the list is loaded again.
    func avvia() async {
        let eventi = omp.events()
        statoOMP = await omp.state
        await caricaModelli()
        for await evento in eventi {
            switch evento {
            case .starting:
                statoOMP = .starting
            case .ready:
                statoOMP = .ready
                await caricaModelli()
            case let .unavailable(motivo): statoOMP = .unavailable(motivo)
            default: break
            }
        }
    }

    private func caricaModelli() async {
        modelli = .caricamento
        do {
            modelli = .pronto(try await omp.availableModels())
        } catch {
            modelli = .errore(String(localized: "Elenco dei modelli non disponibile"))
        }
        modelloPredefinitoOMP = try? await omp.currentModelKey()
    }

    func scegliModello(_ id: String) {
        store.modelloAI = id
        // Applied to both OMP processes when ready; otherwise the next start uses the stored choice.
        Task { try? await omp.setModel(id) }
    }

    /// Stores the OMP path at once. OMP is restarted on it only when the path names an existing executable,
    /// so incomplete paths typed by the user do not disturb the connection.
    func cambiaPercorsoOMP() {
        let nuovo = percorsoOMP.isEmpty ? nil : percorsoOMP
        guard nuovo != store.percorsoOMP else { return }
        store.percorsoOMP = nuovo
        guard let percorso = nuovo, FileManager.default.isExecutableFile(atPath: percorso) else { return }
        sink(.cambiaPercorsoOMP(percorso: percorso))
    }

    func salvaEndpointAzure() {
        store.endpointAzure = endpointAzure
    }

    func salvaChiaveAzure() {
        do {
            try store.chiaveAzure.scrivi(chiaveAzure)
            errorePersistenza = nil
        } catch {
            errorePersistenza = String(localized: "Chiave non salvata nel Keychain")
        }
    }

    func provaAzureConnessione() async {
        esitoProva = .inCorso
        do {
            try await provaAzure(endpointAzure, chiaveAzure)
            esitoProva = .riuscita
        } catch {
            esitoProva = .fallita(String(localized: "Connessione non riuscita"))
        }
    }
}
