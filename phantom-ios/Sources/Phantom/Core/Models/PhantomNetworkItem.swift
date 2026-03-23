import Foundation

public struct PhantomNetworkItem: Identifiable {

    public let id: UUID
    public var url: URL?
    public var methodType: String
    public var requestHeaders: String
    public var requestBody: String
    public var responseHeaders: String
    public var responseBody: String
    public var responseSizeBytes: Int
    public var statusCode: Int?
    public var createdAt: Date
    public var completedAt: Date?
    public var durationMs: Int?

    public init(
        id: UUID = UUID(),
        url: URL?,
        methodType: String,
        requestHeaders: String,
        requestBody: String,
        responseHeaders: String = "No headers",
        responseBody: String = "",
        responseSizeBytes: Int = 0,
        statusCode: Int? = nil,
        completedAt: Date? = nil,
        durationMs: Int? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.url = url
        self.methodType = methodType
        self.requestHeaders = requestHeaders
        self.requestBody = requestBody
        self.responseHeaders = responseHeaders
        self.responseBody = responseBody
        self.responseSizeBytes = responseSizeBytes
        self.statusCode = statusCode
        self.completedAt = completedAt
        self.durationMs = durationMs
        self.createdAt = createdAt
    }
}
