import Foundation

public enum PhantomLanguage: String, CaseIterable {
    case english = "en"
    case spanish = "es"

    public var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        }
    }
}

public struct PhantomLocalizationEntry: Identifiable {
    public let id: String
    public let key: String
    public let englishValue: String
    public let spanishValue: String
    public let group: String

    public init(
        key: String,
        english: String,
        spanish: String,
        group: String = "General"
    ) {
        self.id = "\(group)_\(key)"
        self.key = key
        self.englishValue = english
        self.spanishValue = spanish
        self.group = group
    }

    public func value(for language: PhantomLanguage) -> String {
        switch language {
        case .english: return englishValue
        case .spanish: return spanishValue
        }
    }
}
