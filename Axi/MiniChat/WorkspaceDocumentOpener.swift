import AppKit

/// Opens the vault copy of a cited document in the default app.
struct WorkspaceDocumentOpener: DocumentOpening {
    /// Location of the vault copy of a document, or nil if it is gone.
    let fileURL: @Sendable (String) async -> URL?
    /// Web address kept with a document, or nil if it has none.
    let addressURL: @Sendable (String) async -> URL?

    func open(_ citation: DocumentCitation) async {
        if let url = await fileURL(citation.documentID) {
            let target = Self.target(for: url, page: citation.page)
            _ = await MainActor.run { NSWorkspace.shared.open(target) }
            return
        }
        // A web page kept without its PDF has no copy: open the address saved with it.
        guard let address = await addressURL(citation.documentID) else { return }
        _ = await MainActor.run { NSWorkspace.shared.open(address) }
    }

    /// PDFs get a `#page=` fragment; the default app may or may not honour it.
    static func target(for url: URL, page: Int?) -> URL {
        guard let page,
              url.pathExtension.lowercased() == "pdf",
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        components.fragment = "page=\(page)"
        return components.url ?? url
    }
}
