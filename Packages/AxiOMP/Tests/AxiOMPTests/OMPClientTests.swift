import Foundation
import Testing
@testable import AxiOMP

struct OMPClientTests {
    private func makeClient(
        supportedVersions: [Int] = [1, 2],
        responder: @escaping FakeOMPProcess.Responder
    ) -> (OMPClient, FakeOMPProcess) {
        let process = FakeOMPProcess(supportedVersions: supportedVersions, responder: responder)
        let dispatcher = OMPHostToolDispatcher(chat: StubChatTools(), vault: StubVaultTools(), events: OMPEventHub())
        let client = OMPClient(role: .chat, process: process, dispatcher: dispatcher)
        return (client, process)
    }

    @Test func startNegotiatesAndRegistersTheHostTools() async throws {
        let (client, process) = makeClient(responder: FakeOMP.responder())
        try await client.start()
        let commands = process.writtenFrames.compactMap { $0["type"]?.string }
        #expect(commands == ["negotiate_protocol", "set_host_tools"])
        let tools = process.writtenFrames.last?["tools"]?.array ?? []
        #expect(tools.count == 5)
    }

    @Test func startRejectsAnUnsupportedProtocol() async {
        let (client, _) = makeClient(supportedVersions: [1], responder: FakeOMP.responder())
        await #expect(throws: OMPError.unsupportedProtocol) {
            try await client.start()
        }
    }

    @Test func promptStreamsTextAndReturnsTheFinalText() async throws {
        let (client, _) = makeClient(responder: FakeOMP.responder(extra: { frame in
            frame["type"]?.string == "prompt"
                ? FakeFrames.completedTurn(for: frame, deltas: ["Ci", "ao"], finalText: "Ciao")
                : []
        }))
        try await client.start()
        let deltas = Box<[String]>([])
        let answer = try await client.prompt("Dimmi ciao") { delta in
            deltas.set(deltas.current + [delta])
        }
        #expect(answer == "Ciao")
        #expect(deltas.current == ["Ci", "ao"])
    }

    @Test func promptReportsEachAssistantMessageStart() async throws {
        let (client, _) = makeClient(responder: FakeOMP.responder(extra: { frame in
            frame["type"]?.string == "prompt"
                ? [FakeFrames.response(to: frame),
                   FakeFrames.messageDelta("Cerco."),
                   FakeFrames.messageStart(role: "user"),
                   FakeFrames.messageStart(),
                   FakeFrames.messageDelta("Risposta"),
                   FakeFrames.promptResult(status: "completed")]
                : []
        }))
        try await client.start()
        let events = Box<[String]>([])
        let answer = try await client.prompt("Dimmi", onTextDelta: { delta in
            events.set(events.current + [delta])
        }, onMessageStart: {
            events.set(events.current + ["|"])
        })
        #expect(events.current == ["Cerco.", "|", "Risposta"])
        #expect(answer == "Risposta")
    }

    @Test func opensTheConversationSessionOnce() async throws {
        let (client, process) = makeClient(responder: FakeOMP.responder(extra: { frame in
            frame["type"]?.string == "prompt"
                ? FakeFrames.completedTurn(for: frame, deltas: [], finalText: "ok")
                : []
        }))
        try await client.start()
        let directory = URL(fileURLWithPath: "/tmp/axi-conversation-1")
        _ = try await client.prompt("uno", sessionDirectory: directory)
        _ = try await client.prompt("due", sessionDirectory: directory)
        let opened = process.writtenFrames.filter { $0["type"]?.string == "open_session" }
        #expect(opened.count == 1)
        #expect(opened.first?["sessionDir"]?.string == directory.path)
    }

    @Test func cancellingAPromptAbortsTheTurn() async throws {
        let (client, _) = makeClient(responder: FakeOMP.responder(extra: { frame in
            switch frame["type"]?.string {
            case "prompt":
                return [FakeFrames.response(to: frame), FakeFrames.messageDelta("Sto")]
            case "abort":
                return [FakeFrames.response(to: frame), FakeFrames.promptResult(status: "aborted")]
            default:
                return []
            }
        }))
        try await client.start()
        let (deltas, deltaContinuation) = AsyncStream<String>.makeStream()
        let turn = Task {
            try await client.prompt("Scrivi un racconto") { delta in
                deltaContinuation.yield(delta)
            }
        }
        var iterator = deltas.makeAsyncIterator()
        _ = await iterator.next()
        turn.cancel()
        await #expect(throws: OMPError.aborted) {
            try await turn.value
        }
    }

    @Test func answersHostToolCallsWithTheDispatcherResult() async throws {
        let (client, process) = makeClient(responder: FakeOMP.responder(extra: { frame in
            switch frame["type"]?.string {
            case "prompt":
                return [
                    FakeFrames.response(to: frame),
                    FakeFrames.hostToolCall(
                        id: "tool-1",
                        name: "search_vault",
                        arguments: .object(["query": .string("fattura"), "limit": .number(2)])
                    ),
                ]
            case "host_tool_result":
                return [FakeFrames.agentEnd(text: "Ho trovato la fattura."), FakeFrames.promptResult(status: "completed")]
            default:
                return []
            }
        }))
        try await client.start()
        let answer = try await client.prompt("Cerca la fattura")
        #expect(answer == "Ho trovato la fattura.")
        let result = process.writtenFrames.first { $0["type"]?.string == "host_tool_result" }
        #expect(result?["id"]?.string == "tool-1")
        let text = result?["result"]?["content"]?.array?.first?["text"]?.string ?? ""
        #expect(text.contains("doc-1"))
        #expect(result?["isError"] == nil)
    }

    @Test func reportsLocalCommandsAndFailedPrompts() async throws {
        let (client, _) = makeClient(responder: FakeOMP.responder(extra: { frame in
            guard frame["type"]?.string == "prompt" else { return [] }
            if frame["message"]?.string == "/help" {
                return [FakeFrames.response(to: frame), FakeFrames.promptResult(status: "completed", agentInvoked: false)]
            }
            return [FakeFrames.response(to: frame), FakeFrames.promptResult(status: "error", error: "boom")]
        }))
        try await client.start()
        await #expect(throws: OMPError.localCommand) {
            try await client.prompt("/help")
        }
        await #expect(throws: OMPError.promptFailed(message: "boom")) {
            try await client.prompt("Ciao")
        }
    }

    @Test func setModelSendsProviderAndModelID() async throws {
        let (client, process) = makeClient(responder: FakeOMP.responder())
        try await client.start()
        try await client.setModel("anthropic/claude-x")
        let frame = process.writtenFrames.first { $0["type"]?.string == "set_model" }
        #expect(frame?["provider"]?.string == "anthropic")
        #expect(frame?["modelId"]?.string == "claude-x")
    }

    @Test func listsTheAvailableModels() async throws {
        let (client, _) = makeClient(responder: FakeOMP.responder())
        try await client.start()
        let models = try await client.availableModels()
        #expect(models == [OMPModel(provider: "anthropic", modelID: "claude-x", name: "Claude X")])
    }

    @Test func readsTheContextWindowOfTheActiveModel() async throws {
        let responder = FakeOMP.responder(extra: { frame in
            frame["type"]?.string == "get_state"
                ? [FakeFrames.response(to: frame, data: .object(["model": .object([
                    "id": .string("claude-x"),
                    "contextWindow": .number(200_000),
                ])]))]
                : []
        })
        let (client, _) = makeClient(responder: responder)
        try await client.start()
        #expect(try await client.contextWindowTokens() == 200_000)
    }

    @Test func readsTheKeyOfTheActiveModel() async throws {
        let responder = FakeOMP.responder(extra: { frame in
            frame["type"]?.string == "get_state"
                ? [FakeFrames.response(to: frame, data: .object(["model": .object([
                    "provider": .string("anthropic"),
                    "id": .string("claude-x"),
                ])]))]
                : []
        })
        let (client, _) = makeClient(responder: responder)
        try await client.start()
        #expect(try await client.currentModelKey() == "anthropic/claude-x")
    }
}
