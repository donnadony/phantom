import Foundation
import Combine

final class PhantomConfigViewModel: ObservableObject {

    private let config = PhantomConfig.shared
    private var cancellables = Set<AnyCancellable>()

    var entries: [PhantomConfigEntry] {
        config.entries
    }

    var hasEntries: Bool {
        !config.entries.isEmpty
    }

    init() {
        config.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func effectiveValue(for key: String, defaultValue: String) -> String {
        config.effectiveValue(for: key) ?? defaultValue
    }

    func value(for key: String) -> String? {
        config.value(for: key)
    }

    func isOverridden(_ key: String) -> Bool {
        config.value(for: key) != nil
    }

    func setValue(_ value: String, for key: String) {
        config.setValue(value, for: key)
    }

    func resetValue(for key: String) {
        config.resetValue(for: key)
    }

    func resetAll() {
        config.resetAll()
    }

    func toggleValue(for key: String) -> Bool {
        (config.effectiveValue(for: key) ?? "false") == "true"
    }

    func setToggle(_ isOn: Bool, for key: String) {
        config.setValue(isOn ? "true" : "false", for: key)
    }
}
