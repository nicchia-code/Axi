import AxiCore
import AxiScreen
import SwiftUI

/// The Permissions window: what is missing, with the rows that ask for it. The window's Events go out through `onEvento`.
struct PermessiView: View {
    let model: PermessiModel
    let onEvento: (EventoUtente) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Axi is missing some permissions: without them it can't read the screen.")
                .foregroundStyle(.secondary)

            RighePermessi(model: model, onEvento: onEvento)

            if model.tuttoPronto {
                Label("All set.", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }

            Spacer(minLength: 0)
            HStack {
                Spacer()
                Button("Done") { onEvento(.chiudePermessi) }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.glassProminent)
            }
        }
        .padding(24)
        .frame(width: 460)
    }
}
