import Foundation

/// Where the vault lives on this Mac: inside `~/Library/Application Support/Axi/`.
public enum VaultLocation {
    /// Opens the vault of this Mac, creating its database and folders on first use.
    public static func open(embeddingDimension: Int) throws -> VaultStore {
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folder = support.appending(path: "Axi", directoryHint: .isDirectory)
        return try VaultStore(
            databaseURL: folder.appending(path: "vault.sqlite"),
            filesDirectory: folder.appending(path: "documents", directoryHint: .isDirectory),
            embeddingDimension: embeddingDimension
        )
    }
}
