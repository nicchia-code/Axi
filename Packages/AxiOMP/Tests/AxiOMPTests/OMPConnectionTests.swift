import Foundation
import Testing
@testable import AxiOMP

struct OMPConnectionTests {
    private let executable = URL(fileURLWithPath: "/fake/bin/omp")

    private func makeConnection(
        launcher: any OMPLaunching,
        resolve: @escaping @Sendable (String?) -> URL?,
        clock: TestClock = TestClock()
    ) -> OMPConnection {
        OMPConnection(
            dataDirectory: FileManager.default.temporaryDirectory
                .appending(path: "axi-omp-\(UUID().uuidString)", directoryHint: .isDirectory),
            chatTools: StubChatTools(),
            vaultTools: StubVaultTools(),
            launcher: launcher,
            resolveExecutable: resolve,
            now: { clock.now }
        )
    }

    @Test func startLaunchesTheArchiveAndChatProcesses() async throws {
        let launcher = FakeLauncher(responder: FakeOMP.responder())
        let connection = makeConnection(launcher: launcher, resolve: { _ in executable })
        var events = connection.events().makeAsyncIterator()

        await connection.start(executablePath: nil, model: "anthropic/claude-x")

        #expect(await connection.state == .ready)
        let first = await events.next()
        #expect(first == .ready)
        let requests = launcher.requests
        #expect(requests.count == 2)
        #expect(requests[0].arguments.contains("--no-session"))
        #expect(requests[1].arguments.contains { $0.hasPrefix("--session-dir=") })
        #expect(requests.allSatisfy { $0.arguments.contains("--mode=rpc") })
        #expect(requests.allSatisfy { $0.arguments.contains("--model=anthropic/claude-x") })
        await connection.shutdown()
    }

    @Test func processesAreUnavailableBeforeStart() async {
        let connection = makeConnection(launcher: FakeLauncher(responder: FakeOMP.responder()), resolve: { _ in executable })
        await #expect(throws: OMPError.notReady) {
            try await connection.archive()
        }
    }

    @Test func aMissingExecutableIsReportedAndCanBeFixedWithANewPath() async throws {
        let resolved = Box<URL?>(nil)
        let launcher = FakeLauncher(responder: FakeOMP.responder())
        let connection = makeConnection(launcher: launcher, resolve: { _ in resolved.current })
        var events = connection.events().makeAsyncIterator()

        await connection.start(executablePath: "/nope/omp", model: nil)

        #expect(await connection.state == .unavailable(.notFound))
        let unavailable = await events.next()
        #expect(unavailable == .unavailable(.notFound))
        #expect(launcher.requests.isEmpty)

        resolved.set(executable)
        await connection.changePath(executable.path)

        #expect(await connection.state == .ready)
        #expect(launcher.requests.count == 2)
        await connection.shutdown()
    }

    @Test func aRefusedLaunchIsFailedToStart() async {
        let launcher = FakeLauncher(responder: FakeOMP.responder())
        launcher.setRefusing(true)
        let connection = makeConnection(launcher: launcher, resolve: { _ in executable })
        await connection.start(executablePath: nil, model: nil)
        #expect(await connection.state == .unavailable(.failedToStart))
    }

    @Test func anUnexpectedExitRestartsBothProcesses() async throws {
        let launcher = FakeLauncher(responder: FakeOMP.responder())
        let connection = makeConnection(launcher: launcher, resolve: { _ in executable })
        var events = connection.events().makeAsyncIterator()

        await connection.start(executablePath: nil, model: nil)
        let ready = await events.next()
        #expect(ready == .ready)

        launcher.launched[0].simulateExit()
        let terminated = await events.next()
        #expect(terminated == .terminated)
        #expect(await events.next() == .starting)
        let restarted = await events.next()
        #expect(restarted == .ready)
        #expect(launcher.requests.count == 4)
        #expect(await connection.state == .ready)
        await connection.shutdown()
    }

    @Test func aSecondExitWithin30SecondsMakesTheConnectionUnavailable() async throws {
        let launcher = FakeLauncher(responder: FakeOMP.responder())
        let connection = makeConnection(launcher: launcher, resolve: { _ in executable })
        var events = connection.events().makeAsyncIterator()

        await connection.start(executablePath: nil, model: nil)
        let ready = await events.next()
        #expect(ready == .ready)

        launcher.launched[0].simulateExit()
        let firstStop = await events.next()
        #expect(firstStop == .terminated)
        #expect(await events.next() == .starting)
        let restarted = await events.next()
        #expect(restarted == .ready)

        launcher.launched[2].simulateExit()
        let secondStop = await events.next()
        #expect(secondStop == .terminated)
        let unavailable = await events.next()
        #expect(unavailable == .unavailable(.stoppedAgain))
        #expect(await connection.state == .unavailable(.stoppedAgain))
        #expect(launcher.requests.count == 4)
    }

    @Test func anArchiveExitWhileTheChatStartsIsNotMissed() async throws {
        let launcher = FakeLauncher(responder: FakeOMP.responder())
        let connection = makeConnection(
            launcher: ArchiveStopsWhileChatStarts(inner: launcher),
            resolve: { _ in executable }
        )
        var events = connection.events().makeAsyncIterator()

        await connection.start(executablePath: nil, model: nil)

        let event = await events.next()
        #expect(event == .unavailable(.failedToStart))
        #expect(await connection.state == .unavailable(.failedToStart))
        #expect(launcher.requests.count == 2)
    }

    @Test func aStopAfterTheWindowRestartsAgain() async throws {
        let clock = TestClock()
        let launcher = FakeLauncher(responder: FakeOMP.responder())
        let connection = makeConnection(launcher: launcher, resolve: { _ in executable }, clock: clock)
        var events = connection.events().makeAsyncIterator()

        await connection.start(executablePath: nil, model: nil)
        _ = await events.next()

        launcher.launched[0].simulateExit()
        _ = await events.next()
        _ = await events.next()
        #expect(await events.next() == .ready)

        clock.advance(by: 31)
        launcher.launched[2].simulateExit()
        let terminated = await events.next()
        #expect(terminated == .terminated)
        #expect(await events.next() == .starting)
        let restarted = await events.next()
        #expect(restarted == .ready)
        #expect(launcher.requests.count == 6)
        await connection.shutdown()
    }

    @Test func conversationFoldersOnlyAcceptPlainNames() async throws {
        let connection = makeConnection(launcher: FakeLauncher(responder: FakeOMP.responder()), resolve: { _ in executable })
        let directory = try await connection.sessionDirectory(forConversation: "conv-1")
        #expect(directory.lastPathComponent == "conv-1")
        await #expect(throws: OMPError.invalidSessionName) {
            try await connection.sessionDirectory(forConversation: "../escape")
        }
    }
}

/// Launches like `FakeLauncher`, but the archive process stops as soon as the chat process is launched.
private struct ArchiveStopsWhileChatStarts: OMPLaunching {
    let inner: FakeLauncher

    func launch(_ request: OMPLaunchRequest) throws -> any OMPRunningProcess {
        if inner.requests.count == 1 {
            inner.launched[0].simulateExit()
        }
        return try inner.launch(request)
    }
}
