import Foundation
import Testing
@testable import AxiScreen

private let outlook = ApplicationSnapshot(bundleIdentifier: "com.microsoft.Outlook", name: "Outlook", processIdentifier: 10)
private let safari = ApplicationSnapshot(bundleIdentifier: "com.apple.Safari", name: "Safari", processIdentifier: 11)
private let preview = ApplicationSnapshot(bundleIdentifier: "com.apple.Preview", name: "Anteprima", processIdentifier: 12)

@Test func findsEmailInNewOutlookWithHeadersAndAttachments() throws {
    let window = AccessibilityNode(role: "AXWindow", title: "Re: Preventivo", children: [
        AccessibilityNode(role: AccessibilityRole.staticText, value: "From: Mario Rossi"),
        AccessibilityNode(role: AccessibilityRole.staticText, value: "To: Anna Bianchi, luca@example.com"),
        AccessibilityNode(role: AccessibilityRole.staticText, value: "Subject: Preventivo"),
        AccessibilityNode(role: AccessibilityRole.staticText, value: "Sent: 12/03/2025 09:14"),
        AccessibilityNode(role: AccessibilityRole.staticText, value: "Attachments: offerta.pdf; listino.xlsx"),
        AccessibilityNode(role: AccessibilityRole.webArea, children: [
            AccessibilityNode(role: AccessibilityRole.staticText, value: "Buongiorno, in allegato l'offerta."),
            AccessibilityNode(role: AccessibilityRole.staticText, value: "Saluti, Mario."),
        ]),
    ])
    let candidate = try? DocumentFinder().find(in: AccessibilitySnapshot(application: outlook, window: window)).get().first

    guard case .email(let message) = candidate else {
        Issue.record("attesa una email, trovato \(String(describing: candidate))")
        return
    }
    #expect(message.sender == "Mario Rossi")
    #expect(message.recipients == ["Anna Bianchi", "luca@example.com"])
    #expect(message.subject == "Preventivo")
    #expect(message.sentAt == "12/03/2025 09:14")
    #expect(message.attachmentNames == ["offerta.pdf", "listino.xlsx"])
    #expect(message.body == "Buongiorno, in allegato l'offerta.\nSaluti, Mario.")
}

@Test func readsEmailHeadersInItalianLabelsWithSeparateValues() throws {
    let window = AccessibilityNode(role: "AXWindow", children: [
        AccessibilityNode(role: AccessibilityRole.staticText, value: "Da"),
        AccessibilityNode(role: AccessibilityRole.staticText, value: "Mario Rossi"),
        AccessibilityNode(role: AccessibilityRole.staticText, value: "Oggetto"),
        AccessibilityNode(role: AccessibilityRole.staticText, value: "Riunione"),
    ])
    let message = OutlookMessageReader.read(window, source: outlook)
    #expect(message?.sender == "Mario Rossi")
    #expect(message?.subject == "Riunione")
}

@Test func findsBrowserPageFromAccessibilityURLAndVisibleText() throws {
    let window = AccessibilityNode(role: "AXWindow", title: "Articolo", children: [
        AccessibilityNode(role: AccessibilityRole.textField, label: "Address and search bar", value: "example.com/articolo"),
        AccessibilityNode(role: AccessibilityRole.webArea, url: URL(string: "https://example.com/articolo"), children: [
            AccessibilityNode(role: AccessibilityRole.heading, value: "Titolo"),
            AccessibilityNode(role: AccessibilityRole.staticText, value: "Primo paragrafo"),
        ]),
    ])
    let candidate = try? DocumentFinder().find(in: AccessibilitySnapshot(application: safari, window: window)).get().first

    guard case .webPage(let page) = candidate else {
        Issue.record("attesa una pagina web, trovato \(String(describing: candidate))")
        return
    }
    #expect(page.address == URL(string: "https://example.com/articolo"))
    #expect(page.visibleText == "Titolo\nPrimo paragrafo")
}

@Test func browserPageTextLeavesOutBrowserInterface() throws {
    let window = AccessibilityNode(role: "AXWindow", title: "Articolo", children: [
        AccessibilityNode(role: AccessibilityRole.staticText, value: "Scheda: Articolo"),
        AccessibilityNode(role: AccessibilityRole.link, value: "Segnalibri"),
        AccessibilityNode(role: AccessibilityRole.webArea, url: URL(string: "https://example.com/articolo"), children: [
            AccessibilityNode(role: AccessibilityRole.staticText, value: "Primo paragrafo"),
        ]),
    ])
    #expect(VisibleTextReader.pageText(in: window) == "Primo paragrafo")
}

