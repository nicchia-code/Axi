import ApplicationServices
import AppKit
import CoreGraphics
import Foundation
import ScreenCaptureKit
import Vision

/// What the Accessibility reading fails on for no known reason.
public enum AccessibilityReadingError: Error, Equatable {
    /// The Accessibility call returned this status, which no other outcome explains.
    case unexpected(Int32)
}

/// Reads the Accessibility tree of an application through `AXUIElement`.
public struct LiveAccessibilityReader: AccessibilityReading {
    private static let maxDepth = 40
    private static let maxElements = 5000

    public init() {}

    public func snapshot(of application: ApplicationSnapshot) async throws -> AccessibilitySnapshot? {
        let app = AXUIElementCreateApplication(application.processIdentifier)
        _ = AXUIElementSetMessagingTimeout(app, 2)
        let isFirefox = application.bundleIdentifier == DocumentFinder.firefoxBundleIdentifier
        let turnedOn = isFirefox && Self.turnOnEnhancedInterface(app)
        defer {
            if turnedOn { _ = AXUIElementSetAttributeValue(app, Self.enhancedInterfaceAttribute as CFString, kCFBooleanFalse) }
        }
        guard let window = try Self.mainWindow(app) else {
            return nil
        }
        var budget = Self.maxElements
        var tree = Self.node(window, depth: 0, budget: &budget)
        if tree.url == nil, let bundle = application.bundleIdentifier,
           BrowserTabAutomation.bundleIdentifiers.contains(bundle),
           !tree.descendantsAndSelf.contains(where: { $0.url != nil }),
           BrowserAddress.addressBarURL(in: tree) == nil {
            tree.url = await BrowserTabAutomation.activeTabURL(bundleIdentifier: bundle)
        }
        return AccessibilitySnapshot(application: application, window: tree)
    }

    /// The main window, else the focused one; nil when the application shows none. A busy application
    /// (`cannotComplete`) reads as having none. Any other status throws `AccessibilityReadingError.unexpected`.
    private static func mainWindow(_ app: AXUIElement) throws -> AXUIElement? {
        let attributes: [CFString] = [kAXMainWindowAttribute as CFString, kAXFocusedWindowAttribute as CFString]
        for attribute in attributes {
            var value: CFTypeRef?
            let status = AXUIElementCopyAttributeValue(app, attribute, &value)
            switch status {
            case .success:
                if let value, CFGetTypeID(value) == AXUIElementGetTypeID() {
                    return unsafeDowncast(value as AnyObject, to: AXUIElement.self)
                }
            case .noValue, .attributeUnsupported, .cannotComplete:
                continue
            default:
                throw AccessibilityReadingError.unexpected(status.rawValue)
            }
        }
        return nil
    }

    public func perform(action: String, onElementNamed name: String, in application: ApplicationSnapshot) async -> Bool {
        let app = AXUIElementCreateApplication(application.processIdentifier)
        _ = AXUIElementSetMessagingTimeout(app, 2)
        guard let window = Self.element(app, kAXMainWindowAttribute as CFString)
            ?? Self.element(app, kAXFocusedWindowAttribute as CFString) else {
            return false
        }
        var budget = Self.maxElements
        guard let target = Self.find(named: name, accepting: action, in: window, depth: 0, budget: &budget) else {
            return false
        }
        return AXUIElementPerformAction(target, action as CFString) == .success
    }

    /// The first element, in reading order, whose title or description is `name` and that accepts `action`.
    private static func find(named name: String, accepting action: String, in element: AXUIElement, depth: Int, budget: inout Int) -> AXUIElement? {
        budget -= 1
        let names = [string(element, kAXTitleAttribute as CFString), string(element, kAXDescriptionAttribute as CFString)].compactMap { $0 }
        if names.contains(where: { $0.trimmingCharacters(in: .whitespaces).caseInsensitiveCompare(name) == .orderedSame }),
           actionNames(element).contains(action) {
            return element
        }
        guard depth < maxDepth else { return nil }
        for child in children(element) {
            guard budget > 0 else { break }
            if let found = find(named: name, accepting: action, in: child, depth: depth + 1, budget: &budget) {
                return found
            }
        }
        return nil
    }

    private static func actionNames(_ element: AXUIElement) -> [String] {
        var names: CFArray?
        guard AXUIElementCopyActionNames(element, &names) == .success else { return [] }
        return (names as? [String]) ?? []
    }

    private static func node(_ element: AXUIElement, depth: Int, budget: inout Int) -> AccessibilityNode {
        budget -= 1
        let role = string(element, kAXRoleAttribute as CFString)
        let readsURL = depth == 0 || role == AccessibilityRole.webArea
        var node = AccessibilityNode(
            role: role,
            title: string(element, kAXTitleAttribute as CFString),
            label: string(element, kAXDescriptionAttribute as CFString),
            value: string(element, kAXValueAttribute as CFString),
            url: readsURL ? (url(element, kAXURLAttribute as CFString) ?? url(element, kAXDocumentAttribute as CFString)) : nil,
            actions: actionNames(element),
            selectedURLs: selectedURLs(element))
        guard depth < maxDepth else { return node }
        for child in children(element) {
            guard budget > 0 else { break }
            node.children.append(Self.node(child, depth: depth + 1, budget: &budget))
        }
        return node
    }

