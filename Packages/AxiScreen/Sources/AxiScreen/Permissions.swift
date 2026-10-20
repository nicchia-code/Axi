import AppKit
import ApplicationServices
import CoreGraphics

/// Reads the macOS permissions Axi needs. Reads only: asking is left to the System Settings panes.
public enum Permissions {
    /// Browsers whose tabs Axi may read through Automation, in the order the welcome window shows them.
    private static let automationBrowsers: [(bundleIdentifier: String, name: String)] = [
        ("com.apple.Safari", "Safari"),
        ("com.google.Chrome", "Chrome"),
    ]

    /// The Automation state of one browser as macOS reports it, without asking the user.
    public enum BrowserAutomationState: Sendable, Equatable {
        case granted
        case denied
        case notAsked
        /// The browser is closed, so macOS cannot tell: it is neither granted nor missing.
        case browserClosed
    }

    /// The Automation state of one browser, listed only when the browser is installed.
    public struct BrowserAutomation: Sendable, Equatable, Identifiable {
        public let name: String
        public let bundleIdentifier: String
        public let state: BrowserAutomationState

        public var id: String { bundleIdentifier }

        public var granted: Bool { state == .granted }

        /// The Finder is listed with its state, but its absence does not count as a missing browser permission.
        public var isFinder: Bool { bundleIdentifier == DocumentFinder.finderBundleIdentifier }
    }

    public static func accessibilityGranted() -> Bool {
        AXIsProcessTrusted()
    }

    public static func screenRecordingGranted() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    /// Whether macOS denied the Automation of one browser, or has not asked for it yet.
    /// A browser whose state is unknown (closed) is not counted as missing.
    public static func browserAutomationMissing(bundleIdentifier: String) -> Bool {
        switch automationState(bundleIdentifier: bundleIdentifier) {
        case .denied, .notAsked:
            true
        case .granted, .browserClosed:
            false
        }
    }

    /// The name shown to the user for one of the browsers whose Automation Axi reads, nil for any other app.
    public static func automationBrowserName(bundleIdentifier: String) -> String? {
        automationBrowsers.first { $0.bundleIdentifier == bundleIdentifier }?.name
    }

    /// The Automation state of the Finder, always listed first, then each installed browser among Safari and Chrome.
    /// A browser that is not installed is neither read nor listed.
    public static func automationStates() -> [BrowserAutomation] {
        let finder = BrowserAutomation(
            name: "Finder",
            bundleIdentifier: DocumentFinder.finderBundleIdentifier,
            state: automationState(bundleIdentifier: DocumentFinder.finderBundleIdentifier))
        return [finder] + browserAutomationStates()
    }

    /// The Automation state of each installed browser among Safari and Chrome.
    /// A browser that is not installed is neither read nor listed.
    public static func browserAutomationStates() -> [BrowserAutomation] {
        automationBrowsers.compactMap { browser in
            guard NSWorkspace.shared.urlForApplication(withBundleIdentifier: browser.bundleIdentifier) != nil else {
                return nil
            }
            return BrowserAutomation(
                name: browser.name,
                bundleIdentifier: browser.bundleIdentifier,
                state: automationState(bundleIdentifier: browser.bundleIdentifier))
        }
    }

    /// The permissions that count as missing when the Permissions window is checked at startup: Accessibility,
    /// Screen Recording, and the Automation of a browser macOS denied or has not asked for yet. The Finder's
    /// Automation is not among them, and a closed browser's is unknown, so it is not counted either.
    public static func missingAtStartup() -> [Permission] {
        missingAtStartup(
            accessibilityGranted: accessibilityGranted(),
            screenRecordingGranted: screenRecordingGranted(),
            browsers: browserAutomationStates())
    }

    public static func missingAtStartup(
        accessibilityGranted: Bool,
        screenRecordingGranted: Bool,
        browsers: [BrowserAutomation]
    ) -> [Permission] {
        var missing: [Permission] = []
        if !accessibilityGranted { missing.append(.accessibility) }
        if !screenRecordingGranted { missing.append(.screenRecording) }
        let browserMissing = browsers.contains { browser in
            !browser.isFinder && (browser.state == .denied || browser.state == .notAsked)
        }
        if browserMissing {
            missing.append(.browserAutomation)
        }
        return missing
    }

