import Foundation

/// Size limits OMP announces in its `ready` frame.
struct OMPFrameLimits: Sendable, Equatable {
    static let `default` = OMPFrameLimits(maxFrameBytes: 1 << 20, maxReassembledBytes: 64 << 20)

    var maxFrameBytes: Int
    var maxReassembledBytes: Int
}

/// Splits the stdout bytes of OMP into JSON frames and reassembles `rpc_chunk` frames.
struct OMPFrameReader {
    private struct ChunkedFrame {
        let count: Int
        let byteLength: Int
        var parts: [Int: Data] = [:]
        var received = 0
    }

    private var buffer = Data()
    private var chunked: [String: ChunkedFrame] = [:]
    private(set) var limits: OMPFrameLimits

    init(limits: OMPFrameLimits = .default) {
        self.limits = limits
    }

    mutating func configure(limits: OMPFrameLimits) {
        self.limits = limits
    }

    /// Appends bytes and returns every complete frame they close, in order.
    mutating func append(_ data: Data) throws -> [JSONValue] {
        buffer.append(data)
        var frames: [JSONValue] = []
        let maxLine = limits.maxFrameBytes * 2
        while let newline = buffer.firstIndex(of: 0x0A) {
            let line = Data(buffer[buffer.startIndex..<newline])
            buffer.removeSubrange(buffer.startIndex...newline)
            guard !line.isEmpty else { continue }
            guard line.count <= maxLine else { throw OMPError.frameTooLarge }
            let frame = try JSONDecoder().decode(JSONValue.self, from: line)
            if let complete = try accept(frame) {
                frames.append(complete)
            }
        }
        guard buffer.count <= maxLine else { throw OMPError.frameTooLarge }
        return frames
    }

    /// Returns the frame itself, or the whole reassembled frame once its last chunk arrives.
    private mutating func accept(_ frame: JSONValue) throws -> JSONValue? {
        guard frame["type"]?.string == "rpc_chunk" else { return frame }
        guard let chunkID = frame["chunkId"]?.string,
              let index = frame["index"]?.int,
              let count = frame["count"]?.int,
              let byteLength = frame["byteLength"]?.int,
              let encoded = frame["data"]?.string,
              let payload = Data(base64Encoded: encoded),
              count >= 2, index >= 0, index < count,
              byteLength > limits.maxFrameBytes, byteLength <= limits.maxReassembledBytes
        else {
            throw OMPError.invalidFrame
        }
        var entry = chunked[chunkID] ?? ChunkedFrame(count: count, byteLength: byteLength)
        guard entry.count == count, entry.byteLength == byteLength, entry.parts[index] == nil else {
            throw OMPError.invalidFrame
        }
        let received = entry.parts.values.reduce(0) { $0 + $1.count } + payload.count
        guard received <= byteLength else { throw OMPError.invalidFrame }
        entry.parts[index] = payload
        entry.received = received
        guard entry.parts.count == count else {
            chunked[chunkID] = entry
            return nil
        }
        chunked[chunkID] = nil
        var whole = Data()
        whole.reserveCapacity(byteLength)
        for part in 0..<count {
            guard let bytes = entry.parts[part] else { throw OMPError.invalidFrame }
            whole.append(bytes)
        }
        guard whole.count == byteLength else { throw OMPError.invalidFrame }
        return try JSONDecoder().decode(JSONValue.self, from: whole)
    }
}

/// Encodes frames as JSON lines, chunking the ones larger than the frame limit.
enum OMPFrameWriter {
    static let chunkPayloadBytes = 256 * 1024

    /// All the bytes of one frame, ready to be written in a single call so that
    /// chunks of different frames never interleave.
    static func encode(_ frame: JSONValue, limits: OMPFrameLimits) throws -> Data {
        let json = try JSONEncoder().encode(frame)
        var output = Data()
        if json.count <= limits.maxFrameBytes {
            output.append(json)
            output.append(0x0A)
            return output
        }
        guard json.count <= limits.maxReassembledBytes else { throw OMPError.frameTooLarge }
        let chunkID = UUID().uuidString
        let count = (json.count + chunkPayloadBytes - 1) / chunkPayloadBytes
        for index in 0..<count {
            let start = index * chunkPayloadBytes
            let end = min(start + chunkPayloadBytes, json.count)
            let chunk: JSONValue = .object([
                "type": .string("rpc_chunk"),
                "chunkId": .string(chunkID),
                "index": .number(Double(index)),
                "count": .number(Double(count)),
                "byteLength": .number(Double(json.count)),
                "data": .string(json[start..<end].base64EncodedString()),
            ])
            output.append(try JSONEncoder().encode(chunk))
            output.append(0x0A)
        }
        return output
    }
}
