import Foundation
import SwiftUI
import Combine

final class PhantomLogsViewModel: ObservableObject {

    @Published var searchText: String = ""
    @Published var selectedLevel: PhantomLogLevel?

    private let logger = PhantomLogger.shared
    private var cancellables = Set<AnyCancellable>()

    var totalCount: Int {
        logger.events.count
    }

    var filteredEvents: [PhantomLogItem] {
        var list = logger.events
        if let level = selectedLevel {
            list = list.filter { $0.level == level }
        }
        guard !searchText.isEmpty else { return list }
        let query = searchText.lowercased()
        return list.filter { item in
            item.message.lowercased().contains(query) ||
            (item.tag ?? "").lowercased().contains(query)
        }
    }

    init() {
        logger.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func clearAll() {
        logger.clearAll()
    }

    func selectLevel(_ level: PhantomLogLevel?) {
        selectedLevel = level
    }

    func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    func levelColor(_ level: PhantomLogLevel, theme: PhantomTheme) -> Color {
        switch level {
        case .info: return theme.info
        case .warning: return theme.warning
        case .error: return theme.error
        }
    }
}
