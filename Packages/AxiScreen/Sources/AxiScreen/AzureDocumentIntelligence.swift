import CoreGraphics
import Foundation
import ImageIO

/// The endpoint and key the user configured for Azure AI Document Intelligence.
public struct AzureDocumentIntelligenceConfiguration: Sendable, Equatable {
    public var endpoint: URL
    public var apiKey: String

    public init(endpoint: URL, apiKey: String) {
        self.endpoint = endpoint
        self.apiKey = apiKey
    }
}

public enum AzureDocumentIntelligenceError: Error, Equatable {
    case invalidEndpoint
    case invalidResponse
    case httpStatus(Int)
    case analysisFailed
    case timedOut
}

/// Sends a request and returns the body with the HTTP response. Replaced by a fake in tests.
public protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionTransport: HTTPTransport {
    public init() {}

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AzureDocumentIntelligenceError.invalidResponse }
        return (data, http)
    }
}

/// Client of the `prebuilt-read` model of Azure AI Document Intelligence.
/// Shared by the text extraction of the archive and by screen recognition.
public struct AzureDocumentIntelligenceClient: Sendable {
    public static let modelIdentifier = "prebuilt-read"
    public static let apiVersion = "2024-11-30"

    private let configuration: AzureDocumentIntelligenceConfiguration
    private let transport: any HTTPTransport
    private let pollInterval: Duration
    private let maxPolls: Int

    public init(
        configuration: AzureDocumentIntelligenceConfiguration,
        transport: any HTTPTransport = URLSessionTransport(),
        pollInterval: Duration = .seconds(1),
        maxPolls: Int = 120
    ) {
        self.configuration = configuration
        self.transport = transport
        self.pollInterval = pollInterval
        self.maxPolls = maxPolls
    }

    /// Checks that the endpoint and the key work, by sending an empty PNG to the model.
    /// Throws when the connection or the key fails.
    public static func checkConnection(configuration: AzureDocumentIntelligenceConfiguration) async throws {
        let client = AzureDocumentIntelligenceClient(configuration: configuration)
        _ = try await client.submit(data: blankPNG, contentType: "image/png")
    }

    /// Extracts the text of a document (PDF, image or Office file) and returns it in reading order.
    public func extractText(from data: Data, contentType: String) async throws -> String {
        let operation = try await submit(data: data, contentType: contentType)
        return try await waitForResult(at: operation)
    }

    private func submit(data: Data, contentType: String) async throws -> URL {
        var request = URLRequest(url: try analyzeURL())
        request.httpMethod = "POST"
        request.setValue(configuration.apiKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        let (_, response) = try await transport.send(request)
        guard response.statusCode == 202 else {
            throw AzureDocumentIntelligenceError.httpStatus(response.statusCode)
        }
        guard let location = response.value(forHTTPHeaderField: "Operation-Location"),
              let url = URL(string: location) else {
            throw AzureDocumentIntelligenceError.invalidResponse
        }
        return url
    }

    private func waitForResult(at operation: URL) async throws -> String {
        for _ in 0..<maxPolls {
            try await Task.sleep(for: pollInterval)
            var request = URLRequest(url: operation)
            request.setValue(configuration.apiKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
            let (data, response) = try await transport.send(request)
            guard response.statusCode == 200 else {
                throw AzureDocumentIntelligenceError.httpStatus(response.statusCode)
            }
            let result = try JSONDecoder().decode(AnalyzeOperation.self, from: data)
            switch result.status {
            case "succeeded":
                return result.analyzeResult?.content ?? ""
            case "failed":
                throw AzureDocumentIntelligenceError.analysisFailed
            default:
                continue
            }
        }
        throw AzureDocumentIntelligenceError.timedOut
    }

    private func analyzeURL() throws -> URL {
        guard var components = URLComponents(url: configuration.endpoint, resolvingAgainstBaseURL: false),
              components.scheme == "https" || components.scheme == "http",
              components.host != nil else {
            throw AzureDocumentIntelligenceError.invalidEndpoint
        }
        let base = components.path.hasSuffix("/") ? String(components.path.dropLast()) : components.path
        components.path = base + "/documentintelligence/documentModels/\(Self.modelIdentifier):analyze"
        components.queryItems = [URLQueryItem(name: "api-version", value: Self.apiVersion)]
        guard let url = components.url else { throw AzureDocumentIntelligenceError.invalidEndpoint }
        return url
    }

    private struct AnalyzeOperation: Decodable {
        var status: String
        var analyzeResult: AnalyzeResult?

        struct AnalyzeResult: Decodable {
            var content: String?
        }
    }

    /// A 1x1 white PNG, used only to test the connection.
    private static let blankPNG = Data(base64Encoded:
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==")!
}

/// Text recognition with Azure, for images of a window.
public struct AzureTextRecognizer: TextRecognizing {
    public let source = TextSource.azure
    private let client: AzureDocumentIntelligenceClient

    public init(client: AzureDocumentIntelligenceClient) {
        self.client = client
    }

    public func recognizeText(in image: CGImage) async throws -> String {
        try await client.extractText(from: try PNGEncoder.encode(image), contentType: "image/png")
    }
}

/// Encodes a captured image as PNG.
enum PNGEncoder {
    static func encode(_ image: CGImage) throws -> Data {
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, "public.png" as CFString, 1, nil) else {
            throw AzureDocumentIntelligenceError.invalidResponse
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw AzureDocumentIntelligenceError.invalidResponse
        }
        return output as Data
    }
}
