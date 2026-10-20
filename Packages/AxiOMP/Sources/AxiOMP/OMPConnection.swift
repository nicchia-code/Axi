import Foundation

/// Why the OMP connection is not available. `message` is shown to the user in Italian.
public enum OMPUnavailableReason: Sendable, Equatable {
    case notFound
    case failedToStart
    case stoppedAgain

    public var message: String {
        switch self {
        case .notFound: "OMP non è installato o il percorso configurato non è valido."
        case .failedToStart: "OMP non è riuscito ad avviarsi."
        case .stoppedAgain: "OMP si è chiuso di nuovo subito dopo il riavvio."
        }
    }
}

/// Starting, ready, or unavailable (Avvio, Pronta, Non disponibile).
public enum OMPConnectionState: Sendable, Equatable {
    case starting
    case ready
    case unavailable(OMPUnavailableReason)
}

/// The connection state machine, without side effects: it returns the effects to perform.
struct OMPConnectionMachine {
    enum Input: Equatable {
        case started
        case ready
        case failed(OMPUnavailableReason)
        case exited
        case userChangedPath
    }

    enum Effect: Equatable {
        case publish(OMPEvent)
        case launch
        case stop
    }

    /// A second stop within this interval after a restart makes the connection unavailable.
    static let restartWindow: TimeInterval = 30

    private(set) var state: OMPConnectionState = .starting
    private(set) var lastRestart: Date?

    mutating func handle(_ input: Input, at now: Date) -> [Effect] {
        switch (state, input) {
        case (.starting, .started):
            return [.launch]
        case (.starting, .ready):
            state = .ready
            return [.publish(.ready)]
        case (.starting, .failed(let reason)):
            return unavailable(reason)
        case (.starting, .exited) where lastRestart != nil:
            return stopped(at: now, reportTerminated: false)
        case (.starting, .exited):
            return unavailable(.failedToStart)
        case (.ready, .exited):
            return stopped(at: now, reportTerminated: true)
        case (.unavailable, .userChangedPath):
            lastRestart = nil
            state = .starting
            return [.publish(.starting), .stop, .launch]
        default:
            return []
        }
    }

    private mutating func unavailable(_ reason: OMPUnavailableReason) -> [Effect] {
        state = .unavailable(reason)
        return [.publish(.unavailable(reason)), .stop]
    }

    /// An exit from "Pronta" or while restarting: a second exit within the window makes the connection
    /// unavailable; otherwise OMP is restarted. `terminated` is reported only for the exit from "Pronta".
    private mutating func stopped(at now: Date, reportTerminated: Bool) -> [Effect] {
        let terminated: [Effect] = reportTerminated ? [.publish(.terminated)] : []
        if let lastRestart, now.timeIntervalSince(lastRestart) <= Self.restartWindow {
            return terminated + unavailable(.stoppedAgain)
        }
        lastRestart = now
        state = .starting
        return terminated + [.publish(.starting), .stop, .launch]
    }
}

