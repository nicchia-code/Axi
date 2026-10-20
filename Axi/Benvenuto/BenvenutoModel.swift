import AxiCore
import AxiEmbedding
import AxiOMP
import Foundation
import Observation

/// State of the welcome window: the step, the permission readings and the model download.
@MainActor
@Observable
final class BenvenutoModel {
    /// Hugging Face repository of the 8-bit MLX checkpoint of EmbeddingGemma 2 (`google/embeddinggemma-2`).
    static let embeddingRepository = "mlx-community/embeddinggemma-2-8bit"

    private(set) var flow = BenvenutoFlow()
    /// The permission rows: the same readings and requests as the Permissions window, shared with the app.
    let permessi: PermessiModel
    private(set) var statoOMP: OMPConnectionState = .starting
    private(set) var downloadProgress = ModelDownloadProgress(receivedBytes: 0, totalBytes: 0)
    private(set) var failureMessage: String?

    private let omp: OMPConnection
    private let store: BenvenutoStore
    private let modelFolder: URL
    /// The app's router: the Events of the permission rows go through it to the Machine that asks macOS.
    private let sink: @MainActor (EventoUtente) -> Void

    init(
        omp: OMPConnection,
        permessi: PermessiModel,
        sink: @escaping @MainActor (EventoUtente) -> Void,
        store: BenvenutoStore = BenvenutoStore(fileURL: BenvenutoStore.defaultFileURL),
        modelFolder: URL = TextEmbedder.defaultModelDirectory
    ) {
        self.omp = omp
        self.permessi = permessi
        self.sink = sink
        self.store = store
        self.modelFolder = modelFolder
    }

    // MARK: Permissions

    /// Re-reads the permissions every second while the window is visible, so the rows update by themselves.
    func watchPermissions() async {
        while !Task.isCancelled {
            permessi.refresh()
            try? await Task.sleep(for: .seconds(1))
        }
    }

    // MARK: OMP

    /// Follows the OMP connection state while the window is open, as the Settings window does.
    /// Subscribes before reading the state, so a change in between is not lost.
    func watchOMP() async {
        let eventi = omp.events()
        statoOMP = await omp.state
        for await evento in eventi {
            switch evento {
            case .ready: statoOMP = .ready
            case let .unavailable(motivo): statoOMP = .unavailable(motivo)
            default: break
            }
        }
    }

    /// Sends an Event of a permission row to the app, which asks macOS for the permission as the Permissions window does.
    func invia(_ evento: EventoUtente) {
        sink(evento)
    }

    // MARK: Steps

    /// `utente.PROSEGUE`: goes on even without all permissions; the features that need them stay limited.
    func proceedToDownload() {
        flow.apply(.userContinues)
        startDownload()
    }

    /// `utente.RIPROVA_DOWNLOAD`
    func retryDownload() {
        flow.apply(.userRetriesDownload)
        startDownload()
    }

    private func startDownload() {
        guard flow.step == .modelDownload else { return }
        failureMessage = nil
        downloadProgress = ModelDownloadProgress(receivedBytes: 0, totalBytes: 0)
        let downloader = ModelDownloader(repository: Self.embeddingRepository, destination: modelFolder)
        Task {
            do {
                try await downloader.download { [weak self] progress in
                    Task { @MainActor in self?.downloadProgress = progress }
                }
            } catch {
                fail(Self.describe(error))
                return
            }
            // A complete download is not enough: the model must load and answer before the welcome is completed.
            do {
                try await TextEmbedder.verify(modelDirectory: modelFolder)
            } catch {
                // Remove the files, so that Retry downloads the model again instead of reusing the broken copy.
                try? FileManager.default.removeItem(at: modelFolder)
                fail("The model was downloaded but does not work (\(error.localizedDescription)). Try again to download it.")
                return
            }
            do {
                try store.markCompleted()
            } catch {
                fail(Self.describe(error))
                return
            }
            flow.apply(.modelDownloaded)
            LaunchAtLogin.enableOnceAtWelcomeCompletion()
        }
    }

    private func fail(_ message: String) {
        failureMessage = message
        flow.apply(.downloadFailed)
    }

    private static func describe(_ error: Error) -> String {
        switch error as? ModelDownloadError {
        case .catalog(let detail):
            "The model repository could not be read (\(detail)). Check the connection and try again."
        case .http(let code):
            "The server answered with error \(code). Try again later."
        case .integrity(let file):
            "The file \(file) did not match its checksum and was removed. Try again."
        case .io(let detail):
            "The model could not be saved (\(detail))."
        case nil:
            "The download was interrupted: \(error.localizedDescription)"
        }
    }
}
