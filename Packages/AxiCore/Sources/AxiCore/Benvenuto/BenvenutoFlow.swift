import Foundation

/// A step of the welcome window (Benvenuto).
public enum BenvenutoStep: Sendable, Equatable {
    case permissions
    case modelDownload
    case downloadFailed
    case completed
}

/// Events that move the welcome window from one step to the next.
public enum BenvenutoEvent: Sendable, Equatable {
    /// `utente.PROSEGUE`
    case userContinues
    /// `benvenuto.MODELLO_SCARICATO`
    case modelDownloaded
    /// `benvenuto.SCARICAMENTO_FALLITO`
    case downloadFailed
    /// `utente.RIPROVA_DOWNLOAD`
    case userRetriesDownload
}

/// Pure state machine of the welcome window. Events that the current step does not accept change nothing.
public struct BenvenutoFlow: Sendable, Equatable {
    public private(set) var step: BenvenutoStep

    public init(step: BenvenutoStep = .permissions) {
        self.step = step
    }

    public mutating func apply(_ event: BenvenutoEvent) {
        switch (step, event) {
        case (.permissions, .userContinues):
            step = .modelDownload
        case (.modelDownload, .modelDownloaded):
            step = .completed
        case (.modelDownload, .downloadFailed):
            step = .downloadFailed
        case (.downloadFailed, .userRetriesDownload):
            step = .modelDownload
        default:
            break
        }
    }
}
