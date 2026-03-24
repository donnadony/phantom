import Foundation
import SwiftUI
import Combine

final class PhantomNetworkViewModel: ObservableObject {

    enum DetailTab: String, CaseIterable, Identifiable {
        case request = "Request"
        case response = "Response"
        case headers = "Headers"
        var id: String { rawValue }
    }

    enum FilterType: String, CaseIterable, Identifiable {
        case all = "All"
        case errors = "Errors"
        case slow = "Slow >1s"
        var id: String { rawValue }
    }

    @Published var searchText: String = ""
    @Published var selectedLogID: PhantomNetworkItem.ID?
    @Published var detailTab: DetailTab = .response
    @Published var copiedMessage: String?
    @Published var selectedFilter: FilterType = .all
    @Published var responseDetailHeight: CGFloat = 220
    @Published var showJsonTree: Bool = true
    @Published var mockRuleToCreate: PhantomMockRule?
    @Published var mockRuleToEdit: PhantomMockRule?

    private let networkLogger = PhantomNetworkLogger.shared
    private var cancellables = Set<AnyCancellable>()

    var totalCount: Int {
        networkLogger.logs.count
    }

    var filteredLogs: [PhantomNetworkItem] {
        var list = Array(networkLogger.logs.reversed())
        switch selectedFilter {
        case .all:
            break
        case .errors:
            list = list.filter { ($0.statusCode ?? 0) >= 400 }
        case .slow:
            list = list.filter { ($0.durationMs ?? 0) > 1000 }
        }
        guard !searchText.isEmpty else { return list }
        let query = searchText.lowercased()
        return list.filter { item in
            let url = item.url?.absoluteString.lowercased() ?? ""
            let request = item.requestBody.lowercased()
            let response = item.responseBody.lowercased()
            let headers = "\(item.requestHeaders)\n\(item.responseHeaders)".lowercased()
            return url.contains(query) || request.contains(query) || response.contains(query) || headers.contains(query)
        }
    }

    var selectedLog: PhantomNetworkItem? {
        if let selectedLogID {
            return filteredLogs.first(where: { $0.id == selectedLogID })
                ?? networkLogger.logs.first(where: { $0.id == selectedLogID })
        }
        return filteredLogs.first
    }

    var responseDetailCurrentHeight: CGFloat {
        detailTab == .response ? responseDetailHeight : 220
    }

    var isResponseExpanded: Bool {
        detailTab == .response && responseDetailHeight > 300
    }

    var filteredLogIDs: [PhantomNetworkItem.ID] {
        filteredLogs.map(\.id)
    }

    init() {
        networkLogger.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func clearAll() {
        networkLogger.clearAll()
        selectedLogID = nil
    }

    func selectLog(_ id: PhantomNetworkItem.ID) {
        selectedLogID = id
    }

    func initializeSelection() {
        responseDetailHeight = 220
        if selectedLogID == nil {
            selectedLogID = filteredLogs.first?.id
        }
    }

    func updateSelectionIfNeeded(ids: [PhantomNetworkItem.ID]) {
        guard !ids.contains(where: { $0 == selectedLogID }) else { return }
        selectedLogID = ids.first
    }

    func toggleResponseExpand() {
        responseDetailHeight = responseDetailHeight > 300 ? 220 : 340
    }

    func copyCurl(for item: PhantomNetworkItem) {
        UIPasteboard.general.string = URLRequest(url: item.url ?? URL(string: "about:blank")!).phantomCURLCommand
        showCopiedMessage("cURL copied")
    }

    func createMockFromItem(_ item: PhantomNetworkItem) {
        mockRuleToCreate = buildMockRule(from: item)
    }

    func handleMockCreated(_ rule: PhantomMockRule) {
        PhantomMockInterceptor.shared.addRule(rule)
        mockRuleToCreate = nil
        showCopiedMessage("Mock rule created")
    }

    func handleMockUpdated(_ rule: PhantomMockRule) {
        PhantomMockInterceptor.shared.updateRule(rule)
        mockRuleToEdit = nil
    }

    func findMockRule(for item: PhantomNetworkItem) -> PhantomMockRule? {
        guard let path = item.url?.path else { return nil }
        return PhantomMockInterceptor.shared.rules.first { rule in
            guard rule.httpMethod == "ANY" || rule.httpMethod == item.methodType else { return false }
            return path.contains(rule.urlPattern)
        }
    }

    func isMockLog(_ item: PhantomNetworkItem) -> Bool {
        item.responseHeaders == "[MOCK]"
    }

    func detailText(for item: PhantomNetworkItem) -> String {
        switch detailTab {
        case .request:
            return item.requestBody.isEmpty ? "No body" : item.requestBody
        case .response:
            return item.responseBody.isEmpty ? "No response body" : item.responseBody
        case .headers:
            return "Request Headers:\n\(item.requestHeaders)\n\nResponse Headers:\n\(item.responseHeaders)"
        }
    }

    func pathText(for item: PhantomNetworkItem) -> String {
        guard let url = item.url else { return "No URL" }
        return url.path.isEmpty ? (url.host ?? url.absoluteString) : url.path
    }

    func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    func formattedBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    func statusColor(_ item: PhantomNetworkItem, theme: PhantomTheme) -> Color {
        guard let status = item.statusCode else {
            return item.completedAt == nil ? theme.error : theme.onBackgroundVariant
        }
        return (200..<300).contains(status) ? theme.success : theme.error
    }

    func statusBackgroundColor(for status: Int, theme: PhantomTheme) -> Color {
        if (200..<300).contains(status) { return theme.success.opacity(0.18) }
        if (300..<500).contains(status) { return theme.warning.opacity(0.18) }
        return theme.error.opacity(0.16)
    }

    func statusTextColor(for status: Int, theme: PhantomTheme) -> Color {
        if (200..<300).contains(status) { return theme.success }
        if (300..<500).contains(status) { return theme.warning }
        return theme.error
    }

    private func buildMockRule(from item: PhantomNetworkItem) -> PhantomMockRule {
        let path = item.url?.path ?? ""
        let responseId = UUID()
        let response = PhantomMockResponse(
            id: responseId,
            name: "Response 1",
            statusCode: item.statusCode ?? 200,
            responseBody: item.responseBody
        )
        return PhantomMockRule(
            id: UUID(),
            isEnabled: true,
            urlPattern: path,
            httpMethod: item.methodType,
            responses: [response],
            activeResponseId: responseId,
            ruleDescription: "Mock \(path.split(separator: "/").last ?? "endpoint")",
            createdAt: Date()
        )
    }

    private func showCopiedMessage(_ message: String) {
        copiedMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.copiedMessage = nil
        }
    }
}
