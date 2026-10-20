import Foundation
import Synchronization

/// What the OMP connection tells the rest of Axi.
public enum OMPEvent: Sendable, Equatable {
    case starting
    case ready
    case unavailable(OMPUnavailableReason)
    case terminated
    case tagsChanged(documentID: String, tags: [String])
    case deletionRequested(documentID: String)
}

/// Fan-out of `OMPEvent` to every subscriber.
final class OMPEventHub: Sendable {
    private let subscribers = Mutex<[UUID: AsyncStream<OMPEvent>.Continuation]>([:])

    func events() -> AsyncStream<OMPEvent> {
        AsyncStream(bufferingPolicy: .unbounded) { continuation in
            let id = UUID()
            subscribers.withLock { $0[id] = continuation }
            continuation.onTermination = { [weak self] _ in
                self?.subscribers.withLock { _ = $0.removeValue(forKey: id) }
            }
        }
    }

    func publish(_ event: OMPEvent) {
        let current = subscribers.withLock { Array($0.values) }
        for continuation in current {
            continuation.yield(event)
        }
    }
}
