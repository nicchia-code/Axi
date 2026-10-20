import Foundation
import Testing
@testable import AxiCore

@Suite("Impostazioni store")
struct ImpostazioniStoreTests {
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

    @Test("Model choice is absent until the user picks one")
    func modelloAbsentByDefault() {
        withStore { store in
            #expect(store.modelloAI == nil)
            store.modelloAI = "gpt-x"
            #expect(store.modelloAI == "gpt-x")
            store.modelloAI = nil
            #expect(store.modelloAI == nil)
        }
    }

    @Test("Azure endpoint is empty until configured")
    func endpointVuoto() {
        withStore { store in
            #expect(store.endpointAzure == "")
            store.endpointAzure = "https://example.cognitiveservices.azure.com"
            #expect(store.endpointAzure == "https://example.cognitiveservices.azure.com")
        }
    }

    @Test("Azure key round-trips through the Keychain and can be removed")
    func chiaveKeychain() throws {
        try withStore { store in
            #expect(try store.chiaveAzure.leggi() == nil)
            try store.chiaveAzure.scrivi("segreto-1")
            #expect(try store.chiaveAzure.leggi() == "segreto-1")
            try store.chiaveAzure.scrivi("segreto-2")
            #expect(try store.chiaveAzure.leggi() == "segreto-2")
            try store.chiaveAzure.scrivi("")
            #expect(try store.chiaveAzure.leggi() == nil)
        }
    }

    @Test("Apple keys switch is off until the user turns it on")
    func tastiAppleOffByDefault() {
        withStore { store in
            #expect(store.tastiAppleAttivi == false)
            store.tastiAppleAttivi = true
            #expect(store.tastiAppleAttivi)
            store.tastiAppleAttivi = false
            #expect(store.tastiAppleAttivi == false)
        }
    }
}