@Test func browserPageWithoutWebAreaHasNoText() throws {
    let window = AccessibilityNode(role: "AXWindow", children: [
        AccessibilityNode(role: AccessibilityRole.staticText, value: "Scheda: Articolo"),
    ])
    #expect(VisibleTextReader.pageText(in: window) == nil)
}

@Test func browserAddressFallsBackToAddressFieldWithoutScheme() throws {
    let window = AccessibilityNode(role: "AXWindow", children: [
        AccessibilityNode(role: AccessibilityRole.textField, label: "Address and search bar", value: "example.org/pagina"),
    ])
    let candidate = try? DocumentFinder().find(in: AccessibilitySnapshot(application: safari, window: window)).get().first
    guard case .webPage(let page) = candidate else {
        Issue.record("attesa una pagina web")
        return
    }
    #expect(page.address == URL(string: "https://example.org/pagina"))
}

@Test func browserWithoutAddressFindsNothing() throws {
    let window = AccessibilityNode(role: "AXWindow", children: [
        AccessibilityNode(role: AccessibilityRole.staticText, value: "Nessun indirizzo"),
    ])
    #expect(DocumentFinder().find(in: AccessibilitySnapshot(application: safari, window: window)) == .failure(.addressUnreadable))
}

@Test func findsBrowserPageInFirefoxFromAccessibilityURL() throws {
    let firefox = ApplicationSnapshot(bundleIdentifier: "org.mozilla.firefox", name: "Firefox", processIdentifier: 13)
    let window = AccessibilityNode(role: "AXWindow", title: "Articolo", children: [
        AccessibilityNode(role: AccessibilityRole.webArea, url: URL(string: "https://example.com/firefox"), children: [
            AccessibilityNode(role: AccessibilityRole.staticText, value: "Testo da Firefox"),
        ]),
    ])
    let candidate = try? DocumentFinder().find(in: AccessibilitySnapshot(application: firefox, window: window)).get().first
    guard case .webPage(let page) = candidate else {
        Issue.record("attesa una pagina web, trovato \(String(describing: candidate))")
        return
    }
    #expect(page.address == URL(string: "https://example.com/firefox"))
    #expect(page.visibleText == "Testo da Firefox")
}

@Test func findsFileOpenedInPreview() throws {
    let file = URL(fileURLWithPath: "/Users/luca/Documents/contratto.pdf")
    let window = AccessibilityNode(role: "AXWindow", url: file)
    let candidate = try? DocumentFinder().find(in: AccessibilitySnapshot(application: preview, window: window)).get().first
    #expect(candidate == .file(FileDocument(url: file, source: preview)))
}

@Test func windowWithoutDocumentFindsNothing() throws {
    let window = AccessibilityNode(role: "AXWindow", title: "Scrivania")
    #expect(DocumentFinder().find(in: AccessibilitySnapshot(application: preview, window: window)) == .failure(.nothingInFront))
}

private let finder = ApplicationSnapshot(bundleIdentifier: "com.apple.finder", name: "Finder", processIdentifier: 13)

/// A new folder in the temporary directory, removed by the caller.
private func temporaryFolder() throws -> URL {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("axi-t26-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    return folder
}

@Test func finderSelectionGivesEachFileInSelectionOrderWithoutFolders() throws {
    let folder = try temporaryFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let subfolder = folder.appendingPathComponent("Cartella", isDirectory: true)
    try FileManager.default.createDirectory(at: subfolder, withIntermediateDirectories: true)
    let first = folder.appendingPathComponent("b.pdf")
    let second = folder.appendingPathComponent("a.txt")
    FileManager.default.createFile(atPath: first.path, contents: Data())
    FileManager.default.createFile(atPath: second.path, contents: Data())

    let window = AccessibilityNode(role: "AXWindow", title: "Documenti", selectedURLs: [first, subfolder, second])
    let result = DocumentFinder().find(in: AccessibilitySnapshot(application: finder, window: window))

    #expect(result == .success([
        .file(FileDocument(url: first, source: finder)),
        .file(FileDocument(url: second, source: finder)),
    ]))
}

