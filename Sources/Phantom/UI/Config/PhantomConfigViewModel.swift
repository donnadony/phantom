import Foundation
import Combine

final class PhantomConfigViewModel: ObservableObject {

    @Published var selectedGroup: String?

    private let config = PhantomConfig.shared
    private var cancellables = Set<AnyCancellable>()

    var entries: [PhantomConfigEntry] {
        config.entries
    }

    var hasEntries: Bool {
        !config.entries.isEmpty
    }

    var groups: [String] {
        config.groups
    }

    var hasMultipleGroups: Bool {
        config.groups.count > 1
    }

    var filteredEntries: [PhantomConfigEntry] {
        guard let selectedGroup else { return config.entries }
        return config.entries(for: selectedGroup)
    }

    var groupedEntries: [(group: String, entries: [PhantomConfigEntry])] {
        let entriesToShow = filteredEntries
        let groupOrder = groups
        var result: [(group: String, entries: [PhantomConfigEntry])] = []
        for group in groupOrder {
            let groupEntries = entriesToShow.filter { $0.group == group }
            guard !groupEntries.isEmpty else { continue }
            result.append((group: group, entries: groupEntries))
        }
        return result
    }

    init() {
        config.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func initializeGroupSelection() {
        guard selectedGroup == nil, hasMultipleGroups else { return }
        selectedGroup = groups.first
    }

    func selectGroup(_ group: String?) {
        selectedGroup = group
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
