import AxiScreen
import Foundation

/// Chooses the text recognizer of a screen reading from the settings, at the moment of the reading:
/// Azure Document Intelligence when the user configured it (endpoint and key), Vision on the Mac otherwise.
public enum RiconoscimentoTesto {
    /// The recognizer for one reading. A key that cannot be read from the Keychain counts as not configured.
    public static func riconoscitore(impostazioni: ImpostazioniStore) -> any TextRecognizing {
        guard let configurazione = azureConfigurata(impostazioni: impostazioni) else {
            return VisionTextRecognizer()
        }
        return AzureTextRecognizer(client: AzureDocumentIntelligenceClient(configuration: configurazione))
    }

    /// The Azure configuration, when both the endpoint (an http or https URL) and the key are set.
    static func azureConfigurata(impostazioni: ImpostazioniStore) -> AzureDocumentIntelligenceConfiguration? {
        guard let url = URL(string: impostazioni.endpointAzure),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              url.host != nil,
              let chiave = (try? impostazioni.chiaveAzure.leggi()) ?? nil,
              !chiave.isEmpty else {
            return nil
        }
        return AzureDocumentIntelligenceConfiguration(endpoint: url, apiKey: chiave)
    }
}