@Test func finderSelectionOfFoldersOnlyFindsNothing() throws {
    let folder = try temporaryFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let subfolder = folder.appendingPathComponent("Cartella", isDirectory: true)
    try FileManager.default.createDirectory(at: subfolder, withIntermediateDirectories: true)

    let window = AccessibilityNode(role: "AXWindow", title: "Documenti", selectedURLs: [subfolder])
    #expect(DocumentFinder().find(in: AccessibilitySnapshot(application: finder, window: window)) == .failure(.nothingInFront))
}

@Test func addressBarGivesTheTypedAddressWithoutAutomation() throws {
    let field = AccessibilityNode(role: "AXTextField", label: "Indirizzo", value: "https://example.com/pagina")
    let window = AccessibilityNode(role: "AXWindow", title: "Pagina", children: [field])
    #expect(BrowserAddress.addressBarURL(in: window) == URL(string: "https://example.com/pagina"))
}

@Test func emptyAddressBarGivesNoAddress() throws {
    let field = AccessibilityNode(role: "AXTextField", label: "Address", value: "")
    let window = AccessibilityNode(role: "AXWindow", title: "Pagina", children: [field])
    #expect(BrowserAddress.addressBarURL(in: window) == nil)
}

@Test func fileShownByBrowserInPageAreaIsAFileOfTheBrowser() throws {
    let file = try #require(URL(string: "file:///Users/luca/Downloads/manuale.pdf"))
    let window = AccessibilityNode(role: "AXWindow", title: "manuale.pdf", children: [
        AccessibilityNode(role: AccessibilityRole.webArea, url: file, children: [
            AccessibilityNode(role: AccessibilityRole.staticText, value: "Testo del PDF"),
        ]),
    ])
    let candidate = try? DocumentFinder().find(in: AccessibilitySnapshot(application: safari, window: window)).get().first
    #expect(candidate == .file(FileDocument(url: file, source: safari)))
}

@Test func fileInBrowserAddressBarIsAFileOfTheBrowser() throws {
    let file = try #require(URL(string: "file:///Users/luca/Downloads/manuale.pdf"))
    let field = AccessibilityNode(role: "AXTextField", label: "Address and search bar", value: "file:///Users/luca/Downloads/manuale.pdf")
    let window = AccessibilityNode(role: "AXWindow", title: "manuale.pdf", children: [field])
    let candidate = try? DocumentFinder().find(in: AccessibilitySnapshot(application: safari, window: window)).get().first
    #expect(candidate == .file(FileDocument(url: file, source: safari)))
}

@Test func fileGivenByAutomationAsWindowAddressIsAFileOfTheBrowser() throws {
    let file = try #require(URL(string: "file:///Users/luca/Downloads/manuale.pdf"))
    let window = AccessibilityNode(role: "AXWindow", title: "manuale.pdf", url: file)
    let candidate = try? DocumentFinder().find(in: AccessibilitySnapshot(application: safari, window: window)).get().first
    #expect(candidate == .file(FileDocument(url: file, source: safari)))
}

@Test func pageAreaAddressComesBeforeWindowAddress() throws {
    let page = try #require(URL(string: "https://example.com/pagina"))
    let other = try #require(URL(string: "https://example.com/altra"))
    let window = AccessibilityNode(role: "AXWindow", title: "Pagina", url: other, children: [
        AccessibilityNode(role: AccessibilityRole.webArea, url: page, children: [
            AccessibilityNode(role: AccessibilityRole.staticText, value: "Testo della pagina"),
        ]),
    ])
    #expect(BrowserAddress.pageURL(in: window) == page)
}

@Test func pdfShownByBrowserAtWebAddressIsWebPageWithoutVisibleText() throws {
    let window = AccessibilityNode(role: "AXWindow", title: "doc.pdf", children: [
        AccessibilityNode(role: AccessibilityRole.webArea, url: URL(string: "https://example.com/doc.pdf")),
    ])
    let candidate = try? DocumentFinder().find(in: AccessibilitySnapshot(application: safari, window: window)).get().first
    guard case .webPage(let page) = candidate else {
        Issue.record("attesa una pagina web, trovato \(String(describing: candidate))")
        return
    }
    #expect(page.address == URL(string: "https://example.com/doc.pdf"))
    #expect((page.visibleText ?? "").isEmpty)
}

