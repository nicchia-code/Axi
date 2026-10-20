import Foundation
import Synchronization
@testable import AxiOMP

/// Scripted stand-in for an `omp --mode rpc` process. It speaks the same JSON lines as the
/// real process: `responder` answers every frame the client writes.
final class FakeOMPProcess: OMPRunningProcess, @unchecked Sendable {
    typealias Responder = @Sendable (JSONValue) -> [JSONValue]

    private struct ExitState {
        var status: Int32?
        var waiters: [CheckedContinuation<Int32, Never>] = []
    }

    let output: AsyncStream<Data>
    private let continuation: AsyncStream<Data>.Continuation
    private let responder: Responder
    private let written = Mutex<[JSONValue]>([])
    private let exitState = Mutex(ExitState())

    init(supportedVersions: [Int] = [1, 2], responder: @escaping Responder) {
        var continuation: AsyncStream<Data>.Continuation?
        output = AsyncStream(bufferingPolicy: .unbounded) { continuation = $0 }
        self.continuation = continuation!
        self.responder = responder
        emit(.object([
            "type": .string("ready"),
            "protocolVersion": .number(1),
            "supportedProtocolVersions": .array(supportedVersions.map { .number(Double($0)) }),
            "maxFrameBytes": .number(1_048_576),
            "maxReassembledFrameBytes": .number(67_108_864),
        ]))
    }

    /// Every frame the client has written, in order.
    var writtenFrames: [JSONValue] {
        written.withLock { $0 }
    }

    func write(_ data: Data) throws {
        for line in data.split(separator: 0x0A) {
            let frame = try JSONDecoder().decode(JSONValue.self, from: Data(line))
            written.withLock { $0.append(frame) }
            for reply in responder(frame) {
                emit(reply)
            }
        }
    }

    func waitForExit() async -> Int32 {
        await withCheckedContinuation { continuation in
            exitState.withLock { state in
                if let status = state.status {
                    continuation.resume(returning: status)
                } else {
                    state.waiters.append(continuation)
                }
            }
        }
    }

    func terminate() {
        finish(status: 15)
    }

    /// Simulates OMP stopping on its own.
    func simulateExit(status: Int32 = 1) {
        finish(status: status)
    }

    private func emit(_ frame: JSONValue) {
        if let data = try? OMPFrameWriter.encode(frame, limits: .default) {
            continuation.yield(data)
        }
    }

    private func finish(status: Int32) {
        continuation.finish()
        let waiters = exitState.withLock { state -> [CheckedContinuation<Int32, Never>] in
            guard state.status == nil else { return [] }
            state.status = status
            let waiting = state.waiters
            state.waiters = []
            return waiting
        }
        for waiter in waiters {
            waiter.resume(returning: status)
        }
    }
}

/// Starts `FakeOMPProcess` instances and remembers them, in launch order.
final class FakeLauncher: OMPLaunching, @unchecked Sendable {
    enum Failure: Error {
        case refused
    }

    private let responder: FakeOMPProcess.Responder
    private let launches = Mutex<[OMPLaunchRequest]>([])
    private let started = Mutex<[FakeOMPProcess]>([])
    private let refusing = Mutex(false)

    init(responder: @escaping FakeOMPProcess.Responder) {
        self.responder = responder
    }

    var requests: [OMPLaunchRequest] {
        launches.withLock { $0 }
    }

    var launched: [FakeOMPProcess] {
        started.withLock { $0 }
    }

    func setRefusing(_ value: Bool) {
        refusing.withLock { $0 = value }
    }

    func launch(_ request: OMPLaunchRequest) throws -> any OMPRunningProcess {
        launches.withLock { $0.append(request) }
        if refusing.withLock({ $0 }) {
            throw Failure.refused
        }
        let process = FakeOMPProcess(responder: responder)
        started.withLock { $0.append(process) }
        return process
    }
}

/// A value that tests can read and change from escaping closures.
final class Box<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    init(_ value: Value) {
        self.value = value
    }

    var current: Value {
        lock.withLock { value }
    }

    func set(_ newValue: Value) {
        lock.withLock { value = newValue }
    }
}

/// Clock the connection uses instead of `Date()`.
final class TestClock: @unchecked Sendable {
    private let date = Box(Date(timeIntervalSince1970: 1_000_000))

    var now: Date {
        date.current
    }

    func advance(by seconds: TimeInterval) {
        date.set(now.addingTimeInterval(seconds))
    }
}