/// Runs the archive and chat OMP processes and keeps them ready for Axi.
public actor OMPConnection {
    private let dataDirectory: URL
    private let dispatcher: OMPHostToolDispatcher
    private let launcher: any OMPLaunching
    private let resolveExecutable: @Sendable (String?) -> URL?
    private let now: @Sendable () -> Date
    private let hub = OMPEventHub()
    private var machine = OMPConnectionMachine()
    private var generation = 0
    private var executablePath: String?
    private var model: String?
    private var archiveClient: OMPClient?
    private var chatClient: OMPClient?

    public var state: OMPConnectionState { machine.state }

    /// `dataDirectory` holds the OMP working folder and one session folder per conversation.
    public init(
        dataDirectory: URL,
        chatTools: any OMPChatHostTools,
        vaultTools: any OMPVaultHostTools
    ) {
        self.init(
            dataDirectory: dataDirectory,
            chatTools: chatTools,
            vaultTools: vaultTools,
            launcher: OMPProcessLauncher(),
            resolveExecutable: { OMPLocator.resolve(configuredPath: $0) },
            now: { Date() }
        )
    }

    init(
        dataDirectory: URL,
        chatTools: any OMPChatHostTools,
        vaultTools: any OMPVaultHostTools,
        launcher: any OMPLaunching,
        resolveExecutable: @escaping @Sendable (String?) -> URL?,
        now: @escaping @Sendable () -> Date
    ) {
        self.dataDirectory = dataDirectory
        self.launcher = launcher
        self.resolveExecutable = resolveExecutable
        self.now = now
        self.dispatcher = OMPHostToolDispatcher(chat: chatTools, vault: vaultTools, events: hub)
    }

    /// Events of the connection, from the moment of subscription.
    public nonisolated func events() -> AsyncStream<OMPEvent> {
        hub.events()
    }

    /// Starts both processes. `executablePath` nil means: look for `omp`.
    public func start(executablePath: String?, model: String?) async {
        self.executablePath = executablePath
        self.model = model
        await run(.started)
    }

    /// Uses a new `omp` path: restarts the processes, or retries after "Non disponibile".
    public func changePath(_ path: String?) async {
        executablePath = path
        await run(.userChangedPath)
    }

    /// Changes the model of both processes. `key` is `provider/modelID`.
    public func setModel(_ key: String) async throws {
        if let archive = archiveClient, let chat = chatClient, machine.state == .ready {
            try await archive.setModel(key)
            try await chat.setModel(key)
        }
        model = key
    }

    /// The models available to the archive process.
    public func availableModels() async throws -> [OMPModel] {
        try await archive().availableModels()
    }

    /// The model OMP uses for the sessions, as `provider/modelID`; nil when OMP reports none.
    public func currentModelKey() async throws -> String? {
        try await archive().currentModelKey()
    }

    /// The archive process, only while the connection is ready.
    public func archive() throws -> OMPClient {
        guard machine.state == .ready, let archiveClient else { throw OMPError.notReady }
        return archiveClient
    }

    /// The chat process, only while the connection is ready.
    public func chat() throws -> OMPClient {
        guard machine.state == .ready, let chatClient else { throw OMPError.notReady }
        return chatClient
    }

    /// The session folder of a conversation. The identifier must be a plain name.
    public func sessionDirectory(forConversation conversationID: String) throws -> URL {
        let valid = !conversationID.isEmpty
            && conversationID.count <= 128
            && conversationID.unicodeScalars.allSatisfy { scalar in
                scalar.value < 128
                    && (CharacterSet.alphanumerics.contains(scalar) || scalar == "-" || scalar == "_")
            }
        guard valid else { throw OMPError.invalidSessionName }
        return sessionsDirectory.appending(path: conversationID, directoryHint: .isDirectory)
    }

    /// Stops both processes without restarting them.
    public func shutdown() async {
        await stopProcesses()
    }

    // MARK: - Private

    private var sessionsDirectory: URL {
        dataDirectory.appending(path: "omp-sessioni", directoryHint: .isDirectory)
    }

    private func run(_ input: OMPConnectionMachine.Input) async {
        let effects = machine.handle(input, at: now())
        for effect in effects {
            switch effect {
            case .publish(let event):
                hub.publish(event)
            case .stop:
                await stopProcesses()
            case .launch:
                await launchProcesses()
            }
        }
    }

    private func launchProcesses() async {
        await stopProcesses()
        let current = generation
        let path = executablePath
        let resolver = resolveExecutable
        let found = await Task.detached { resolver(path) }.value
        guard let executable = found else {
            await run(.failed(.notFound))
            return
        }
        do {
            try FileManager.default.createDirectory(at: sessionsDirectory, withIntermediateDirectories: true)
            let archive = try makeClient(.archive, executable: executable)
            archiveClient = archive
            try await archive.start()
            guard current == generation else { return }
            watchExit(of: archive, generation: current)
            let chat = try makeClient(.chat, executable: executable)
            chatClient = chat
            try await chat.start()
            guard current == generation else { return }
            watchExit(of: chat, generation: current)
            // The mini-chat answers at the lowest thinking level the model offers; the archive keeps its own.
            if let levels = try? await chat.availableThinkingLevels(), levels.contains("low") {
                try? await chat.setThinkingLevel("low")
            }
            await run(.ready)
        } catch {
            guard current == generation else { return }
            await run(.failed(.failedToStart))
        }
    }

    private func makeClient(_ role: OMPRole, executable: URL) throws -> OMPClient {
        let process = try launcher.launch(OMPLaunchRequest(
            executable: executable,
            arguments: arguments(for: role),
            workingDirectory: dataDirectory
        ))
        return OMPClient(role: role, process: process, dispatcher: dispatcher)
    }

    private func arguments(for role: OMPRole) -> [String] {
        var arguments = [
            "--mode=rpc",
            "--no-title",
            "--no-tools",
            "--no-extensions",
            "--no-skills",
            "--no-rules",
            "--no-lsp",
            "--no-ui",
            "--cwd=\(dataDirectory.path)",
        ]
        switch role {
        case .archive:
            arguments.append("--no-session")
        case .chat:
            arguments.append("--session-dir=\(sessionsDirectory.path)")
        }
        if let model, !model.isEmpty {
            arguments.append("--model=\(model)")
        }
        return arguments
    }

    private func watchExit(of client: OMPClient, generation current: Int) {
        Task { [weak self] in
            _ = await client.waitForExit()
            await self?.processExited(generation: current)
        }
    }

    private func processExited(generation current: Int) async {
        guard current == generation else { return }
        await run(.exited)
    }

    private func stopProcesses() async {
        generation += 1
        let archive = archiveClient
        let chat = chatClient
        archiveClient = nil
        chatClient = nil
        await archive?.shutdown()
        await chat?.shutdown()
    }
}
