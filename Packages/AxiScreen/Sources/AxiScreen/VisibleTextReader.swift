/// Collects the text an application shows in a window, from its Accessibility tree.
public enum VisibleTextReader {
    private static let textRoles: Set<String> = [
        AccessibilityRole.staticText,
        AccessibilityRole.textArea,
        AccessibilityRole.heading,
        AccessibilityRole.link,
    ]

    /// The visible text in reading order, one line per element. Nil when the window shows none.
    public static func text(in window: AccessibilityNode) -> String? {
        var lines: [String] = []
        for node in window.descendantsAndSelf {
            guard let role = node.role, textRoles.contains(role), let text = node.shownText else { continue }
            guard text != lines.last else { continue }
            lines.append(text)
        }
        let joined = lines.joined(separator: "\n")
        return joined.isEmpty ? nil : joined
    }

    /// The text of a browser's page: only that of its web area, without tabs, address bar, bookmarks and toolbars.
    /// Nil when the window has no web area or the area shows no text.
    public static func pageText(in window: AccessibilityNode) -> String? {
        guard let area = window.descendantsAndSelf.first(where: { $0.role == AccessibilityRole.webArea }) else {
            return nil
        }
        return text(in: area)
    }
}