    private static func copy(_ element: AXUIElement, _ attribute: CFString) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else { return nil }
        return value
    }

    private static func string(_ element: AXUIElement, _ attribute: CFString) -> String? {
        copy(element, attribute) as? String
    }

    private static func url(_ element: AXUIElement, _ attribute: CFString) -> URL? {
        guard let value = copy(element, attribute) else { return nil }
        if let url = value as? URL { return url }
        if let text = value as? String { return URL(string: text) }
        return nil
    }

    /// The file or folder URLs of the children an element selects, in selection order.
    /// Finder reports its selection through the children (icon and column views) or the rows (list view).
    private static func selectedURLs(_ element: AXUIElement) -> [URL] {
        for attribute in [kAXSelectedChildrenAttribute, kAXSelectedRowsAttribute] {
            let selected = (copy(element, attribute as CFString) as? [AXUIElement]) ?? []
            let urls = selected.compactMap { url($0, kAXURLAttribute as CFString) }
            if !urls.isEmpty { return urls }
        }
        return []
    }

    private static func element(_ element: AXUIElement, _ attribute: CFString) -> AXUIElement? {
        guard let value = copy(element, attribute), CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }
        return unsafeDowncast(value as AnyObject, to: AXUIElement.self)
    }

    /// Firefox shows the content of its pages to Accessibility only while `AXEnhancedUserInterface` is on
    /// (it does not accept `AXManualAccessibility`). Returns true when it was off and is now on.
    private static func turnOnEnhancedInterface(_ app: AXUIElement) -> Bool {
        guard (copy(app, enhancedInterfaceAttribute as CFString) as? Bool) != true else { return false }
        return AXUIElementSetAttributeValue(app, enhancedInterfaceAttribute as CFString, kCFBooleanTrue) == .success
    }

    private static let enhancedInterfaceAttribute = "AXEnhancedUserInterface"

    private static func children(_ element: AXUIElement) -> [AXUIElement] {
        (copy(element, kAXChildrenAttribute as CFString) as? [AXUIElement]) ?? []
    }
}

/// Asks a browser for the address of its active tab, where Accessibility does not expose it.
@MainActor
enum BrowserTabAutomation {
    /// Safari and Chrome only: Firefox never gets Apple Events for the address of its page.
    nonisolated static let bundleIdentifiers: Set<String> = ["com.apple.Safari", "com.google.Chrome"]

    static func activeTabURL(bundleIdentifier: String) async -> URL? {
        let script: String
        switch bundleIdentifier {
        case "com.apple.Safari":
            script = "tell application id \"com.apple.Safari\" to return URL of current tab of front window"
        case "com.google.Chrome":
            script = "tell application id \"com.google.Chrome\" to return URL of active tab of front window"
        default:
            return nil
        }
        var error: NSDictionary?
        guard let result = NSAppleScript(source: script)?.executeAndReturnError(&error),
              let text = result.stringValue else {
            return nil
        }
        return URL(string: text)
    }
}

/// Reads the Finder selection through Apple Events, where Accessibility gives none.
public struct LiveFinderSelection: FinderSelectionReading {
    public init() {}

    public func selectedURLs() async -> [URL]? {
        await FinderAutomation.selectedURLs()
    }
}

/// Asks the Finder for the items it has selected, in selection order, through Apple Events.
@MainActor
enum FinderAutomation {
    static func selectedURLs() -> [URL]? {
        let script = """
        set picked to {}
        tell application id "com.apple.finder" to set picked to selection
        set paths to {}
        repeat with item_ in picked
            set end of paths to POSIX path of (item_ as alias)
        end repeat
        return paths
        """
        var error: NSDictionary?
        guard let result = NSAppleScript(source: script)?.executeAndReturnError(&error) else {
            return nil
        }
        return (0..<result.numberOfItems).compactMap { index in
            result.atIndex(index + 1)?.stringValue.map { URL(fileURLWithPath: $0) }
        }
    }
}

/// Captures the main window of an application with ScreenCaptureKit.
public struct WindowCapturer: WindowCapturing {
    public enum Failure: Error {
        case noWindow
    }

    public init() {}

    public func capture(of application: ApplicationSnapshot) async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        let windows = content.windows.filter {
            $0.owningApplication?.processID == application.processIdentifier && $0.windowLayer == 0
        }
        guard let window = windows.max(by: { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }) else {
            throw Failure.noWindow
        }
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let configuration = SCStreamConfiguration()
        let scale = CGFloat(filter.pointPixelScale)
        configuration.width = Int(window.frame.width * scale)
        configuration.height = Int(window.frame.height * scale)
        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
    }
}

/// Recognizes text on the Mac with Vision, in Italian and English.
public struct VisionTextRecognizer: TextRecognizing {
    public let source = TextSource.vision

    public init() {}

    public func recognizeText(in image: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["it-IT", "en-US"]
            request.usesLanguageCorrection = true
            do {
                try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

/// The permissions read from the system.
public struct SystemScreenPermissions: ScreenPermissions {
    public init() {}

    public var accessibilityGranted: Bool { Permissions.accessibilityGranted() }
    public var screenRecordingGranted: Bool { Permissions.screenRecordingGranted() }

    public func browserAutomationMissing(bundleIdentifier: String) -> Bool {
        Permissions.browserAutomationMissing(bundleIdentifier: bundleIdentifier)
    }
}
