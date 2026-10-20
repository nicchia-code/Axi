import AxiScreen
import Foundation
import Testing
@testable import AxiCore

@Suite("Scelta del riconoscimento del testo")
struct RiconoscimentoTestoTests {
    /// A store on its own `UserDefaults` suite and Keychain item, cleaned up at the end.
    private func withStore(_ body: (ImpostazioniStore) throws -> Void) rethrows {
        let suite = "axi-test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let store = ImpostazioniStore(
            defaults: defaults,
            chiaveAzure: CredenzialeKeychain(
                service: "Axi-test-\(UUID().uuidString)", account: "azure"))
        defer {
            defaults.removePersistentDomain(forName: suite)
            try? store.chiaveAzure.cancella()
        }
        try body(store)
    }

    @Test("Vision is used when Azure is not configured")
    func visionWithoutAzure() {
        withStore { store in
            #expect(RiconoscimentoTesto.riconoscitore(impostazioni: store).source == .vision)
        }
    }

    @Test("Azure is used when endpoint and key are configured")
    func azureWhenConfigured() throws {
        try withStore { store in
            store.endpointAzure = "https://example.cognitiveservices.azure.com"
            try store.chiaveAzure.scrivi("chiave-di-prova")
            #expect(RiconoscimentoTesto.riconoscitore(impostazioni: store).source == .azure)
        }
    }

    @Test("Vision is used when the endpoint is set without the key")
    func visionWithoutKey() {
        withStore { store in
            store.endpointAzure = "https://example.cognitiveservices.azure.com"
            #expect(RiconoscimentoTesto.riconoscitore(impostazioni: store).source == .vision)
        }
    }

    @Test("Vision is used when the key is set without the endpoint")
    func visionWithoutEndpoint() throws {
        try withStore { store in
            try store.chiaveAzure.scrivi("chiave-di-prova")
            #expect(RiconoscimentoTesto.riconoscitore(impostazioni: store).source == .vision)
        }
    }

    @Test("Vision is used when the endpoint is not an http or https URL")
    func visionWithInvalidEndpoint() throws {
        try withStore { store in
            store.endpointAzure = "ftp://example.com"
            try store.chiaveAzure.scrivi("chiave-di-prova")
            #expect(RiconoscimentoTesto.riconoscitore(impostazioni: store).source == .vision)
        }
    }

    @Test("The choice follows the settings at each call")
    func choiceFollowsSettings() throws {
        try withStore { store in
            store.endpointAzure = "https://example.cognitiveservices.azure.com"
            try store.chiaveAzure.scrivi("chiave-di-prova")
            #expect(RiconoscimentoTesto.riconoscitore(impostazioni: store).source == .azure)
            try store.chiaveAzure.scrivi("")
            #expect(RiconoscimentoTesto.riconoscitore(impostazioni: store).source == .vision)
        }
    }
}
