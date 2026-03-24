import SwiftUI

struct PhantomNetworkView: View {

    @Environment(\.phantomTheme) private var theme
    @ObservedObject private var networkLogger = PhantomNetworkLogger.shared
    @State private var searchText: String = ""
    @State private var selectedLogID: PhantomNetworkItem.ID?
    @State private var detailTab: DetailTab = .response
    @State private var copiedMessage: String?
    @State private var selectedFilter: FilterType = .all
    @State private var responseDetailHeight: CGFloat = 220
    @State private var showJsonTree: Bool = true
    @State private var mockRuleToCreate: PhantomMockRule?
    @State private var mockRuleToEdit: PhantomMockRule?

    private enum DetailTab: String, CaseIterable, Identifiable {
        case request = "Request"
        case response = "Response"
        case headers = "Headers"
        var id: String { rawValue }
    }

    private enum FilterType: String, CaseIterable, Identifiable {
        case all = "All"
        case errors = "Errors"
        case slow = "Slow >1s"
        var id: String { rawValue }
    }

    private var filteredLogs: [PhantomNetworkItem] {
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
        return list.filter { item in
            let url = item.url?.absoluteString.lowercased() ?? ""
            let request = item.requestBody.lowercased()
            let response = item.responseBody.lowercased()
            let headers = "\(item.requestHeaders)\n\(item.responseHeaders)".lowercased()
            let query = searchText.lowercased()
            return url.contains(query) || request.contains(query) || response.contains(query) || headers.contains(query)
        }
    }

    private var selectedLog: PhantomNetworkItem? {
        if let selectedLogID {
            return filteredLogs.first(where: { $0.id == selectedLogID })
                ?? networkLogger.logs.first(where: { $0.id == selectedLogID })
        }
        return filteredLogs.first
    }

    private var responseDetailCurrentHeight: CGFloat {
        detailTab == .response ? responseDetailHeight : 220
    }

    private var isResponseExpanded: Bool {
        detailTab == .response && responseDetailHeight > 300
    }

