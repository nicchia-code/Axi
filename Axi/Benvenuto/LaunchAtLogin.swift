import OSLog
import ServiceManagement

/// Opens Axi at each login of the user. Turned on once, when the welcome is completed: a later switch off stays off.
enum LaunchAtLogin {
    /// Set once the launch at login was turned on by the welcome, so it is never turned on again.
    private static let enabledByWelcomeKey = "LaunchAtLogin.enabledByWelcome"
    private static let logger = Logger(subsystem: "Axi", category: "avvio")

    /// Turns the launch at login on the first time the welcome is completed, and never again after that.
    static func enableOnceAtWelcomeCompletion() {
        guard !UserDefaults.standard.bool(forKey: enabledByWelcomeKey) else { return }
        do {
            try SMAppService.mainApp.register()
            UserDefaults.standard.set(true, forKey: enabledByWelcomeKey)
        } catch {
            logger.error("Launch at login could not be turned on: \(error.localizedDescription, privacy: .public)")
        }
    }
}
