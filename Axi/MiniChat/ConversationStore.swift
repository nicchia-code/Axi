import Foundation

/// Saved conversations, one JSON file each, in Application Support.
actor ConversationStore {
    private let directory: URL

    init(directory: URL) {
        self.directory = directory
    }

    /// `~/Library/Application Support/Axi/conversations`.
    static func defaultDirectory() throws -> URL {
        try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Axi", isDirectory: true)
            .appendingPathComponent("conversations", isDirectory: true)
    }

    func save(_ conversation: Conversation) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(conversation)
        try data.write(to: fileURL(for: conversation.id), options: .atomic)
    }

    func load(_ id: UUID) throws -> Conversation? {
        let url = fileURL(for: id)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try JSONDecoder().decode(Conversation.self, from: Data(contentsOf: url))
    }

    /// The most recently active conversation, nil when none is saved. Throws when conversations are saved but none can be read.
    func latest() throws -> Conversation? {
        let (readable, unreadableCount) = try readConversations()
        if readable.isEmpty && unreadableCount > 0 { throw ConversationStoreError.noReadableConversation }
        return readable.max { $0.lastMessageAt < $1.lastMessageAt }
    }

    /// All conversations, most recent first.
    func summaries() throws -> [ConversationSummary] {
        try allConversations()
            .map(\.summary)
            .sorted { $0.lastMessageAt > $1.lastMessageAt }
    }

    func delete(_ id: UUID) throws {
        let url = fileURL(for: id)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    private func fileURL(for id: UUID) -> URL {
        directory.appendingPathComponent(id.uuidString).appendingPathExtension("json")
    }

    private func allConversations() throws -> [Conversation] {
        try readConversations().readable
    }

    /// The conversations that decode, and how many saved files do not.
    private func readConversations() throws -> (readable: [Conversation], unreadableCount: Int) {
        guard FileManager.default.fileExists(atPath: directory.path) else { return ([], 0) }
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
        let decoder = JSONDecoder()
        var readable: [Conversation] = []
        var unreadableCount = 0
        for url in files {
            if let conversation = try? decoder.decode(Conversation.self, from: Data(contentsOf: url)) {
                readable.append(conversation)
            } else {
                unreadableCount += 1
            }
        }
        return (readable, unreadableCount)
    }
}

enum ConversationStoreError: Error {
    /// Conversations are saved, but none of them can be read.
    case noReadableConversation
}