    private static func automationState(bundleIdentifier: String) -> BrowserAutomationState {
        let target = NSAppleEventDescriptor(bundleIdentifier: bundleIdentifier)
        guard let address = target.aeDesc else {
            return .browserClosed
        }
        let status = AEDeterminePermissionToAutomateTarget(
            address, AEEventClass(typeWildCard), AEEventID(typeWildCard), false)
        return automationState(forStatus: status)
    }

    /// Maps the status of `AEDeterminePermissionToAutomateTarget` to a state.
    /// `procNotFound` (a closed browser) and any other status are not known: `browserClosed`.
    static func automationState(forStatus status: OSStatus) -> BrowserAutomationState {
        switch status {
        case noErr:
            .granted
        case OSStatus(errAEEventNotPermitted):
            .denied
        case OSStatus(errAEEventWouldRequireUserConsent):
            .notAsked
        default:
            .browserClosed
        }
    }

    /// Asks macOS for a permission that is missing, as the Allow button does. macOS shows its own request only once,
    /// so when it no longer shows it, the System Settings pane that holds the permission opens instead.
    /// Accessibility and Screen Recording are asked at once. Each installed browser whose Automation is not yet
    /// decided is asked in turn, off the main thread; the pane opens when a browser was already denied.
    /// The Finder's Automation, which reads its selection, is asked the same way.
    public static func requestAccess(for permission: Permission) async {
        switch permission {
        case .accessibility:
            guard !accessibilityGranted() else { return }
            let alreadyAsked = markAsked(permission)
            // The value of kAXTrustedCheckOptionPrompt, which Swift 6 does not accept as a global var.
            let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
            if alreadyAsked { openSettings(for: permission) }
        case .screenRecording:
            guard !screenRecordingGranted() else { return }
            let alreadyAsked = markAsked(permission)
            _ = CGRequestScreenCaptureAccess()
            if alreadyAsked { openSettings(for: permission) }
        case .browserAutomation:
            let automations = browserAutomationStates()
            for automation in automations where automation.state == .notAsked {
                await askAutomation(bundleIdentifier: automation.bundleIdentifier)
            }
            if automations.contains(where: { $0.state == .denied }) {
                openSettings(for: permission)
            }
        case .finderAutomation:
            let finder = DocumentFinder.finderBundleIdentifier
            if automationState(bundleIdentifier: finder) == .notAsked {
                await askAutomation(bundleIdentifier: finder)
            }
            if automationState(bundleIdentifier: finder) == .denied {
                openSettings(for: permission)
            }
        }
    }

    /// Records that Axi asked for the permission, and tells whether it had asked before.
    private static func markAsked(_ permission: Permission) -> Bool {
        let key = "Permissions.asked.\(permission)"
        let alreadyAsked = UserDefaults.standard.bool(forKey: key)
        UserDefaults.standard.set(true, forKey: key)
        return alreadyAsked
    }

    /// Shows macOS's Automation request for one browser. It blocks until the user answers, so it runs off the main thread.
    private static func askAutomation(bundleIdentifier: String) async {
        await Task.detached {
            let target = NSAppleEventDescriptor(bundleIdentifier: bundleIdentifier)
            guard let address = target.aeDesc else { return }
            _ = AEDeterminePermissionToAutomateTarget(
                address, AEEventClass(typeWildCard), AEEventID(typeWildCard), true)
        }.value
    }

    /// Opens the System Settings pane that holds the permission.
    public static func openSettings(for permission: Permission) {
        guard let url = URL(string: permission.settingsURL) else { return }
        NSWorkspace.shared.open(url)
    }

    public enum Permission: Sendable, CaseIterable {
        case accessibility
        case screenRecording
        case browserAutomation
        /// Automation of the Finder, which reads its selection when Accessibility gives none.
        case finderAutomation

        public var settingsURL: String {
            switch self {
            case .accessibility:
                "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
            case .screenRecording:
                "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
            case .browserAutomation, .finderAutomation:
                "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
            }
        }
    }
}
