import Foundation
import Combine

public final class PhantomLocalizer: ObservableObject {

    public static let shared = PhantomLocalizer()

    @Published public private(set) var entries: [PhantomLocalizationEntry] = []
    @Published public private(set) var currentLanguage: PhantomLanguage = .english

    private let languageKey = "phantom_language"

    private init() {
        if let saved = UserDefaults.standard.string(forKey: languageKey),
           let language = PhantomLanguage(rawValue: saved) {
            currentLanguage = language
        }
    }

    // MARK: - Registration

    public func register(
        key: String,
        english: String,
        spanish: String,
        group: String = "General"
    ) {
        let compositeId = "\(group)_\(key)"
        guard !entries.contains(where: { $0.id == compositeId }) else { return }
        let entry = PhantomLocalizationEntry(
            key: key,
            english: english,
            spanish: spanish,
            group: group
        )
        entries.append(entry)
    }

    // MARK: - Language

    public func setLanguage(_ language: PhantomLanguage) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: languageKey)
    }

    // MARK: - Lookup

    public func localized(_ key: String, group: String? = nil) -> String {
        let match: PhantomLocalizationEntry?
        if let group {
            match = entries.first(where: { $0.key == key && $0.group == group })
        } else {
            match = entries.first(where: { $0.key == key })
        }
        return match?.value(for: currentLanguage) ?? key
    }

    // MARK: - Groups

    public var groups: [String] {
        Array(Set(entries.map(\.group))).sorted()
    }

    public func entries(for group: String) -> [PhantomLocalizationEntry] {
        entries.filter { $0.group == group }
    }

    // MARK: - Reset

    public func removeAll() {
        entries.removeAll()
    }
}
