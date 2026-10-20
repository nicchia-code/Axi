import Foundation
import Testing
@testable import AxiOMP

struct OMPFramesTests {
    @Test func roundTripsASmallFrame() throws {
        let frame: JSONValue = .object(["type": .string("prompt"), "id": .string("req_1"), "message": .string("Ciao")])
        let bytes = try OMPFrameWriter.encode(frame, limits: .default)
        #expect(bytes.last == 0x0A)
        var reader = OMPFrameReader()
        let frames = try reader.append(bytes)
        #expect(frames == [frame])
    }

    @Test func splitsFramesAcrossReads() throws {
        let first: JSONValue = .object(["type": .string("ready")])
        let second: JSONValue = .object(["type": .string("response"), "id": .string("req_2")])
        let bytes = try OMPFrameWriter.encode(first, limits: .default) + OMPFrameWriter.encode(second, limits: .default)
        var reader = OMPFrameReader()
        var frames: [JSONValue] = []
        for start in stride(from: 0, to: bytes.count, by: 7) {
            frames += try reader.append(bytes[start..<min(start + 7, bytes.count)])
        }
        #expect(frames == [first, second])
    }

    @Test func reassemblesChunkedFrames() throws {
        let text = String(repeating: "a", count: 1_200_000)
        let frame: JSONValue = .object(["type": .string("prompt"), "message": .string(text)])
        let bytes = try OMPFrameWriter.encode(frame, limits: .default)
        var reader = OMPFrameReader()
        var frames: [JSONValue] = []
        for start in stride(from: 0, to: bytes.count, by: 65_536) {
            frames += try reader.append(bytes[start..<min(start + 65_536, bytes.count)])
        }
        #expect(frames == [frame])
    }

    @Test func rejectsChunkWithInconsistentLength() throws {
        let chunk: JSONValue = .object([
            "type": .string("rpc_chunk"),
            "chunkId": .string("c1"),
            "index": .number(0),
            "count": .number(2),
            "byteLength": .number(10),
            "data": .string(Data("abc".utf8).base64EncodedString()),
        ])
        let bytes = try OMPFrameWriter.encode(chunk, limits: .default)
        var reader = OMPFrameReader()
        #expect(throws: OMPError.invalidFrame) {
            try reader.append(bytes)
        }
    }

    @Test func rejectsLinesBeyondTheLimit() {
        var reader = OMPFrameReader()
        reader.configure(limits: OMPFrameLimits(maxFrameBytes: 16, maxReassembledBytes: 1024))
        let line = Data(repeating: 0x61, count: 64)
        #expect(throws: OMPError.frameTooLarge) {
            try reader.append(line)
        }
    }
}