@Test func browserAddressOfOtherSchemeIsUnreadable() throws {
    let field = AccessibilityNode(role: "AXTextField", label: "Address and search bar", value: "chrome://settings")
    let window = AccessibilityNode(role: "AXWindow", title: "Impostazioni", children: [field])
    #expect(DocumentFinder().find(in: AccessibilitySnapshot(application: safari, window: window)) == .failure(.addressUnreadable))
}

@Test func folderAsAppDocumentFindsNothing() throws {
    let folder = try temporaryFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let window = AccessibilityNode(role: "AXWindow", title: "Terminal", url: folder)
    #expect(DocumentFinder().find(in: AccessibilitySnapshot(application: preview, window: window)) == .failure(.nothingInFront))
}

@Test func realFileAsAppDocumentIsFound() throws {
    let folder = try temporaryFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let file = folder.appendingPathComponent("contratto.pdf")
    FileManager.default.createFile(atPath: file.path, contents: Data())
    let window = AccessibilityNode(role: "AXWindow", title: "contratto.pdf", url: file)
    let candidate = try? DocumentFinder().find(in: AccessibilitySnapshot(application: preview, window: window)).get().first
    #expect(candidate == .file(FileDocument(url: file, source: preview)))
}

@Test func folderShownByBrowserAsFileAddressFindsNothing() throws {
    let folder = try temporaryFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let field = AccessibilityNode(role: "AXTextField", label: "Address and search bar", value: folder.absoluteString)
    let window = AccessibilityNode(role: "AXWindow", title: "Cartella", children: [field])
    #expect(DocumentFinder().find(in: AccessibilitySnapshot(application: safari, window: window)) == .failure(.nothingInFront))
}

@Test func realFileShownByBrowserAsFileAddressIsFound() throws {
    let folder = try temporaryFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let file = folder.appendingPathComponent("manuale.pdf")
    FileManager.default.createFile(atPath: file.path, contents: Data())
    let field = AccessibilityNode(role: "AXTextField", label: "Address and search bar", value: file.absoluteString)
    let window = AccessibilityNode(role: "AXWindow", title: "manuale.pdf", children: [field])
    let candidate = try? DocumentFinder().find(in: AccessibilitySnapshot(application: safari, window: window)).get().first
    #expect(candidate == .file(FileDocument(url: file, source: safari)))
}

@Test func pageAreaTitleIsTheOriginNameOfTheWebPage() throws {
    let window = AccessibilityNode(role: "AXWindow", title: "Finestra", children: [
        AccessibilityNode(role: AccessibilityRole.webArea, title: "Fattura marzo", url: URL(string: "https://example.com/fattura"), children: []),
    ])
    let candidate = try DocumentFinder().find(in: AccessibilitySnapshot(application: safari, window: window)).get().first
    #expect(candidate?.originName == "Fattura marzo")
}

@Test func windowTitleIsTheOriginNameWhenPageAreaHasNoTitle() throws {
    let window = AccessibilityNode(role: "AXWindow", title: "Articolo", children: [
        AccessibilityNode(role: AccessibilityRole.webArea, url: URL(string: "https://example.com/articolo"), children: []),
    ])
    let candidate = try DocumentFinder().find(in: AccessibilitySnapshot(application: safari, window: window)).get().first
    #expect(candidate?.originName == "Articolo")
}

@Test func pageWithoutAnyTitleHasNoOriginName() throws {
    let window = AccessibilityNode(role: "AXWindow", title: "  ", children: [
        AccessibilityNode(role: AccessibilityRole.webArea, url: URL(string: "https://example.com/senza-titolo"), children: []),
    ])
    let candidate = try DocumentFinder().find(in: AccessibilitySnapshot(application: safari, window: window)).get().first
    #expect(candidate?.originName == nil)
}

@Test func fileOriginNameIsItsFileNameWithExtension() {
    let file = DocumentCandidate.file(FileDocument(url: URL(fileURLWithPath: "/tmp/Bolletta.pdf"), source: preview))
    #expect(file.originName == "Bolletta.pdf")
}

@Test func emailOriginNameIsItsSubjectWhenPresent() {
    func email(subject: String?) -> DocumentCandidate {
        .email(EmailMessage(sender: nil, recipients: [], subject: subject, sentAt: nil, body: "", attachmentNames: [], source: outlook))
    }
    #expect(email(subject: "Preventivo").originName == "Preventivo")
    #expect(email(subject: nil).originName == nil)
}
