import AxiCore
import AxiOMP
import KeyboardShortcuts
import SwiftUI

/// The settings window: Modello AI, Scorciatoie, Azure Document Intelligence, OMP and Permissions.
struct ImpostazioniView: View {
    @Bindable var modello: ImpostazioniModel
    var body: some View {
        Form {
            sezioneModello
            sezioneScorciatoie
            sezioneTastiApple
            sezioneAzure
            sezioneOMP
            sezionePermessi
        }
        .formStyle(.grouped)
        .frame(minWidth: 480, minHeight: 520)
        .task { await modello.avvia() }
        .task { await modello.seguePermessi() }
    }

    // MARK: Modello AI

    private var sezioneModello: some View {
        Section("Modello AI") {
            switch modello.modelli {
            case .caricamento:
                ProgressView()
            case .errore(let messaggio):
                Text(messaggio).foregroundStyle(.secondary)
            case .pronto(let lista):
                Picker("Modello", selection: Binding(
                    get: { modello.modelloSelezionato ?? "" },
                    set: { modello.scegliModello($0) }
                )) {
                    ForEach(lista, id: \.key) { modelloOMP in
                        Text(modelloOMP.name)
                            .tag(modelloOMP.key)
                    }
                }
            }
        }
    }

    // MARK: Scorciatoie

    private var sezioneScorciatoie: some View {
        Section {
            KeyboardShortcuts.Recorder("Archivia", name: .archivia)
            KeyboardShortcuts.Recorder("Chat", name: .chat)
            KeyboardShortcuts.Recorder("Nascondi", name: .alterna)
            Button("Ripristina valori predefiniti") {
                Scorciatoie.ripristinaPredefinite()
            }
        } header: {
            Text("Scorciatoie")
        }
    }

    // MARK: Tasti Apple

    private var sezioneTastiApple: some View {
        Section {
            Toggle("Spotlight e Dettatura", isOn: $modello.tastiAppleAttivi)
        } header: {
            Text("Tasti Apple")
        } footer: {
            Text(testoTastiApple)
        }
    }

    /// Says what the switch does, and that the keys stay macOS's until their signal is verified on a real keyboard.
    private var testoTastiApple: String {
        let cosa = "Spotlight apre o chiude la chat, Dettatura archivia il documento in primo piano."
        if CodiciTastiApple.predefiniti.completi {
            return "\(cosa) Serve il permesso di Accessibilità."
        }
        return "\(cosa) Il segnale dei due tasti non è ancora verificato su una tastiera Apple reale: finché non lo è, Axi non li prende e restano quelli di macOS."
    }

    // MARK: Azure Document Intelligence

    private var sezioneAzure: some View {
        Section {
            TextField("Endpoint", text: $modello.endpointAzure)
                .onChange(of: modello.endpointAzure) { _, _ in modello.salvaEndpointAzure() }
            SecureField("Chiave", text: $modello.chiaveAzure)
                .onChange(of: modello.chiaveAzure) { _, _ in modello.salvaChiaveAzure() }
            HStack {
                Button("Prova connessione") {
                    Task { await modello.provaAzureConnessione() }
                }
                .disabled(modello.endpointAzure.isEmpty || modello.chiaveAzure.isEmpty
                          || modello.esitoProva == .inCorso)
                esitoProvaView
            }
            if let errore = modello.errorePersistenza {
                Text(errore).foregroundStyle(.red)
            }
        } header: {
            Text("Azure Document Intelligence")
        } footer: {
            Text("Se configurato, Azure viene usato per le pagine senza testo e per lo schermo.")
        }
    }

    @ViewBuilder
    private var esitoProvaView: some View {
        switch modello.esitoProva {
        case .nessuna:
            EmptyView()
        case .inCorso:
            ProgressView().controlSize(.small)
        case .riuscita:
            Label("Connessione riuscita", systemImage: "checkmark.circle")
                .foregroundStyle(.green)
        case .fallita(let motivo):
            Label(motivo, systemImage: "xmark.circle")
                .foregroundStyle(.red)
        }
    }

    // MARK: OMP

    private var sezioneOMP: some View {
        Section("OMP") {
            TextField("Percorso", text: $modello.percorsoOMP)
                .onChange(of: modello.percorsoOMP) { _, _ in modello.cambiaPercorsoOMP() }
            LabeledContent("Stato") {
                Text(testoStato)
            }
            if case .unavailable(let motivo) = modello.statoOMP {
                Text(motivo.message).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Permessi

    private var sezionePermessi: some View {
        Section {
            RighePermessi(model: modello.permessi, onEvento: { modello.invia($0) })
        } header: {
            Text("Permissions")
        }
    }

    private var testoStato: String {
        switch modello.statoOMP {
        case .starting: String(localized: "Avvio in corso")
        case .ready: String(localized: "Connesso")
        case .unavailable: String(localized: "Non disponibile")
        }
    }
}
