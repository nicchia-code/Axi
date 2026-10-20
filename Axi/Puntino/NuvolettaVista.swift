import AxiScreen
import AxiCore
import SwiftUI

/// The tail of the bubble: two small glass circles that come out of the side facing the dot or the menu-bar icon.
/// The panel keeps the tail as a strip `spessore` points thick on that side, so the bubble keeps its place.
struct CodaNuvoletta: Equatable {
    enum Lato: Equatable {
        case sopra, sotto, sinistra, destra
    }

    /// The side of the bubble the tail comes out of: the side that faces the anchor.
    let lato: Lato
    /// Place of the tail along that side, in points: from the leading edge on top and bottom, from the top edge on the sides.
    let posizione: CGFloat

    /// Thickness of the tail strip: the gap between the bubble and its anchor.
    static let spessore: CGFloat = 8

    /// Offset of a tail circle `distanza` points out of the bubble and `diametro` wide, measured from the corner
    /// that `allineamento` names.
    func spostamento(distanza: CGFloat, diametro: CGFloat) -> CGSize {
        switch lato {
        case .sopra: CGSize(width: posizione - diametro / 2, height: -distanza - diametro / 2)
        case .sotto: CGSize(width: posizione - diametro / 2, height: distanza + diametro / 2)
        case .sinistra: CGSize(width: -distanza - diametro / 2, height: posizione - diametro / 2)
        case .destra: CGSize(width: distanza + diametro / 2, height: posizione - diametro / 2)
        }
    }

    /// The corner of the bubble the tail circles are measured from.
    var allineamento: Alignment {
        switch lato {
        case .sopra, .sinistra: .topLeading
        case .sotto: .bottomLeading
        case .destra: .topTrailing
        }
    }
}

/// The bubble that explains the last result. It takes clicks only in the outcome state.
struct NuvolettaVista: View {
    let modello: PuntinoModello
    /// Tail toward the dot or the menu-bar icon; nil when the bubble lies over the open chat.
    var coda: CodaNuvoletta?
    let alPassaggio: (Bool) -> Void
    let alClic: () -> Void

    var body: some View {
        if let nuvoletta = modello.attivita.nuvoletta {
            corpo(nuvoletta)
        }
    }

    private func corpo(_ nuvoletta: Nuvoletta) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            contenuto(nuvoletta)
            if nuvoletta.copia != nil {
                Text("Click to open the copy.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(12)
        .frame(width: 280, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: coda?.allineamento ?? .topLeading) {
            codaVista
        }
        .padding(rientro)
        .onHover(perform: alPassaggio)
        .onTapGesture {
            alClic()
        }
    }

    /// The two glass circles of the tail: the larger next to the bubble, the smaller next to the anchor.
    @ViewBuilder
    private var codaVista: some View {
        if let coda {
            cerchio(coda.spostamento(distanza: 3, diametro: 5), diametro: 5)
            cerchio(coda.spostamento(distanza: 6.5, diametro: 3), diametro: 3)
        }
    }

    private func cerchio(_ spostamento: CGSize, diametro: CGFloat) -> some View {
        Circle()
            .frame(width: diametro, height: diametro)
            .glassEffect(.regular, in: .circle)
            .offset(spostamento)
    }

    /// Room for the tail beside the bubble, on the side that faces the anchor.
    private var rientro: EdgeInsets {
        let spessore = CodaNuvoletta.spessore
        switch coda?.lato {
        case .sopra?: return EdgeInsets(top: spessore, leading: 0, bottom: 0, trailing: 0)
        case .sotto?: return EdgeInsets(top: 0, leading: 0, bottom: spessore, trailing: 0)
        case .sinistra?: return EdgeInsets(top: 0, leading: spessore, bottom: 0, trailing: 0)
        case .destra?: return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: spessore)
        case nil: return EdgeInsets()
        }
    }

