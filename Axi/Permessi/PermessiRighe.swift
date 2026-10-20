import AxiCore
import AxiScreen
import SwiftUI

/// The row of one permission: its explanation, whether it is granted, and the Allow button while it is missing.
/// Shared by the Permissions window, the welcome and the settings.
struct RigaPermesso: View {
    let title: LocalizedStringKey
    let explanation: LocalizedStringKey
    let granted: Bool
    /// Screen Recording was asked and takes effect only after Axi is reopened: the row says so and offers Reopen Axi.
    var attesaRiapertura = false
    let onAllow: () -> Void
    var onReopen: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(explanation).font(.subheadline).foregroundStyle(.secondary)
                if attesaRiapertura {
                    Text("Screen Recording takes effect after reopening Axi.").font(.subheadline)
                }
            }
            Spacer()
            Image(systemName: granted ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(granted ? .green : .secondary)
                .accessibilityLabel(Text(granted ? "Granted" : "Not granted"))
            if attesaRiapertura {
                if let onReopen {
                    Button("Reopen Axi", action: onReopen).buttonStyle(.glass)
                }
            } else if !granted {
                Button("Allow", action: onAllow).buttonStyle(.glass)
            }
        }
    }
}

/// The Automation row: the state of the Finder and of each installed browser among Safari and Chrome.
/// A closed browser has no state yet, so it is asked to be opened instead, with no button.
struct RigaAutomazione: View {
    let browsers: [Permissions.BrowserAutomation]
    /// Asks only for the Finder's Automation.
    let onAllowFinder: () -> Void
    /// Asks for the browsers' Automation; the Finder is not among them.
    let onAllow: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Browser Automation").font(.headline)
                Text("Lets Axi read the Finder selection and the address of your browser tabs.")
                    .font(.subheadline).foregroundStyle(.secondary)
                ForEach(browsers) { browser in
                    if browser.state == .browserClosed {
                        Text("Open \(browser.name) to check.").font(.subheadline)
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: browser.granted ? "checkmark.circle.fill" : "circle.dashed")
                                .foregroundStyle(browser.granted ? .green : .secondary)
                                .accessibilityLabel(Text(browser.granted ? "Granted" : "Not granted"))
                            Text(verbatim: browser.name).font(.subheadline)
                            if browser.isFinder && !browser.granted {
                                Button("Allow", action: onAllowFinder).buttonStyle(.glass).controlSize(.small)
                            }
                        }
                    }
                }
                Text("Firefox doesn't need it: Accessibility is enough.").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            if browsers.contains(where: { !$0.isFinder && !$0.granted && $0.state != .browserClosed }) {
                Button("Allow", action: onAllow).buttonStyle(.glass)
            }
        }
    }
}

/// The three permission rows, shared by the Permissions window and the settings' Permissions section.
/// Their Events go out through `onEvento`.
struct RighePermessi: View {
    let model: PermessiModel
    let onEvento: (EventoUtente) -> Void

    var body: some View {
        RigaPermesso(
            title: "Accessibility",
            explanation: "Lets Axi read the windows and use the Spotlight and Dictation keys.",
            granted: model.accessibilityGranted,
            onAllow: { onEvento(.chiedePermesso(.accessibility)) })
        RigaPermesso(
            title: "Screen Recording",
            explanation: "Lets Axi read the screen when you ask it to.",
            granted: model.screenRecordingGranted,
            attesaRiapertura: model.attesaRiapertura,
            onAllow: { onEvento(.chiedePermesso(.screenRecording)) },
            onReopen: { onEvento(.riapreAxi) })
        RigaAutomazione(
            browsers: model.automations,
            onAllowFinder: { onEvento(.chiedePermesso(.finderAutomation)) },
            onAllow: { onEvento(.chiedePermesso(.browserAutomation)) })
    }
}
