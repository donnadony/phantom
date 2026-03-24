import Foundation
import SwiftUI
import Combine

final class PhantomMockListViewModel: ObservableObject {

    @Published var editingRule: PhantomMockRule?
    @Published var showAddSheet = false
    @Published var showImportPicker = false
    @Published var showExportShare = false
    @Published var exportData: Data?
    @Published var toastMessage: String?

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

    func importMocks(from url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        if interceptor.loadMocks(from: url) {
            showToast("\(interceptor.rules.count) rules loaded")
        } else {
            showToast("Invalid mock file")
        }
    }

    func exportMocks() {
        exportData = interceptor.exportCollection()
        if exportData != nil {
            showExportShare = true
        }
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

    private func showToast(_ message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.toastMessage = nil
        }
    }
}
