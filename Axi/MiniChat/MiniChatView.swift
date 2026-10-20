import AxiScreen
import SwiftUI

/// The mini-chat window that grows from the puntino.
struct MiniChatView: View {
    let controller: MiniChatController

    @State private var draft = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var model: MiniChatModel { controller.model }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if model.state == .conversationList {
                ConversationListView(controller: controller)
            } else {
                transcript
                composer
            }
        }
        .frame(minWidth: 320, idealWidth: 380, minHeight: 400, idealHeight: 520)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
        .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.35), value: model.state)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            titleText(model.conversation.title)
                .font(.headline)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                controller.send(.newConversation)
            } label: {
                Label("New", systemImage: "square.and.pencil")
            }
            .help("New conversation")
            Button {
                controller.send(.openConversationList)
            } label: {
                Label("Conversations", systemImage: "list.bullet")
            }
            .help("Conversations")
            Button {
                controller.send(.closeChat)
            } label: {
                Label("Close", systemImage: "xmark")
            }
            .help("Close")
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .padding(12)
    }

    // MARK: - Transcript

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if model.conversation.messages.isEmpty && model.pendingAnswer == nil {
                        Text("Ask something about your documents or the screen.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(model.conversation.messages) { message in
                        MessageView(
                            message: message,
                            showRetry: message.id == model.conversation.messages.last?.id && model.canRetry,
                            onOpen: { citation in controller.send(.openCitedDocument(citation)) },
                            onRetry: { controller.send(.retryAnswer) },
                            summary: model.answerSummary
                        )
                        .id(message.id)
                    }
                    if let pending = model.pendingAnswer {
                        if !pending.steps.isEmpty || !pending.reasoning.isEmpty {
                            AnswerProgress(steps: pending.steps, reasoning: pending.reasoning)
                        }
                        if pending.steps.isEmpty && pending.reasoning.isEmpty && pending.text.isEmpty {
                            AnimatedDots()
                        }
                        if !pending.text.isEmpty {
                            MessageBubble(markdown: pending.text, author: .axi)
                        }
                        ForEach(pending.citations, id: \.self) { citation in
                            CitationLabel(citation: citation) {
                                controller.send(.openCitedDocument(citation))
                            }
                        }
                        .id("pending")
                    }
                    if model.state == .confirmingDeletion, let preview = model.pendingDeletion {
                        DeletionCard(
                            preview: preview,
                            onConfirm: { controller.send(.confirmDeletion) },
                            onCancel: { controller.send(.cancelDeletion) }
                        )
                        .transition(reduceMotion ? .opacity : .scale(scale: 0.95).combined(with: .opacity))
                        .id("deletion")
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onChange(of: model.conversation.messages.count) {
                if let last = model.conversation.messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
            .onChange(of: model.state) {
                if model.state == .confirmingDeletion {
                    proxy.scrollTo("deletion", anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Composer

    private var composer: some View {
        VStack(alignment: .leading, spacing: 8) {
            if case .context(let context) = model.screen {
                ScreenContextLabel(context: context) {
                    controller.send(.removeContext)
                }
            } else if case .unreadable(let failure) = model.screen {
                Text(unreadableNotice(failure))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if case .permissionMissing? = failure {
                    Button("Open permissions") {
                        controller.apriPermessi()
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }
            }
            if model.leftoverFile {
                Text("A deleted document's file stays on disk until the next launch.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Ask Axi", text: $draft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .onSubmit(send)
                    .disabled(model.state != .ready)
                if model.state == .answering {
                    Button {
                        controller.send(.interruptAnswer)
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                            .labelStyle(.iconOnly)
                    }
                    .help("Stop")
                } else {
                    Button(action: send) {
                        Label("Send", systemImage: "arrow.up.circle.fill")
                            .labelStyle(.iconOnly)
                    }
                    .help("Send")
                    .disabled(model.state != .ready || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .buttonStyle(.borderless)
            .font(.title2)
        }
        .padding(12)
    }

    private func send() {
        let question = draft
        draft = ""
        controller.send(.sendQuestion(question))
    }
}

private extension ChatError {
    var text: LocalizedStringKey {
        switch self {
        case .answerFailed:
            "The answer failed."
        case .ompStopped:
            "The answer service stopped."
        }
    }
}

// MARK: - Parts

private struct MessageView: View {
    let message: ChatMessage
    let showRetry: Bool
    let onOpen: (DocumentCitation) -> Void
    let onRetry: () -> Void
    let summary: AnswerSummary?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let context = message.screenContext {
                ScreenContextLabel(context: context, onRemove: nil)
            }
            if let summary, summary.messageID == message.id {
                AnswerSummaryView(summary: summary)
            }
            if let failure = message.failure {
                Text(failure.text)
                    .font(.callout)
                    .foregroundStyle(.red)
                if showRetry {
                    Button("Retry", action: onRetry)
                }
            } else {
                MessageBubble(markdown: message.text, author: message.author)
            }
            ForEach(message.citations, id: \.self) { citation in
                CitationLabel(citation: citation) { onOpen(citation) }
            }
        }
        .frame(maxWidth: .infinity, alignment: message.author == .user ? .trailing : .leading)
    }
}

private struct MessageBubble: View {
    let markdown: String
    let author: ChatMessage.Author

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(MarkdownBlock.blocks(from: markdown)) { block in
                MarkdownBlockView(block: block)
            }
        }
        .textSelection(.enabled)
        .padding(10)
        .background(
            author == .user ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.06),
            in: .rect(cornerRadius: 12)
        )
    }
}

/// The three dots that show work in progress; they stand still when Reduce Motion is on.
private struct AnimatedDots: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            Text("…")
                .foregroundStyle(.secondary)
        } else {
            TimelineView(.periodic(from: .now, by: 0.4)) { context in
                let count = Int(context.date.timeIntervalSinceReferenceDate / 0.4) % 3 + 1
                Text(String(repeating: "•", count: count))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// The steps of an answer, one per line in order, and the last sentence of its reasoning in italics.
private struct AnswerProgress: View {
    let steps: [AnswerStep]
    let reasoning: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(steps) { step in
                HStack(spacing: 4) {
                    Text(step.title)
                    if !step.isDone {
                        AnimatedDots()
                    }
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }
            if let sentence = Self.lastSentence(of: reasoning) {
                Text(sentence)
                    .font(.callout.italic())
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// The last sentence of the reasoning as written so far, or nil when there is none.
    static func lastSentence(of text: String) -> String? {
        text.split(whereSeparator: { ".!?\n".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .last { !$0.isEmpty }
    }
}

/// The steps and reasoning of a finished answer, collapsed to one line that expands on click.
private struct AnswerSummaryView: View {
    let summary: AnswerSummary
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                expanded.toggle()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                    Text(line)
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            if expanded {
                AnswerProgress(steps: summary.steps, reasoning: summary.reasoning)
            }
        }
    }

    private var line: LocalizedStringKey {
        let searches = summary.steps.filter { step in
            if case .searchVault = step.kind { return step.isDone }
            return false
        }.count
        let pages = summary.steps.filter { step in
            if case .readPage = step.kind { return step.isDone }
            return false
        }.count
        if searches > 0 && pages > 0 {
            return "Searched \(searches) times and read \(pages) pages"
        } else if searches > 0 {
            return "Searched \(searches) times"
        } else if pages > 0 {
            return "Read \(pages) pages"
        } else if !summary.steps.isEmpty {
            return "\(summary.steps.count) steps"
        }
        return "Reasoned"
    }
}

private extension AnswerStep {
    /// The line that names the step, in the words of the Model.
    var title: LocalizedStringKey {
        switch kind {
        case .searchVault(let words):
            words.isEmpty ? "Searching the vault" : "Searching the vault for “\(words)”"
        case .readPage(let page, let title):
            "Reading page \(page) of “\(title)”"
        case .cite(let count):
            count == 1 ? "Citing 1 document" : "Citing \(count) documents"
        case .changeTags(let title):
            "Changing the tags of “\(title)”"
        case .askDeletion(let title):
            "Asking to delete “\(title)”"
        case .retry(let attempt, let maximum):
            "The provider isn't responding, retrying (\(attempt) of \(maximum))"
        case .summarize:
            "Summarizing the conversation"
        }
    }
}

/// One top-level Markdown block (paragraph, heading, list item, code block, quote or rule).
private struct MarkdownBlock: Identifiable {
    enum Kind: Equatable {
        case paragraph
        case heading(level: Int)
        case listItem(marker: String, depth: Int)
        case code(language: String?)
        case quote
        case rule
    }

    let id: Int
    let kind: Kind
    let text: AttributedString

    /// Parses the Markdown into blocks. Falls back to plain text when parsing fails.
    static func blocks(from markdown: String) -> [MarkdownBlock] {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .full,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        guard let parsed = try? AttributedString(markdown: markdown, options: options) else {
            return [MarkdownBlock(id: 0, kind: .paragraph, text: AttributedString(markdown))]
        }

        // Group consecutive runs that share the same block-level intent.
        var groups: [(intent: PresentationIntent?, text: AttributedString)] = []
        for run in parsed.runs {
            let piece = parsed[run.range]
            if let last = groups.indices.last, groups[last].intent == run.presentationIntent {
                groups[last].text.append(piece)
            } else {
                groups.append((run.presentationIntent, AttributedString(piece)))
            }
        }

        var blocks: [MarkdownBlock] = []
        for group in groups {
            var text = group.text
            let trimmed = String(text.characters).trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            let blockKind = kind(for: group.intent, text: &text)
            blocks.append(MarkdownBlock(id: blocks.count, kind: blockKind, text: text))
        }
        return blocks.isEmpty ? [MarkdownBlock(id: 0, kind: .paragraph, text: AttributedString(markdown))] : blocks
    }

    private static func kind(for intent: PresentationIntent?, text: inout AttributedString) -> Kind {
        guard let components = intent?.components else { return .paragraph }
        var depth = 0
        var isOrdered = false
        var ordinal = 1
        var listItem = false
        var kind: Kind = .paragraph
        for component in components {
            switch component.kind {
            case .orderedList:
                depth += 1
                isOrdered = true
            case .unorderedList:
                depth += 1
                isOrdered = false
            case .listItem(let number):
                listItem = true
                ordinal = number
            case .header(let level):
                kind = .heading(level: level)
            case .codeBlock(let language):
                kind = .code(language: language)
            case .blockQuote:
                kind = .quote
            case .thematicBreak:
                kind = .rule
            default:
                break
            }
        }
        if listItem {
            let marker = isOrdered ? "\(ordinal)." : "•"
            return .listItem(marker: marker, depth: max(depth, 1))
        }
        if case .code = kind {
            while text.characters.last?.isNewline == true { text.characters.removeLast() }
        }
        return kind
    }
}

/// Lays out one Markdown block.
private struct MarkdownBlockView: View {
    let block: MarkdownBlock

    var body: some View {
        switch block.kind {
        case .paragraph:
            Text(block.text)
        case .heading(let level):
            Text(block.text)
                .font(level <= 1 ? .title3 : level == 2 ? .headline : .subheadline)
                .bold()
        case .listItem(let marker, let depth):
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(marker).monospacedDigit()
                Text(block.text)
            }
            .padding(.leading, CGFloat(depth - 1) * 14)
        case .code:
            ScrollView(.horizontal) {
                Text(block.text)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(8)
            }
            .background(Color.primary.opacity(0.08), in: .rect(cornerRadius: 8))
        case .quote:
            Text(block.text)
                .foregroundStyle(.secondary)
                .padding(.leading, 10)
                .overlay(alignment: .leading) {
                    Rectangle().fill(Color.secondary.opacity(0.5)).frame(width: 3)
                }
        case .rule:
            Divider()
        }
    }
}

private struct CitationLabel: View {
    let citation: DocumentCitation
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                if let page = citation.page {
                    Text("\(citation.title) · page \(page)")
                } else {
                    Text(citation.title)
                }
            } icon: {
                Image(systemName: "doc.text")
            }
            .font(.callout)
        }
        .buttonStyle(.borderless)
    }
}

private struct ScreenContextLabel: View {
    let context: ScreenContext
    let onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            AppIcon(bundleIdentifier: context.bundleIdentifier)
                .frame(width: 18, height: 18)
            Text(context.title.isEmpty ? context.appName : context.title)
                .font(.callout)
                .lineLimit(1)
            if let onRemove {
                Spacer(minLength: 0)
                Button(action: onRemove) {
                    Label("Remove context", systemImage: "xmark.circle.fill")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.06), in: .capsule)
    }
}

private struct AppIcon: View {
    let bundleIdentifier: String?

    var body: some View {
        Image(nsImage: icon)
            .resizable()
            .interpolation(.high)
    }

    private var icon: NSImage {
        guard let bundleIdentifier,
              let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return NSWorkspace.shared.icon(for: .application)
        }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
}

/// Confirmation of a document deletion requested by the assistant.
struct DeletionCard: View {
    let preview: DeletionPreview
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Delete this document?")
                .font(.headline)
            VStack(alignment: .leading, spacing: 4) {
                Text(preview.title).font(.body.weight(.semibold))
                Text("Type: \(preview.kind)")
                Text("Archived on \(preview.archivedAt.formatted(date: .abbreviated, time: .omitted))")
            }
            .font(.callout)
            if !preview.attachments.isEmpty {
                Text("Attachments that will disappear")
                    .font(.callout.weight(.semibold))
                ForEach(preview.attachments, id: \.self) { attachment in
                    Label(attachment, systemImage: "paperclip")
                        .font(.callout)
                }
            }
            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Delete", role: .destructive, action: onConfirm)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(maxWidth: 320, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .shadow(radius: 12)
    }
}

/// The saved conversations, newest first, each with a delete action.
struct ConversationListView: View {
    let controller: MiniChatController

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Conversations").font(.headline)
                Spacer()
                Button("Close list") {
                    controller.send(.closeConversationList)
                }
            }
            .padding(12)
            Divider()
            if controller.model.unreadableConversation != nil {
                Text("This conversation couldn't be opened. It was left unchanged.")
                    .foregroundStyle(.secondary)
                    .padding(12)
            }
            if controller.summaries.isEmpty {
                Text("No conversations")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(controller.summaries) { summary in
                    HStack {
                        Button {
                            controller.send(.reopenConversation(summary.id))
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                titleText(summary.title)
                                    .lineLimit(1)
                                Text(summary.lastMessageAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        Button {
                            controller.send(.deleteConversation(summary.id))
                        } label: {
                            Label("Delete conversation", systemImage: "trash")
                                .labelStyle(.iconOnly)
                        }
                        .buttonStyle(.borderless)
                        .help("Delete conversation")
                    }
                }
            }
        }
        .onAppear {
            controller.reloadSummaries()
        }
    }
}

/// A conversation title, or the localized placeholder when the conversation has none yet.
private func titleText(_ title: String) -> Text {
    title.isEmpty ? Text("New conversation") : Text(verbatim: title)
}

/// The notice that replaces the screen label when the screen could not be read: it names the missing
/// permissions, and says only that the screen could not be read when no permission is missing.
private func unreadableNotice(_ failure: ReadingFailure?) -> LocalizedStringKey {
    guard case .permissionMissing(let missing)? = failure else {
        return "I couldn't read the screen."
    }
    switch (missing.contains(.accessibility), missing.contains(.screenRecording)) {
    case (true, true):
        return "I couldn't read the screen: the Accessibility and Screen Recording permissions are missing. I'll answer from the vault only."
    case (false, true):
        return "I couldn't read the screen: the Screen Recording permission is missing. I'll answer from the vault only."
    default:
        return "I couldn't read the screen."
    }
}
