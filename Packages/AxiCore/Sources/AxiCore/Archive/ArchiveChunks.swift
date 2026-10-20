import Foundation

/// Estimates tokens without a tokenizer: about four tokens every three words.
enum TokenEstimate {
    static func tokens(_ text: String) -> Int {
        (wordCount(text) * 4 + 2) / 3
    }

    static func wordCount(_ text: String) -> Int {
        text.split(whereSeparator: \.isWhitespace).count
    }

    /// How many words make about `tokens` tokens (at least one word).
    static func words(fitting tokens: Int) -> Int {
        max(1, tokens * 3 / 4)
    }
}

/// A passage of one page, before its embedding.
struct Passage: Equatable {
    var text: String
    var page: Int
}

/// Cuts pages into overlapping passages of about 500 tokens with about 50 tokens of overlap.
/// A passage never crosses a page, so each one knows its page.
enum Chunker {
    static let targetTokens = 500
    static let overlapTokens = 50

    static func passages(of pages: [DocumentPage]) -> [Passage] {
        let window = TokenEstimate.words(fitting: targetTokens)
        let overlap = TokenEstimate.words(fitting: overlapTokens)
        var passages: [Passage] = []
        for page in pages {
            let words = page.text.split(whereSeparator: \.isWhitespace)
            var start = 0
            while start < words.count {
                let end = min(start + window, words.count)
                passages.append(Passage(text: words[start..<end].joined(separator: " "), page: page.number))
                if end == words.count { break }
                start = end - overlap
            }
        }
        return passages
    }
}

/// How the text of a document goes to the AI for its metadata.
enum MetadataPlan: Equatable {
    /// The whole text, in one prompt.
    case whole(String)
    /// The text in sections: each is summarized, then the summaries go to the metadata prompt.
    case sections([Section])
}

/// A part of a long document, with the pages it covers.
struct Section: Equatable {
    var text: String
    var firstPage: Int
    var lastPage: Int
}

/// Plans the prompts for the metadata. The whole text goes in one prompt when it fits in half
/// the context window; otherwise it is cut in sections of at most that size.
///
/// The half is the share the document may take: the rest holds the instructions and the answer.
enum MetadataPlanner {
    static let textShare = 0.5
    /// Tokens kept free in a section for its page marker and the separators.
    private static let markerReserve = 16

    static func plan(pages: [DocumentPage], contextWindowTokens: Int) -> MetadataPlan {
        let limit = max(1, Int(Double(contextWindowTokens) * textShare))
        let whole = pages.map { block(number: $0.number, text: $0.text) }.joined(separator: "\n\n")
        if TokenEstimate.tokens(whole) <= limit {
            return .whole(whole)
        }
        return .sections(sections(of: pages, limit: limit))
    }

    private static func sections(of pages: [DocumentPage], limit: Int) -> [Section] {
        let piece = TokenEstimate.words(fitting: max(1, limit - markerReserve))
        var sections: [Section] = []
        var text = ""
        var tokens = 0
        var first = 0
        var last = 0
        for page in pages {
            let words = page.text.split(whereSeparator: \.isWhitespace)
            // A page longer than one section is cut in pieces of words; each piece is a block.
            for start in stride(from: 0, to: words.count, by: piece) {
                let end = min(start + piece, words.count)
                let blockText = block(number: page.number, text: words[start..<end].joined(separator: " "))
                let blockTokens = TokenEstimate.tokens(blockText)
                if !text.isEmpty && tokens + blockTokens > limit {
                    sections.append(Section(text: text, firstPage: first, lastPage: last))
                    text = ""
                    tokens = 0
                }
                if text.isEmpty { first = page.number }
                text += text.isEmpty ? blockText : "\n\n" + blockText
                tokens += blockTokens
                last = page.number
            }
        }
        if !text.isEmpty {
            sections.append(Section(text: text, firstPage: first, lastPage: last))
        }
        return sections
    }

    private static func block(number: Int, text: String) -> String {
        "--- Page \(number) ---\n\(text)"
    }
}
