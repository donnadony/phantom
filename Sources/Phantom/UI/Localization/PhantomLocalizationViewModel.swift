import Foundation
import Combine

final class PhantomLocalizationViewModel: ObservableObject {

    @Published var selectedGroup: String?
    @Published var searchText: String = ""

    private let localizer = PhantomLocalizer.shared
    private var cancellables = Set<AnyCancellable>()

    var entries: [PhantomLocalizationEntry] {
        localizer.entries
    }

    var hasEntries: Bool {
        !localizer.entries.isEmpty
    }

    var groups: [String] {
        localizer.groups
    }

    var hasMultipleGroups: Bool {
        localizer.groups.count > 1
    }

    var currentLanguage: PhantomLanguage {
        localizer.currentLanguage
    }

    var filteredEntries: [PhantomLocalizationEntry] {
        var result = localizer.entries
        if let selectedGroup {
            result = result.filter { $0.group == selectedGroup }
        }
        guard !searchText.isEmpty else { return result }
        let query = searchText.lowercased()
        return result.filter {
            $0.key.lowercased().contains(query) ||
            $0.englishValue.lowercased().contains(query) ||
            $0.spanishValue.lowercased().contains(query)
        }
    }

    var showGroupBadge: Bool {
        hasMultipleGroups && selectedGroup == nil
    }

    init() {
        localizer.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func selectGroup(_ group: String?) {
        selectedGroup = group
    }

    func setLanguage(_ language: PhantomLanguage) {
        localizer.setLanguage(language)
    }

    func initializeGroupSelection() {
        guard selectedGroup == nil, hasMultipleGroups else { return }
        selectedGroup = groups.first
    }
}
