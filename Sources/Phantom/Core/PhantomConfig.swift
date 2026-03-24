import Foundation
import Combine

public final class PhantomConfig: ObservableObject {

    // MARK: - Properties

    public static let shared = PhantomConfig()

    @Published public private(set) var entries: [PhantomConfigEntry] = []

    private let storagePrefix = "phantom_config_"

    // MARK: - Lifecycle

    private init() {}

    // MARK: - Registration

    public func register(
        _ label: String,
        key: String,
        defaultValue: String,
        type: PhantomConfigType = .text,
        options: [String] = []
    ) {
        guard !entries.contains(where: { $0.key == key }) else { return }
        let entry = PhantomConfigEntry(
            label: label,
            key: key,
            defaultValue: defaultValue,
            type: type,
            options: options
        )
        entries.append(entry)
    }

    // MARK: - Read / Write

    public func value(for key: String) -> String? {
        UserDefaults.standard.string(forKey: storagePrefix + key)
    }

    public func effectiveValue(for key: String) -> String? {
        if let override = value(for: key), !override.isEmpty {
            return override
        }
        return entries.first(where: { $0.key == key })?.defaultValue
    }

    public func setValue(_ value: String?, for key: String) {
        if let value, !value.isEmpty {
            UserDefaults.standard.set(value, forKey: storagePrefix + key)
        } else {
            UserDefaults.standard.removeObject(forKey: storagePrefix + key)
        }
        objectWillChange.send()
    }

    public func resetValue(for key: String) {
        UserDefaults.standard.removeObject(forKey: storagePrefix + key)
        objectWillChange.send()
    }

    public func resetAll() {
        for entry in entries {
            UserDefaults.standard.removeObject(forKey: storagePrefix + entry.key)
        }
        objectWillChange.send()
    }
}
