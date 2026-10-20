import Foundation

/// Where the dot was left: its window origin, the display it was on, and whether it was hidden in the menu bar.
public struct PosizionePuntino: Codable, Sendable, Equatable {
    /// Origin of the dot's window in screen coordinates.
    public var x: Double
    public var y: Double
    /// `CGDirectDisplayID` of the display the dot was on, when known.
    public var schermo: UInt32?
    /// Whether the dot was hidden in the menu bar when it was left.
    public var nascosto: Bool

    public init(x: Double, y: Double, schermo: UInt32?, nascosto: Bool = false) {
        self.x = x
        self.y = y
        self.schermo = schermo
        self.nascosto = nascosto
    }

    /// Files written before the hidden flag existed have none: the dot was visible.
    public init(from decoder: Decoder) throws {
        let contenitore = try decoder.container(keyedBy: CodingKeys.self)
        x = try contenitore.decode(Double.self, forKey: .x)
        y = try contenitore.decode(Double.self, forKey: .y)
        schermo = try contenitore.decodeIfPresent(UInt32.self, forKey: .schermo)
        nascosto = try contenitore.decodeIfPresent(Bool.self, forKey: .nascosto) ?? false
    }
}

/// Keeps the position of the dot in the Axi data folder.
public struct PuntinoStore: Sendable {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// `~/Library/Application Support/Axi/puntino.json`
    public static var defaultFileURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "Axi", directoryHint: .isDirectory)
            .appending(path: "puntino.json")
    }

    /// The saved position, or `nil` when none was saved or the file cannot be read.
    public func load() -> PosizionePuntino? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(PosizionePuntino.self, from: data)
    }

    public func save(_ posizione: PosizionePuntino) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(posizione)
        try data.write(to: fileURL, options: .atomic)
    }
}
