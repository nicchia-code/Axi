import AxiCore
import SwiftUI

/// The welcome window: a centered, step-by-step card with a step indicator.
struct BenvenutoView: View {
    @Bindable var model: BenvenutoModel
    let close: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 20) {
            StepIndicator(step: model.flow.step)

            Group {
                switch model.flow.step {
                case .permissions:
                    PermissionsStep(model: model)
                case .modelDownload:
                    DownloadStep(model: model)
                case .downloadFailed:
                    DownloadFailedStep(model: model)
                case .completed:
                    EmptyView()
                }
            }
            .transition(stepTransition)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding(28)
        .frame(width: 520, height: 470)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .smooth, value: model.flow.step)
        .task { await model.watchPermissions() }
        .task { await model.watchOMP() }
        .onChange(of: model.flow.step) { _, step in
            if step == .completed { close() }
        }
    }

    private var stepTransition: AnyTransition {
        reduceMotion
            ? .opacity
            : .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity))
    }
}

private struct StepIndicator: View {
    let step: BenvenutoStep

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<2, id: \.self) { index in
                Capsule()
                    .fill(index == currentIndex ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: index == currentIndex ? 28 : 10, height: 6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Step \(currentIndex + 1) of 2"))
    }

    private var currentIndex: Int {
        switch step {
        case .permissions: 0
        case .modelDownload, .downloadFailed, .completed: 1
        }
    }
}

private struct PermissionsStep: View {
    let model: BenvenutoModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Welcome to Axi").font(.title2.bold())
            Text("Axi needs these permissions. You can go on without them: features that need one stay limited until it is granted.")
                .foregroundStyle(.secondary)

            RighePermessi(model: model.permessi, onEvento: { model.invia($0) })

            ompRow

            Spacer(minLength: 0)
            HStack {
                Spacer()
                Button("Continue") { model.proceedToDownload() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.glassProminent)
            }
        }
    }

    private var ompRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: ompIcon)
                    .foregroundStyle(model.statoOMP == .ready ? .green : .secondary)
                Text(ompTitle)
                Spacer()
            }
            if case .unavailable(let motivo) = model.statoOMP {
                Text(motivo.message).foregroundStyle(.secondary)
            }
        }
        .padding(.top, 4)
    }

    private var ompTitle: LocalizedStringKey {
        switch model.statoOMP {
        case .starting: "OMP starting"
        case .ready: "OMP found"
        case .unavailable: "OMP not available"
        }
    }

    private var ompIcon: String {
        switch model.statoOMP {
        case .starting: "circle.dashed"
        case .ready: "checkmark.circle.fill"
        case .unavailable: "xmark.circle"
        }
    }
}

private struct DownloadStep: View {
    let model: BenvenutoModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Downloading the search model").font(.title2.bold())
            Text("Axi downloads the model it uses to search your vault. It stays on this Mac.")
                .foregroundStyle(.secondary)
            DownloadProgressView(progress: model.downloadProgress)
            Spacer(minLength: 0)
        }
    }
}

private struct DownloadFailedStep: View {
    let model: BenvenutoModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Download failed").font(.title2.bold())
            Text(model.failureMessage ?? "The model could not be downloaded.")
                .foregroundStyle(.secondary)
            DownloadProgressView(progress: model.downloadProgress)
            Spacer(minLength: 0)
            HStack {
                Spacer()
                Button("Retry") { model.retryDownload() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.glassProminent)
            }
        }
    }
}

private struct DownloadProgressView: View {
    let progress: ModelDownloadProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: fraction)
            Text("\(format(progress.receivedBytes)) of \(format(progress.totalBytes))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private var fraction: Double {
        guard progress.totalBytes > 0 else { return 0 }
        return min(1, Double(progress.receivedBytes) / Double(progress.totalBytes))
    }

    private func format(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
