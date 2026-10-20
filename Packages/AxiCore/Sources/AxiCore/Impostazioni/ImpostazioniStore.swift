import Foundation

/// Preferences of the `impostazioni` Machine: preferences in `UserDefaults`, and the
/// Azure Document Intelligence key in the Keychain, never on disk in clear.
public struct ImpostazioniStore: @unchecked Sendable {
    /// Model chosen in the Settings window, in OMP's `provider/id` format.
    public static let modelloAIKey = "ai.model"
    /// Path of the OMP executable, passed by the app to AxiOMP.
    public static let percorsoOMPKey = "omp.path"
    public static let azureEndpointKey = "azure.endpoint"
    /// "Tasti Apple" switch: Axi takes the Spotlight and Dictation keys while it is on.
    public static let tastiAppleAttiviKey = "tasti.apple.attivi"

    // `UserDefaults` is documented as thread-safe, so sharing it across actors is sound.
    public let defaults: UserDefaults
    public let chiaveAzure: CredenzialeKeychain

    public init(
        defaults: UserDefaults = .standard,
        chiaveAzure: CredenzialeKeychain = CredenzialeKeychain(
            service: "Axi", account: "azure-document-intelligence")
    ) {
        self.defaults = defaults
        self.chiaveAzure = chiaveAzure
    }

    /// Model chosen in the Settings window; `nil` when the OMP default is used.
    public var modelloAI: String? {
        get { defaults.string(forKey: Self.modelloAIKey) }
        nonmutating set { defaults.set(newValue, forKey: Self.modelloAIKey) }
    }

    /// Path of the OMP executable; `nil` when the app should locate it itself.
    public var percorsoOMP: String? {
        get { defaults.string(forKey: Self.percorsoOMPKey) }
        nonmutating set { defaults.set(newValue, forKey: Self.percorsoOMPKey) }
    }

    /// Endpoint of Azure Document Intelligence; empty when not configured.
    public var endpointAzure: String {
        get { defaults.string(forKey: Self.azureEndpointKey) ?? "" }
        nonmutating set { defaults.set(newValue, forKey: Self.azureEndpointKey) }
    }

    /// Whether Axi takes the Spotlight and Dictation keys of Apple keyboards; off until the user turns it on.
    public var tastiAppleAttivi: Bool {
        get { defaults.bool(forKey: Self.tastiAppleAttiviKey) }
        nonmutating set { defaults.set(newValue, forKey: Self.tastiAppleAttiviKey) }
    }
}
