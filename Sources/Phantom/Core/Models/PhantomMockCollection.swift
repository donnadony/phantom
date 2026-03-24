import Foundation

public struct PhantomMockCollection: Codable {
    public let name: String
    public let description: String
    public let rules: [PhantomMockRule]

    public init(name: String, description: String = "", rules: [PhantomMockRule]) {
        self.name = name
        self.description = description
        self.rules = rules
    }
}
