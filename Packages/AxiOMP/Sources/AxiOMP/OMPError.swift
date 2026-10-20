import Foundation

/// Errors raised by the OMP connection. Messages are generic: they never carry document or conversation text.
public enum OMPError: Error, Sendable, Equatable {
    case notReady
    case unsupportedProtocol
    case frameTooLarge
    case invalidFrame
    case rejected(command: String, message: String)
    case timedOut(command: String)
    case processExited
    case aborted
    case promptFailed(message: String)
    case localCommand
    case invalidSessionName
}

extension OMPError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notReady: "OMP non è pronto."
        case .unsupportedProtocol: "La versione del protocollo OMP non è supportata."
        case .frameTooLarge: "Un messaggio di OMP supera il limite consentito."
        case .invalidFrame: "Un messaggio di OMP non è valido."
        case .rejected(let command, _): "OMP ha rifiutato il comando \(command)."
        case .timedOut(let command): "OMP non ha risposto al comando \(command) in tempo."
        case .processExited: "Il processo OMP si è chiuso."
        case .aborted: "La risposta di OMP è stata interrotta."
        case .promptFailed: "OMP non è riuscito a completare la richiesta."
        case .localCommand: "OMP ha eseguito un comando locale invece di rispondere."
        case .invalidSessionName: "Il nome della sessione OMP non è valido."
        }
    }
}