struct StubChatTools: OMPChatHostTools {
    func searchVault(query: String, limit: Int, filter: OMPSearchFilter) async throws -> [OMPSearchHit] {
        [OMPSearchHit(documentID: "doc-1", title: "Fattura", excerpt: query, archivedAt: Date(timeIntervalSince1970: 0))]
    }

    func readDocumentPage(documentID: String, page: Int) async throws -> OMPDocumentPage {
        OMPDocumentPage(documentID: documentID, page: page, text: "Testo della pagina")
    }

    func citeDocuments(_ citations: [OMPCitation]) async throws {}
}

struct StubVaultTools: OMPVaultHostTools {
    func setDocumentTags(documentID: String, tags: [String]) async throws {}

    func requestDocumentDeletion(documentID: String) async throws -> Bool { true }
}

/// Builders for the frames OMP sends.
enum FakeFrames {
    static func response(to frame: JSONValue, data: JSONValue = .object([:])) -> JSONValue {
        .object([
            "type": .string("response"),
            "id": .string(frame["id"]?.string ?? ""),
            "command": .string(frame["type"]?.string ?? ""),
            "success": .bool(true),
            "data": data,
        ])
    }

    static func failure(to frame: JSONValue, message: String) -> JSONValue {
        .object([
            "type": .string("response"),
            "id": .string(frame["id"]?.string ?? ""),
            "command": .string(frame["type"]?.string ?? ""),
            "success": .bool(false),
            "error": .string(message),
        ])
    }

    static func messageStart(role: String = "assistant") -> JSONValue {
        .object([
            "type": .string("message_start"),
            "message": .object(["role": .string(role)]),
        ])
    }

    static func messageDelta(_ delta: String) -> JSONValue {
        .object([
            "type": .string("message_update"),
            "assistantMessageEvent": .object([
                "type": .string("text_delta"),
                "delta": .string(delta),
                "contentIndex": .number(0),
            ]),
        ])
    }

    static func agentEnd(text: String) -> JSONValue {
        .object([
            "type": .string("agent_end"),
            "messages": .array([
                .object([
                    "role": .string("assistant"),
                    "content": .array([.object(["type": .string("text"), "text": .string(text)])]),
                ]),
            ]),
        ])
    }

    static func promptResult(status: String, agentInvoked: Bool = true, error: String? = nil) -> JSONValue {
        var object: [String: JSONValue] = [
            "type": .string("prompt_result"),
            "status": .string(status),
            "agentInvoked": .bool(agentInvoked),
            "sessionSettled": .bool(true),
        ]
        if let error {
            object["error"] = .object(["message": .string(error)])
        }
        return .object(object)
    }

    static func hostToolCall(id: String, name: String, arguments: JSONValue) -> JSONValue {
        .object([
            "type": .string("host_tool_call"),
            "id": .string(id),
            "toolCallId": .string("call-\(id)"),
            "toolName": .string(name),
            "arguments": arguments,
        ])
    }

    /// Acknowledges `prompt`, streams `deltas` and finishes the turn with `finalText`.
    static func completedTurn(for frame: JSONValue, deltas: [String], finalText: String) -> [JSONValue] {
        [response(to: frame)]
            + deltas.map { messageDelta($0) }
            + [agentEnd(text: finalText), promptResult(status: "completed")]
    }
}

enum FakeOMP {
    /// Answers the handshake and the setup commands. Every other command goes to `extra`.
    static func responder(extra: @escaping FakeOMPProcess.Responder = { _ in [] }) -> FakeOMPProcess.Responder {
        { frame in
            switch frame["type"]?.string {
            case "negotiate_protocol":
                [FakeFrames.response(to: frame, data: .object(["protocolVersion": .number(2)]))]
            case "set_host_tools":
                [FakeFrames.response(to: frame, data: .object(["toolNames": .array([])]))]
            case "set_model":
                [FakeFrames.response(to: frame)]
            case "open_session":
                [FakeFrames.response(to: frame, data: .object(["cancelled": .bool(false), "resumed": .bool(true)]))]
            case "get_available_models":
                [FakeFrames.response(to: frame, data: .object(["models": .array([
                    .object([
                        "id": .string("claude-x"),
                        "provider": .string("anthropic"),
                        "name": .string("Claude X"),
                    ]),
                ])]))]
            default:
                extra(frame)
            }
        }
    }
}