    var body: some View {
        VStack(spacing: 0) {
            if isResponseExpanded {
                detailOnlyView
            } else {
                searchView
                filterView
                contentView
            }
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("Network (\(networkLogger.logs.count))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    PhantomNetworkLogger.shared.clearAll()
                    selectedLogID = nil
                }) {
                    Text("Clear")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.error)
                }
            }
        }
        .onAppear {
            responseDetailHeight = 220
            if selectedLogID == nil {
                selectedLogID = filteredLogs.first?.id
            }
        }
        .onChange(of: filteredLogs.map(\.id)) { ids in
            if ids.contains(where: { $0 == selectedLogID }) { return }
            selectedLogID = ids.first
        }
        .sheet(item: $mockRuleToCreate) { rule in
            PhantomMockEditView(existingRule: rule, onSave: { savedRule in
                PhantomMockInterceptor.shared.addRule(savedRule)
                mockRuleToCreate = nil
                copiedMessage = "Mock rule created"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copiedMessage = nil }
            })
            .environment(\.phantomTheme, theme)
        }
        .sheet(item: $mockRuleToEdit) { rule in
            PhantomMockEditView(existingRule: rule, onSave: { updatedRule in
                PhantomMockInterceptor.shared.updateRule(updatedRule)
                mockRuleToEdit = nil
            })
            .environment(\.phantomTheme, theme)
        }
    }

    private var searchView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.onBackgroundVariant)
            TextField("Filter by endpoint, body or headers", text: $searchText)
                .font(.system(size: 14))
                .foregroundStyle(theme.onBackground)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(theme.surface))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var filterView: some View {
        HStack(spacing: 8) {
            ForEach(FilterType.allCases) { filter in
                Button(action: { selectedFilter = filter }) {
                    Text(filter.rawValue)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(selectedFilter == filter ? theme.onPrimary : theme.onBackground)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedFilter == filter ? theme.primary : theme.surface)
                        )
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var contentView: some View {
        VStack(spacing: 12) {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredLogs) { item in
                        logRow(item)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
            Divider().background(theme.outlineVariant)
            detailView()
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
        }
    }

    private var detailOnlyView: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                detailView(expandedContentHeight: max(220, geometry.size.height - 170))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private func logRow(_ item: PhantomNetworkItem) -> some View {
        let isSelected = item.id == selectedLogID
        return Button(action: { selectedLogID = item.id }) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(statusColor(item))
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(item.methodType)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(theme.onBackground)
                        statusBadge(for: item)
                        if isMockLog(item) {
                            Text("MOCK")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(theme.onPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(RoundedRectangle(cornerRadius: 8).fill(theme.warning))
                        }
                    }
                    Text(pathText(for: item))
                        .font(.system(size: 12))
                        .foregroundStyle(theme.onBackgroundVariant)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Text(timeText(item.createdAt))
                            .font(.system(size: 12))
                            .foregroundStyle(theme.onBackgroundVariant)
                        if let duration = item.durationMs {
                            Text("\(duration)ms")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(duration > 1000 ? theme.error : theme.onBackgroundVariant)
                        }
                        if item.responseSizeBytes > 0 {
                            Text(formattedBytes(item.responseSizeBytes))
                                .font(.system(size: 12))
                                .foregroundStyle(theme.onBackgroundVariant)
                        }
                    }
                }
                Spacer()
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(isSelected ? theme.surfaceVariant : theme.surface))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? theme.primary : theme.outlineVariant, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func detailView(expandedContentHeight: CGFloat? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let item = selectedLog {
                Picker("", selection: $detailTab) {
                    ForEach(DetailTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                VStack(alignment: .leading, spacing: 6) {
                    if detailTab == .response {
                        HStack {
                            HStack(spacing: 0) {
                                Button(action: { showJsonTree = true }) {
                                    Text("Viewer")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(showJsonTree ? theme.onBackground : theme.onBackgroundVariant)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(showJsonTree ? theme.surfaceVariant : .clear)
                                        )
                                }
                                Button(action: { showJsonTree = false }) {
                                    Text("Text")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(!showJsonTree ? theme.onBackground : theme.onBackgroundVariant)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(!showJsonTree ? theme.surfaceVariant : .clear)
                                        )
                                }
                            }
                            .background(RoundedRectangle(cornerRadius: 6).fill(theme.surface))
                            Spacer()
                            Button(action: {
                                responseDetailHeight = responseDetailHeight > 300 ? 220 : 340
                            }) {
                                Text(responseDetailHeight > 300 ? "Collapse" : "Expand")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(theme.info)
                            }
                        }
                    }
                    Text(item.url?.absoluteString ?? "No URL")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.onBackground)
                        .fixedSize(horizontal: false, vertical: true)
                    ScrollView {
                        if detailTab == .response && showJsonTree {
                            PhantomJsonTreeView(jsonString: item.responseBody)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(detailText(for: item))
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundStyle(theme.onBackground)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(height: expandedContentHeight ?? responseDetailCurrentHeight)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(theme.surface))
                HStack {
                    Spacer()
                    if isMockLog(item) {
                        Button(action: { mockRuleToEdit = findMockRule(for: item) }) {
                            Text("Edit Mock")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(theme.onPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(theme.warning))
                        }
                    } else {
                        Button(action: { mockRuleToCreate = createMockRule(from: item) }) {
                            Text("Mock this")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(theme.onPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(theme.info))
                        }
                        Button(action: {
                            UIPasteboard.general.string = URLRequest(url: item.url ?? URL(string: "about:blank")!).phantomCURLCommand
                            copiedMessage = "cURL copied"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copiedMessage = nil }
                        }) {
                            Text("Copy cURL")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(theme.onPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(theme.error))
                        }
                    }
                }
                if let copiedMessage {
                    Text(copiedMessage)
                        .font(.system(size: 12))
                        .foregroundStyle(theme.onBackgroundVariant)
                }
            } else {
                Text("No network logs yet. Make a request to see it here.")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.onBackgroundVariant)
                    .padding(.vertical, 10)
            }
        }
    }

    private func detailText(for item: PhantomNetworkItem) -> String {
        switch detailTab {
        case .request:
            return item.requestBody.isEmpty ? "No body" : item.requestBody
        case .response:
            return item.responseBody.isEmpty ? "No response body" : item.responseBody
        case .headers:
            return "Request Headers:\n\(item.requestHeaders)\n\nResponse Headers:\n\(item.responseHeaders)"
        }
    }

    private func pathText(for item: PhantomNetworkItem) -> String {
        guard let url = item.url else { return "No URL" }
        return url.path.isEmpty ? (url.host ?? url.absoluteString) : url.path
    }

    private func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    private func formattedBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private func statusColor(_ item: PhantomNetworkItem) -> Color {
        guard let status = item.statusCode else {
            return item.completedAt == nil ? theme.error : theme.onBackgroundVariant
        }
        return (200..<300).contains(status) ? theme.success : theme.error
    }

    @ViewBuilder
    private func statusBadge(for item: PhantomNetworkItem) -> some View {
        if let status = item.statusCode {
            Text("\(status)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(statusTextColor(for: status))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 8).fill(statusBackgroundColor(for: status)))
        } else {
            Text(item.completedAt == nil ? "PENDING" : "DONE")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(theme.onBackgroundVariant)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 8).fill(theme.surface))
        }
    }

    private func statusBackgroundColor(for status: Int) -> Color {
        if (200..<300).contains(status) { return theme.success.opacity(0.18) }
        if (300..<500).contains(status) { return theme.warning.opacity(0.18) }
        return theme.error.opacity(0.16)
    }

    private func statusTextColor(for status: Int) -> Color {
        if (200..<300).contains(status) { return theme.success }
        if (300..<500).contains(status) { return theme.warning }
        return theme.error
    }

    private func isMockLog(_ item: PhantomNetworkItem) -> Bool {
        item.responseHeaders == "[MOCK]"
    }

    private func findMockRule(for item: PhantomNetworkItem) -> PhantomMockRule? {
        guard let path = item.url?.path else { return nil }
        return PhantomMockInterceptor.shared.rules.first { rule in
            guard rule.httpMethod == "ANY" || rule.httpMethod == item.methodType else { return false }
            return path.contains(rule.urlPattern)
        }
    }

    private func createMockRule(from item: PhantomNetworkItem) -> PhantomMockRule {
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
}
