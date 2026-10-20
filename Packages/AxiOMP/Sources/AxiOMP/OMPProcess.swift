import Foundation
import os
import Synchronization

/// What to start: the executable, its arguments and the folder it runs in.
struct OMPLaunchRequest: Sendable, Equatable {
    var executable: URL
    var arguments: [String]
    var workingDirectory: URL
}

/// One running OMP process, seen through its stdin and stdout.
protocol OMPRunningProcess: AnyObject, Sendable {
    /// The raw stdout bytes, finished when the process exits.
    var output: AsyncStream<Data> { get }
    /// Writes one complete block of bytes to stdin.
    func write(_ data: Data) throws
    /// Suspends until the process exits and returns its status.
    func waitForExit() async -> Int32
    /// Asks the process to stop.
    func terminate()
}

/// Starts OMP processes. Tests replace it with an in-process fake.
protocol OMPLaunching: Sendable {
    func launch(_ request: OMPLaunchRequest) throws -> any OMPRunningProcess
}

/// Starts real `omp` processes with Foundation `Process`.
struct OMPProcessLauncher: OMPLaunching {
    func launch(_ request: OMPLaunchRequest) throws -> any OMPRunningProcess {
        // A write to a process that already exited must fail with an error, not stop Axi.
        signal(SIGPIPE, SIG_IGN)
        return try OMPSystemProcess(request: request)
    }
}

/// `Process`-backed implementation. Stderr goes to the log, never to the parser.
final class OMPSystemProcess: OMPRunningProcess, @unchecked Sendable {
    private struct ExitState {
        var status: Int32?
        var waiters: [CheckedContinuation<Int32, Never>] = []
    }

    private static let log = Logger(subsystem: "Axi", category: "OMP")

    private let process = Process()
    private let stdinPipe = Pipe()
    private let stdoutPipe = Pipe()
    private let stderrPipe = Pipe()
    private let outputContinuation: AsyncStream<Data>.Continuation
    let output: AsyncStream<Data>
    private let exit = Mutex(ExitState())

    init(request: OMPLaunchRequest) throws {
        var continuation: AsyncStream<Data>.Continuation?
        output = AsyncStream(bufferingPolicy: .unbounded) { continuation = $0 }
        outputContinuation = continuation!

        process.executableURL = request.executable
        process.arguments = request.arguments
        process.currentDirectoryURL = request.workingDirectory
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        stdoutPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard let self else { return }
            if data.isEmpty {
                handle.readabilityHandler = nil
            } else {
                self.outputContinuation.yield(data)
            }
        }
        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                handle.readabilityHandler = nil
                return
            }
            // Only the size is logged: the text may contain document or conversation content.
            Self.log.debug("omp stderr: \(data.count, privacy: .public) bytes")
        }
        process.terminationHandler = { [weak self] finished in
            guard let self else { return }
            self.stdoutPipe.fileHandleForReading.readabilityHandler = nil
            if let rest = try? self.stdoutPipe.fileHandleForReading.readToEnd(), !rest.isEmpty {
                self.outputContinuation.yield(rest)
            }
            self.outputContinuation.finish()
            let status = finished.terminationStatus
            let waiters = self.exit.withLock { state -> [CheckedContinuation<Int32, Never>] in
                state.status = status
                let waiting = state.waiters
                state.waiters = []
                return waiting
            }
            for waiter in waiters {
                waiter.resume(returning: status)
            }
        }

        do {
            try process.run()
        } catch {
            outputContinuation.finish()
            throw error
        }
    }

    func write(_ data: Data) throws {
        try stdinPipe.fileHandleForWriting.write(contentsOf: data)
    }

    func waitForExit() async -> Int32 {
        await withCheckedContinuation { continuation in
            exit.withLock { state in
                if let status = state.status {
                    continuation.resume(returning: status)
                } else {
                    state.waiters.append(continuation)
                }
            }
        }
    }

    func terminate() {
        if process.isRunning {
            process.terminate()
        }
    }
}
