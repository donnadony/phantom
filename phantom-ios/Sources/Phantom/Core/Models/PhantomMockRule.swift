import Foundation

public struct PhantomMockResponse: Codable, Identifiable {
    public let id: UUID
    public var name: String
    public var statusCode: Int
    public var responseBody: String

    public init(id: UUID = UUID(), name: String, statusCode: Int, responseBody: String) {
        self.id = id
        self.name = name
        self.statusCode = statusCode
        self.responseBody = responseBody
    }
}

public struct PhantomMockRule: Codable, Identifiable {

    public let id: UUID
    public var isEnabled: Bool
    public var urlPattern: String
    public var httpMethod: String
    public var responses: [PhantomMockResponse]
    public var activeResponseId: UUID?
    public var ruleDescription: String
    public var createdAt: Date

    public var activeResponse: PhantomMockResponse? {
        guard let activeId = activeResponseId else { return responses.first }
        return responses.first { $0.id == activeId } ?? responses.first
    }

    public init(
        id: UUID = UUID(),
        isEnabled: Bool = true,
        urlPattern: String,
        httpMethod: String = "ANY",
        responses: [PhantomMockResponse],
        activeResponseId: UUID? = nil,
        ruleDescription: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.isEnabled = isEnabled
        self.urlPattern = urlPattern
        self.httpMethod = httpMethod
        self.responses = responses
        self.activeResponseId = activeResponseId
        self.ruleDescription = ruleDescription
        self.createdAt = createdAt
    }
}
