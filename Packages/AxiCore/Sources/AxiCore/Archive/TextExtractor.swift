import AppKit
import AxiScreen
import CoreGraphics
import Foundation
import PDFKit

/// Reads the text of a file, page by page. Scanned pages go through the text recognizer.
struct TextExtractor: Sendable {
    /// The file cannot be read at all: unknown format, locked or corrupt.
    /// Any other error (for example the recognizer failing) is thrown as is.
    enum Failure: Error, Equatable {
        case unreadable
    }

    let recognizer: any TextRecognizing

    /// Scale of the page image sent to the recognizer: about 144 dpi.
    private static let recognitionScale: CGFloat = 2

    static let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "heic", "heif", "tif", "tiff", "gif", "bmp", "webp"]
    private static let textExtensions: Set<String> = ["txt", "md", "markdown"]

    /// The kind of a file, from its extension.
    static func kind(of url: URL) -> DocumentKind {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "pdf": return .pdf
        case "doc", "docx", "rtf": return .word
        case "eml": return .email
        default: return imageExtensions.contains(ext) ? .image : .other
        }
    }

    /// The pages of a file. A file with no text gives pages with empty text; the caller decides.
    func pages(of url: URL) async throws -> [DocumentPage] {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "pdf":
            return try await pdfPages(of: url)
        case "doc", "docx", "rtf":
            return [DocumentPage(number: 1, text: try wordText(of: url, extension: ext))]
        case "eml":
            guard let data = try? Data(contentsOf: url), let email = EmlParser.parse(data) else {
                throw Failure.unreadable
            }
            return [DocumentPage(number: 1, text: email.body)]
        case _ where Self.imageExtensions.contains(ext):
            return try await imagePages(of: url)
        case _ where Self.textExtensions.contains(ext):
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { throw Failure.unreadable }
            return [DocumentPage(number: 1, text: text)]
        default:
            throw Failure.unreadable
        }
    }

    /// The text a PDF carries, without recognition. Empty when it carries none.
    static func nativeText(of url: URL) -> String {
        PDFDocument(url: url)?.string ?? ""
    }

    // MARK: PDF

    private func pdfPages(of url: URL) async throws -> [DocumentPage] {
        guard let document = PDFDocument(url: url), !document.isLocked else { throw Failure.unreadable }
        var pages: [DocumentPage] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            let native = page.string ?? ""
            let text: String
            if TokenEstimate.wordCount(native) > 0 {
                text = native
            } else if let image = Self.render(page) {
                text = try await recognizer.recognizeText(in: image)
            } else {
                text = ""
            }
            pages.append(DocumentPage(number: index + 1, text: text))
        }
        return pages
    }

    // MARK: Images

    /// Every frame of an image file (a multipage TIFF has one per page) is a page, recognized in order.
    private func imagePages(of url: URL) async throws -> [DocumentPage] {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { throw Failure.unreadable }
        let count = CGImageSourceGetCount(source)
        guard count > 0 else { throw Failure.unreadable }
        var pages: [DocumentPage] = []
        for index in 0..<count {
            guard let image = CGImageSourceCreateImageAtIndex(source, index, nil) else { throw Failure.unreadable }
            let text = try await recognizer.recognizeText(in: image)
            pages.append(DocumentPage(number: index + 1, text: text))
        }
        return pages
    }

    /// The page drawn on white, for recognition.
    private static func render(_ page: PDFPage) -> CGImage? {
        let box = page.bounds(for: .mediaBox)
        let width = Int((box.width * recognitionScale).rounded(.up))
        let height = Int((box.height * recognitionScale).rounded(.up))
        guard width > 0, height > 0,
              let context = CGContext(
                  data: nil,
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: CGColorSpaceCreateDeviceRGB(),
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              )
        else { return nil }
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.scaleBy(x: recognitionScale, y: recognitionScale)
        page.draw(with: .mediaBox, to: context)
        return context.makeImage()
    }

    // MARK: Word processing

    private func wordText(of url: URL, extension ext: String) throws -> String {
        let type: NSAttributedString.DocumentType
        switch ext {
        case "doc": type = .docFormat
        case "docx": type = .officeOpenXML
        default: type = .rtf
        }
        guard let text = try? NSAttributedString(
            url: url,
            options: [.documentType: type],
            documentAttributes: nil
        ).string else {
            throw Failure.unreadable
        }
        return text
    }
}
