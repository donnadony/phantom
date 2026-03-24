import Foundation
import SwiftUI
import Combine

final class PhantomMockListViewModel: ObservableObject {

    @Published var editingRule: PhantomMockRule?
    @Published var showAddSheet = false

    private let interceptor = PhantomMockInterceptor.shared
    private var cancellables = Set<AnyCancellable>()

    var rules: [PhantomMockRule] {
        interceptor.rules
    }

    var hasRules: Bool {
        !interceptor.rules.isEmpty
    }

    init() {
        interceptor.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func addRule(_ rule: PhantomMockRule) {
        interceptor.addRule(rule)
        showAddSheet = false
    }

    func updateRule(_ rule: PhantomMockRule) {
        interceptor.updateRule(rule)
        editingRule = nil
    }

    func deleteRule(at offsets: IndexSet) {
        offsets.forEach { interceptor.deleteRule(id: interceptor.rules[$0].id) }
    }

    func toggleRule(id: UUID) {
        interceptor.toggleRule(id: id)
    }

    func methodColor(_ method: String, theme: PhantomTheme) -> Color {
        switch method {
        case "GET": return theme.httpGet
        case "POST": return theme.httpPost
        case "PUT": return theme.httpPut
        case "DELETE": return theme.httpDelete
        default: return theme.onBackgroundVariant
        }
    }

    func statusColor(_ code: Int, theme: PhantomTheme) -> Color {
        if (200..<300).contains(code) { return theme.success }
        if (400..<500).contains(code) { return theme.warning }
        if code >= 500 { return theme.error }
        return theme.onBackgroundVariant
    }
}
