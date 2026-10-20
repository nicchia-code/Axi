import Foundation
import os

/// The two OMP processes Axi runs: one for the archive, one for chat.
public enum OMPRole: String, Sendable {
    case archive
    case chat
}

/// A model OMP can use, identified by `provider/modelID`.
public struct OMPModel: Sendable, Equatable {
    public let provider: String
    public let modelID: String
    public let name: String

    public var key: String { "\(provider)/\(modelID)" }

    public init(provider: String, modelID: String, name: String) {
        self.provider = provider
        self.modelID = modelID
        self.name = name
    }
}

/// Speaks the OMP RPC protocol (version 2) with one OMP process.
/// Each process runs one turn at a time; `prompt` waits for the turn lock.
public actor OMPClient {
    private struct Pending {
        let command: String
        let complete: (Result<JSONValue, Error>) -> Void
        let timeout: Task<Void, Never>?
    }

    private struct ActiveTurn {
        let onTextDelta: @Sendable (String) -> Void
        let onMessageStart: @Sendable () -> Void
        let onActivity: @Sendable (OMPActivity) -> Void
        let completion: CheckedContinuation<String, Error>
        var text = ""
        var finalText: String?
    }

    private static let log = Logger(subsystem: "Axi", category: "OMP")
    private static let protocolVersion = 2

    public let role: OMPRole
    private let process: any OMPRunningProcess
    private let dispatcher: OMPHostToolDispatcher
    private var reader = OMPFrameReader()
    private var nextID = 0
    private var pending: [String: Pending] = [:]
    private var readyFrame: JSONValue?
    private var activeTurn: ActiveTurn?
    private var turnLocked = false
    private var turnWaiters: [CheckedContinuation<Void, Never>] = []
    private var currentSession: URL?
    private var hostTasks: [String: Task<Void, Never>] = [:]
    private var closed = false

    init(role: OMPRole, process: any OMPRunningProcess, dispatcher: OMPHostToolDispatcher) {
        self.role = role
        self.process = process
        self.dispatcher = dispatcher
        Task { await self.readLoop() }
    }

    /// Waits for the `ready` frame and negotiates protocol version 2, then registers the host tools.
    public func start(readyTimeout: Duration = .seconds(30)) async throws {
        let ready = try await waitForReady(timeout: readyTimeout)
        let versions = ready["supportedProtocolVersions"]?.array?.compactMap(\.int) ?? []
        guard versions.contains(Self.protocolVersion) else { throw OMPError.unsupportedProtocol }
        if let maxFrame = ready["maxFrameBytes"]?.int, let maxReassembled = ready["maxReassembledFrameBytes"]?.int {
            reader.configure(limits: OMPFrameLimits(maxFrameBytes: maxFrame, maxReassembledBytes: maxReassembled))
        }
        let negotiated = try await request("negotiate_protocol", ["protocolVersion": .number(Double(Self.protocolVersion))])
        guard negotiated["protocolVersion"]?.int == Self.protocolVersion else { throw OMPError.unsupportedProtocol }
        _ = try await request("set_host_tools", ["tools": .array(OMPHostToolDispatcher.definitions)])
    }

    /// Changes the model of the running process. `key` is `provider/modelID`.
    public func setModel(_ key: String) async throws {
        guard let slash = key.firstIndex(of: "/") else {
            throw OMPError.rejected(command: "set_model", message: "")
        }
        let provider = String(key[..<slash])
        let modelID = String(key[key.index(after: slash)...])
        guard !provider.isEmpty, !modelID.isEmpty else {
            throw OMPError.rejected(command: "set_model", message: "")
        }
        _ = try await request("set_model", ["provider": .string(provider), "modelId": .string(modelID)])
    }

    /// The models OMP can use with the credentials it has.
    public func availableModels() async throws -> [OMPModel] {
        let data = try await request("get_available_models")
        let entries = data["models"]?.array ?? []
        return entries.compactMap { entry in
            guard let id = entry["id"]?.string, let provider = entry["provider"]?.string else { return nil }
            return OMPModel(provider: provider, modelID: id, name: entry["name"]?.string ?? id)
        }
    }

    /// The context window, in tokens, of the model this process uses; nil when OMP reports no limit.
    public func contextWindowTokens() async throws -> Int? {
        let data = try await request("get_state")
        return data["model"]?["contextWindow"]?.int
    }

    /// The thinking levels the live model offers, `off` first; empty when it offers none.
    public func availableThinkingLevels() async throws -> [String] {
        let data = try await request("get_available_thinking_levels")
        return data["levels"]?.array?.compactMap { $0.string } ?? []
    }

    /// Sets the thinking level of the live model.
    public func setThinkingLevel(_ level: String) async throws {
        _ = try await request("set_thinking_level", ["level": .string(level)])
    }

    /// The `provider/modelID` key of the model this process uses; nil when OMP reports none.
    public func currentModelKey() async throws -> String? {
        let data = try await request("get_state")
        guard let provider = data["model"]?["provider"]?.string, let id = data["model"]?["id"]?.string else {
            return nil
        }
        return "\(provider)/\(id)"
    }

    /// Sends one user message and returns the final assistant text.
    /// `onTextDelta` receives the text as it streams; `onMessageStart` is called when OMP starts an assistant message. `sessionDirectory` resumes the session kept there.
    public func prompt(
        _ message: String,
        sessionDirectory: URL? = nil,
        onTextDelta: @escaping @Sendable (String) -> Void = { _ in },
        onMessageStart: @escaping @Sendable () -> Void = {},
        onActivity: @escaping @Sendable (OMPActivity) -> Void = { _ in }
    ) async throws -> String {
        guard !closed else { throw OMPError.processExited }
        await acquireTurn()
        defer { releaseTurn() }
        try Task.checkCancellation()
        guard !closed else { throw OMPError.processExited }
        if let sessionDirectory, sessionDirectory != currentSession {
            _ = try await request("open_session", ["sessionDir": .string(sessionDirectory.path)])
            currentSession = sessionDirectory
        }
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                activeTurn = ActiveTurn(onTextDelta: onTextDelta, onMessageStart: onMessageStart, onActivity: onActivity, completion: continuation)
                dispatch(command: "prompt", fields: ["message": .string(message)], timeout: nil) { [weak self] result in
                    if case .failure(let error) = result {
                        Task { await self?.failTurn(error) }
                    }
                }
            }
        } onCancel: {
            Task { await self.abort() }
        }
    }

    /// Stops the running turn; its `prompt` call then throws `OMPError.aborted`.
    public func abort() async {
        guard activeTurn != nil else { return }
        _ = try? await request("abort")
    }

    /// Suspends until the process exits and returns its status.
    public func waitForExit() async -> Int32 {
        await process.waitForExit()
    }

    /// Stops the process. Pending calls fail with `OMPError.processExited`.
    public func shutdown() {
        close(with: OMPError.processExited)
        process.terminate()
    }

    // MARK: - Turn lock

    private func acquireTurn() async {
        if !turnLocked {
            turnLocked = true
            return
        }
        await withCheckedContinuation { turnWaiters.append($0) }
    }

    private func releaseTurn() {
        if turnWaiters.isEmpty {
            turnLocked = false
        } else {
            turnWaiters.removeFirst().resume()
        }
    }

    // MARK: - Requests

    private func request(
        _ command: String,
        _ fields: [String: JSONValue] = [:],
        timeout: Duration = .seconds(30)
    ) async throws -> JSONValue {
        try await withCheckedThrowingContinuation { continuation in
            dispatch(command: command, fields: fields, timeout: timeout) { result in
                continuation.resume(with: result)
            }
        }
    }

    private func waitForReady(timeout: Duration) async throws -> JSONValue {
        if let readyFrame { return readyFrame }
        return try await withCheckedThrowingContinuation { continuation in
            let timeoutTask = Task { [weak self] in
                try? await Task.sleep(for: timeout)
                await self?.expire("ready")
            }
            pending["ready"] = Pending(command: "ready", complete: { continuation.resume(with: $0) }, timeout: timeoutTask)
        }
    }

    /// Sends a request frame and remembers how to complete it when its response arrives.
    private func dispatch(
        command: String,
        fields: [String: JSONValue],
        timeout: Duration?,
        completion: @escaping (Result<JSONValue, Error>) -> Void
    ) {
        nextID += 1
        let id = "req_\(nextID)"
        var frame = fields
        frame["type"] = .string(command)
        frame["id"] = .string(id)
        do {
            try send(.object(frame))
        } catch {
            completion(.failure(error))
            return
        }
        let timeoutTask: Task<Void, Never>? = timeout.map { duration in
            Task { [weak self] in
                try? await Task.sleep(for: duration)
                await self?.expire(id)
            }
        }
        pending[id] = Pending(command: command, complete: completion, timeout: timeoutTask)
    }

    private func expire(_ id: String) {
        guard let entry = pending.removeValue(forKey: id) else { return }
        entry.complete(.failure(OMPError.timedOut(command: entry.command)))
    }

    private func resolve(_ id: String, with result: Result<JSONValue, Error>) {
        guard let entry = pending.removeValue(forKey: id) else { return }
        entry.timeout?.cancel()
        entry.complete(result)
    }

    private func send(_ frame: JSONValue) throws {
        guard !closed else { throw OMPError.processExited }
        let data = try OMPFrameWriter.encode(frame, limits: reader.limits)
        try process.write(data)
    }

    // MARK: - Incoming frames

    private func readLoop() async {
        for await data in process.output {
            do {
                for frame in try reader.append(data) {
                    handle(frame)
                }
            } catch {
                Self.log.error("omp sent an invalid frame; stopping the process")
                process.terminate()
                close(with: error)
                return
            }
        }
        close(with: OMPError.processExited)
    }

    private func handle(_ frame: JSONValue) {
        switch frame["type"]?.string {
        case "ready":
            if let entry = pending.removeValue(forKey: "ready") {
                entry.timeout?.cancel()
                entry.complete(.success(frame))
            } else {
                readyFrame = frame
            }
        case "response":
            guard let id = frame["id"]?.string else { return }
            if frame["success"]?.bool == true {
                resolve(id, with: .success(frame["data"] ?? .null))
            } else {
                let command = frame["command"]?.string ?? pending[id]?.command ?? ""
                resolve(id, with: .failure(OMPError.rejected(command: command, message: frame["error"]?.string ?? "")))
            }
        case "rpc_frame_error":
            Self.log.error("omp rejected a frame")
            if let id = frame["id"]?.string {
                resolve(id, with: .failure(OMPError.invalidFrame))
            }
        case "message_update":
            guard let event = frame["assistantMessageEvent"], activeTurn != nil,
                  let delta = event["delta"]?.string
            else { return }
            switch event["type"]?.string {
            case "text_delta":
                activeTurn?.text += delta
                activeTurn?.onTextDelta(delta)
            case "thinking_delta":
                activeTurn?.onActivity(.thinking(delta))
            default:
                return
            }
        case "message_start":
            guard frame["message"]?["role"]?.string == "assistant", activeTurn != nil else { return }
            activeTurn?.text = ""
            activeTurn?.onMessageStart()
        case "agent_end":
            if let text = Self.assistantText(frame["messages"]) {
                activeTurn?.finalText = text
            }
        case "prompt_result":
            finishTurn(frame)
        case "host_tool_call":
            startHostTool(frame)
        case "auto_retry_start":
            if activeTurn != nil, let attempt = frame["attempt"]?.int, let maximum = frame["maxAttempts"]?.int {
                activeTurn?.onActivity(.retryStarted(attempt: attempt, maxAttempts: maximum))
            }
        case "auto_retry_end":
            activeTurn?.onActivity(.retryEnded)
        case "auto_compaction_start":
            activeTurn?.onActivity(.compactionStarted)
        case "auto_compaction_end":
            activeTurn?.onActivity(.compactionEnded)
        case "host_tool_cancel":
            let target = frame["targetId"]?.string ?? frame["id"]?.string
            if let target {
                hostTasks.removeValue(forKey: target)?.cancel()
            }
        default:
            break
        }
    }

    private func finishTurn(_ frame: JSONValue) {
        guard let turn = activeTurn else { return }
        activeTurn = nil
        switch frame["status"]?.string {
        case "completed":
            if frame["agentInvoked"]?.bool == false {
                turn.completion.resume(throwing: OMPError.localCommand)
            } else {
                turn.completion.resume(returning: turn.finalText ?? turn.text)
            }
        case "aborted", "cancelled":
            turn.completion.resume(throwing: OMPError.aborted)
        default:
            turn.completion.resume(throwing: OMPError.promptFailed(message: Self.errorMessage(frame["error"])))
        }
    }

    private func failTurn(_ error: Error) {
        guard let turn = activeTurn else { return }
        activeTurn = nil
        turn.completion.resume(throwing: error)
    }

    private func startHostTool(_ frame: JSONValue) {
        guard let callID = frame["id"]?.string, let name = frame["toolName"]?.string else { return }
        let arguments = frame["arguments"] ?? .object([:])
        activeTurn?.onActivity(.toolStarted(id: callID, name: name, arguments: arguments))
        let dispatcher = self.dispatcher
        hostTasks[callID] = Task {
            let output = await dispatcher.handle(toolName: name, arguments: arguments)
            guard !Task.isCancelled else { return }
            self.finishHostTool(id: callID, output: output)
        }
    }

    private func finishHostTool(id: String, output: OMPHostToolDispatcher.Output) {
        hostTasks[id] = nil
        activeTurn?.onActivity(.toolFinished(id: id))
        let result: JSONValue = .object([
            "content": .array([.object(["type": .string("text"), "text": .string(output.text)])]),
            "details": .object([:]),
        ])
        var frame: [String: JSONValue] = [
            "type": .string("host_tool_result"),
            "id": .string(id),
            "result": result,
        ]
        if output.isError {
            frame["isError"] = .bool(true)
        }
        try? send(.object(frame))
    }

    private func close(with error: Error) {
        closed = true
        let entries = pending
        pending = [:]
        for entry in entries.values {
            entry.timeout?.cancel()
            entry.complete(.failure(error))
        }
        if let turn = activeTurn {
            activeTurn = nil
            turn.completion.resume(throwing: error)
        }
        for task in hostTasks.values {
            task.cancel()
        }
        hostTasks = [:]
    }

    /// The text of the last assistant message, if it has any.
    private static func assistantText(_ messages: JSONValue?) -> String? {
        guard let list = messages?.array,
              let last = list.last(where: { $0["role"]?.string == "assistant" })
        else { return nil }
        if let text = last["content"]?.string {
            return text
        }
        guard let blocks = last["content"]?.array else { return nil }
        return blocks.compactMap { block -> String? in
            guard block["type"]?.string == "text" else { return nil }
            return block["text"]?.string
        }.joined()
    }

    private static func errorMessage(_ error: JSONValue?) -> String {
        error?.string ?? error?["message"]?.string ?? ""
    }
}
