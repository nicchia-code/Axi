import AppKit
import Foundation

/// Accessibility roles the readers look for.
public enum AccessibilityRole {
    public static let staticText = "AXStaticText"
    public static let textArea = "AXTextArea"
    public static let textField = "AXTextField"
    public static let secureTextField = "AXSecureTextField"
    public static let comboBox = "AXComboBox"
    public static let heading = "AXHeading"
    public static let link = "AXLink"
    public static let webArea = "AXWebArea"
}

/// An application as it was when the user asked for a reading.
public struct ApplicationSnapshot: Sendable, Equatable {
    public var bundleIdentifier: String?
    public var name: String
    public var processIdentifier: pid_t

    public init(bundleIdentifier: String?, name: String, processIdentifier: pid_t) {
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.processIdentifier = processIdentifier
    }
}

/// The application that is in front right now. Call it before Axi takes the focus.
@MainActor
public enum FrontmostApplication {
    public static func current() -> ApplicationSnapshot? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        return ApplicationSnapshot(
            bundleIdentifier: app.bundleIdentifier,
            name: app.localizedName ?? "",
            processIdentifier: app.processIdentifier)
    }
}

/// A plain copy of one element of an application's Accessibility tree.
public struct AccessibilityNode: Sendable, Equatable {
    public var role: String?
    public var title: String?
    public var label: String?
    public var value: String?
    public var url: URL?
    /// The file or folder URLs of the children this element selects, in selection order (Finder selections).
    public var selectedURLs: [URL]
    /// The names of the actions the element accepts, as Accessibility reports them (for example `AXPress`).
    public var actions: [String]
    public var children: [AccessibilityNode]

    public init(
        role: String? = nil,
        title: String? = nil,
        label: String? = nil,
        value: String? = nil,
        url: URL? = nil,
        actions: [String] = [],
        selectedURLs: [URL] = [],
        children: [AccessibilityNode] = []
    ) {
        self.role = role
        self.title = title
        self.label = label
        self.value = value
        self.url = url
        self.actions = actions
        self.selectedURLs = selectedURLs
        self.children = children
    }

    /// This node followed by all its descendants, in reading order.
    public var descendantsAndSelf: [AccessibilityNode] {
        var result: [AccessibilityNode] = []
        var stack = [self]
        while let node = stack.popLast() {
            result.append(node)
            stack.append(contentsOf: node.children.reversed())
        }
        return result
    }

    /// The text the element shows: its value, or else its title. Nil when empty.
    public var shownText: String? {
        nonEmpty(value) ?? nonEmpty(title)
    }
}

/// The main window of the application a reading is about.
public struct AccessibilitySnapshot: Sendable, Equatable {
    public var application: ApplicationSnapshot
    /// The window; its `url` is the open document (`AXDocument`) or the page address.
    public var window: AccessibilityNode

    public init(application: ApplicationSnapshot, window: AccessibilityNode) {
        self.application = application
        self.window = window
    }

    /// The URLs the elements of the window select, in reading order and in selection order within each element.
    public var selectedURLs: [URL] {
        window.descendantsAndSelf.flatMap(\.selectedURLs)
    }
}

func nonEmpty(_ text: String?) -> String? {
    guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
        return nil
    }
    return trimmed
}
