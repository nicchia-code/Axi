import ApplicationServices
import Testing
@testable import AxiScreen

@Suite("Browser Automation states")
struct PermissionsTests {
    @Test func mapsEachAutomationStatusToItsState() {
        #expect(Permissions.automationState(forStatus: noErr) == .granted)
        #expect(Permissions.automationState(forStatus: OSStatus(errAEEventNotPermitted)) == .denied)
        #expect(Permissions.automationState(forStatus: OSStatus(errAEEventWouldRequireUserConsent)) == .notAsked)
    }

    @Test func closedBrowserIsNotKnownRatherThanDenied() {
        #expect(Permissions.automationState(forStatus: OSStatus(procNotFound)) == .browserClosed)
    }

    @Test func grantedIsTheOnlyStateCountedAsGranted() {
        let granted = Permissions.BrowserAutomation(name: "Safari", bundleIdentifier: "com.apple.Safari", state: .granted)
        let closed = Permissions.BrowserAutomation(name: "Chrome", bundleIdentifier: "com.google.Chrome", state: .browserClosed)
        #expect(granted.granted)
        #expect(!closed.granted)
    }

    @Test func finderAutomationNeverCountsAsMissingAtStartup() {
        let finderDenied = Permissions.BrowserAutomation(
            name: "Finder", bundleIdentifier: "com.apple.finder", state: .denied)
        let missing = Permissions.missingAtStartup(
            accessibilityGranted: true, screenRecordingGranted: true, browsers: [finderDenied])
        #expect(missing.isEmpty)
    }

    @Test func deniedOrNotAskedBrowserCountsAsMissingAtStartup() {
        let safari = Permissions.BrowserAutomation(name: "Safari", bundleIdentifier: "com.apple.Safari", state: .notAsked)
        let chrome = Permissions.BrowserAutomation(name: "Chrome", bundleIdentifier: "com.google.Chrome", state: .browserClosed)
        let missing = Permissions.missingAtStartup(
            accessibilityGranted: true, screenRecordingGranted: true, browsers: [safari, chrome])
        #expect(missing == [.browserAutomation])
    }
}
