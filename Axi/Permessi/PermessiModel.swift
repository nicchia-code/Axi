import AxiScreen
import Foundation
import Observation

/// State of the Permissions window: the readings of macOS, and whether Screen Recording waits for Axi to reopen.
/// The window reads them again every second while it is open.
@MainActor
@Observable
final class PermessiModel {
    private(set) var accessibilityGranted = false
    private(set) var screenRecordingGranted = false
    private(set) var automations: [Permissions.BrowserAutomation] = []
    /// The permissions that count as missing: Accessibility, Screen Recording and the Automation of a browser.
    private(set) var mancanti: [Permissions.Permission] = []
    /// Screen Recording was asked in this run: macOS applies it only when Axi is reopened.
    private(set) var screenRecordingChiesto = false

    /// Screen Recording was asked and is not in effect yet: the row waits for Axi to be reopened.
    var attesaRiapertura: Bool { screenRecordingChiesto && !screenRecordingGranted }

    /// Every permission that counts is granted and nothing waits for the reopen.
    var tuttoPronto: Bool { mancanti.isEmpty && !attesaRiapertura }

    func refresh() {
        accessibilityGranted = Permissions.accessibilityGranted()
        screenRecordingGranted = Permissions.screenRecordingGranted()
        automations = Permissions.automationStates()
        mancanti = Permissions.missingAtStartup(
            accessibilityGranted: accessibilityGranted,
            screenRecordingGranted: screenRecordingGranted,
            browsers: automations)
    }

    /// `utente.CHIEDE_PERMESSO`: asks macOS for the permission, then reads the permissions again.
    func chiede(_ permesso: Permissions.Permission) async {
        if permesso == .screenRecording {
            screenRecordingChiesto = true
        }
        await Permissions.requestAccess(for: permesso)
        refresh()
    }
}