    @ViewBuilder
    private func contenuto(_ nuvoletta: Nuvoletta) -> some View {
        switch nuvoletta {
        case .archiviato(let documento, let nome):
            Group {
                if let nome {
                    Text("Archived “\(nome)”")
                } else {
                    Text("Archived")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
            Text(documento.titolo)
                .font(.headline)
                .lineLimit(2)
            if documento.pdfNonPresente {
                Text("The vault holds only the text you read on screen and the address.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !documento.tag.isEmpty {
                Text(documento.tag.map { "#\($0)" }.joined(separator: " "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if documento.dataRicezioneSconosciuta {
                Text("I couldn't tell when it arrived: archived without a received date.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !documento.allegatiNonPresi.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Attachments not taken: \(documento.allegatiNonPresi.joined(separator: ", "))")
                    Text("You can drag them or open them.")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
        case .archiviando(let nome):
            HStack(spacing: 6) {
                if let nome {
                    Text("Archiving “\(nome)”")
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text("Archiving")
                }
                PuntiniAttesa()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        case .nonArchiviato(.giaPresente, let nome):
            if let nome {
                Text("“\(nome)” is already in the vault.")
            } else {
                Text("Already in the vault.")
            }
        case .nonArchiviato(let motivo, let nome):
            if let nome {
                Text("Didn't archive “\(nome)”")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(motivo.testo)
        case .nessunDocumento(let motivo):
            Text(motivo.testo)
        case .chatNonDisponibile:
            Text("Chat is not available")
                .font(.headline)
            Text("Chat needs OMP, which is not ready yet.")
        }
    }
}

/// The three dots of the bubble while Axi archives: three small solid circles in the secondary colour, rising one after
/// another in a wave on the same cycle as the character's three dots. With Reduce Motion they run at half speed.
private struct PuntiniAttesa: View {
    @Environment(\.accessibilityReduceMotion) private var riduciMovimento

    var body: some View {
        TimelineView(.animation) { linea in
            let fase = PuntinoGeometria.fase(
                al: linea.date,
                velocita: PuntinoGeometria.velocita(riduciMovimento: riduciMovimento)
            )
            Canvas { contesto, dimensione in
                let diametro: CGFloat = 4.5
                for i in 0..<3 {
                    let sollevamento = max(0, sin(fase - CGFloat(i) * 0.7))
                    let centro = CGPoint(
                        x: diametro / 2 + CGFloat(i) * 6,
                        y: dimensione.height / 2 - 2.5 * sollevamento
                    )
                    let punto = CGRect(x: centro.x - diametro / 2, y: centro.y - diametro / 2, width: diametro, height: diametro)
                    contesto.fill(Path(ellipseIn: punto), with: .color(Color.secondary))
                }
            }
            .frame(width: 17, height: 9)
        }
    }
}

extension MotivoNonArchiviato {
    /// Text shown in the bubble for each reason.
    var testo: LocalizedStringKey {
        switch self {
        case .giaPresente: "Already in the vault."
        case .ompNonPronto: "OMP is not ready."
        case .ompFermato: "OMP stopped while archiving."
        case .benvenutoNonCompletato: "Finish the welcome window before archiving."
        case .documentoIllegibile: "The document cannot be read."
        case .testoAssente: "The document has no text."
        case .aiNonRisponde: "The AI did not return valid details."
        case .pdfNonScaricato: "I couldn't download this PDF: download it and drop it on the dot."
        case .pdfTroppoGrande: "This PDF is over 200 MB: download it and drop it on the dot."
        case .indicizzazioneFallita: "Indexing failed."
        case .erroreImprevisto: "Something went wrong: the document wasn't archived."
        }
    }
}

extension NoDocumentReason {
    /// The sentence the bubble shows for each reason: what happened and what the user can do.
    var testo: LocalizedStringKey {
        switch self {
        case .nothingInFront:
            "I don't see a document to archive here: save it as a file first."
        case .addressUnreadable:
            "I can't read this page's address."
        case .browserAutomationMissing(let browser):
            "Reading this page needs the Automation permission for \(browser)."
        case .permissionMissing(.accessibility):
            "Reading the screen needs the Accessibility permission."
        case .permissionMissing(.browserAutomation):
            "Reading this page needs the Automation permission for the browser."
        case .permissionMissing(.finderAutomation):
            "Reading the Finder selection needs the Automation permission for Finder."
        case .permissionMissing(.screenRecording):
            "Reading the screen needs the Screen Recording permission."
        case .unexpectedError:
            "Something went wrong: the document wasn't archived."
        }
    }
}
