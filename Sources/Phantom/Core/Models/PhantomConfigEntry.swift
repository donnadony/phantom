import Foundation

public enum PhantomConfigType: String, Codable {
    case text
    case toggle
    case picker
}

public struct PhantomConfigEntry: Identifiable {
    public let id: String
    public let label: String
    public let key: String
    public let defaultValue: String
    public let type: PhantomConfigType
    public let options: [String]
    public let group: String

    public init(
        label: String,
        key: String,
        defaultValue: String,
        type: PhantomConfigType = .text,
        options: [String] = [],
        group: String = "General"
    ) {
        self.id = key
        self.label = label
        self.key = key
        self.defaultValue = defaultValue
        self.type = type
        self.options = options
        self.group = group
    }
}
