import Foundation

public struct PhantomLogItem: Identifiable {
    public let id = UUID()
    public let level: PhantomLogLevel
    public let message: String
    public let tag: String?
    public let createdAt = Date()
}
