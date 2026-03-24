import SwiftUI

struct PhantomNetworkView: View {

    @Environment(\.phantomTheme) private var theme
    @StateObject private var viewModel = PhantomNetworkViewModel()

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isResponseExpanded {
                detailOnlyView
            } else {
                searchView
                filterView
                contentView
            }
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("Network (\(viewModel.totalCount))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.clearAll() }) {
                    Text("Clear")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.error)
                }
            }
        }
        .onAppear { viewModel.initializeSelection() }
        .onChange(of: viewModel.filteredLogIDs) { ids in
            viewModel.updateSelectionIfNeeded(ids: ids)
        }
        .sheet(item: $viewModel.mockRuleToCreate) { rule in
            PhantomMockEditView(existingRule: rule, onSave: { viewModel.handleMockCreated($0) })
                .environment(\.phantomTheme, theme)
        }
        .sheet(item: $viewModel.mockRuleToEdit) { rule in
            PhantomMockEditView(existingRule: rule, onSave: { viewModel.handleMockUpdated($0) })
                .environment(\.phantomTheme, theme)
        }
    }

    private var searchView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.onBackgroundVariant)
            TextField("Filter by endpoint, body or headers", text: $viewModel.searchText)
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
            ForEach(PhantomNetworkViewModel.FilterType.allCases) { filter in
                Button(action: { viewModel.selectedFilter = filter }) {
                    Text(filter.rawValue)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(viewModel.selectedFilter == filter ? theme.onPrimary : theme.onBackground)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(viewModel.selectedFilter == filter ? theme.primary : theme.surface)
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
                    ForEach(viewModel.filteredLogs) { item in
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
        let isSelected = item.id == viewModel.selectedLogID
        return Button(action: { viewModel.selectLog(item.id) }) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(viewModel.statusColor(item, theme: theme))
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(item.methodType)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(theme.onBackground)
                        statusBadge(for: item)
                        if viewModel.isMockLog(item) {
                            Text("MOCK")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(theme.onPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(RoundedRectangle(cornerRadius: 8).fill(theme.warning))
                        }
                    }
                    Text(viewModel.pathText(for: item))
                        .font(.system(size: 12))
                        .foregroundStyle(theme.onBackgroundVariant)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Text(viewModel.timeText(item.createdAt))
                            .font(.system(size: 12))
                            .foregroundStyle(theme.onBackgroundVariant)
                        if let duration = item.durationMs {
                            Text("\(duration)ms")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(duration > 1000 ? theme.error : theme.onBackgroundVariant)
                        }
                        if item.responseSizeBytes > 0 {
                            Text(viewModel.formattedBytes(item.responseSizeBytes))
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
            if let item = viewModel.selectedLog {
                Picker("", selection: $viewModel.detailTab) {
                    ForEach(PhantomNetworkViewModel.DetailTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                VStack(alignment: .leading, spacing: 6) {
                    if viewModel.detailTab == .response {
                        HStack {
                            HStack(spacing: 0) {
                                Button(action: { viewModel.showJsonTree = true }) {
                                    Text("Viewer")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(viewModel.showJsonTree ? theme.onBackground : theme.onBackgroundVariant)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(viewModel.showJsonTree ? theme.surfaceVariant : .clear)
                                        )
                                }
                                Button(action: { viewModel.showJsonTree = false }) {
                                    Text("Text")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(!viewModel.showJsonTree ? theme.onBackground : theme.onBackgroundVariant)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(!viewModel.showJsonTree ? theme.surfaceVariant : .clear)
                                        )
                                }
                            }
                            .background(RoundedRectangle(cornerRadius: 6).fill(theme.surface))
                            Spacer()
                            Button(action: { viewModel.toggleResponseExpand() }) {
                                Text(viewModel.isResponseExpanded ? "Collapse" : "Expand")
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
                        if viewModel.detailTab == .response && viewModel.showJsonTree {
                            PhantomJsonTreeView(jsonString: item.responseBody)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(viewModel.detailText(for: item))
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundStyle(theme.onBackground)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(height: expandedContentHeight ?? viewModel.responseDetailCurrentHeight)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(theme.surface))
                HStack {
                    Spacer()
                    if viewModel.isMockLog(item) {
                        Button(action: { viewModel.mockRuleToEdit = viewModel.findMockRule(for: item) }) {
                            Text("Edit Mock")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(theme.onPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(theme.warning))
                        }
                    } else {
                        Button(action: { viewModel.createMockFromItem(item) }) {
                            Text("Mock this")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(theme.onPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(theme.info))
                        }
                        Button(action: { viewModel.copyCurl(for: item) }) {
                            Text("Copy cURL")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(theme.onPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(theme.error))
                        }
                    }
                }
                if let copiedMessage = viewModel.copiedMessage {
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

    @ViewBuilder
    private func statusBadge(for item: PhantomNetworkItem) -> some View {
        if let status = item.statusCode {
            Text("\(status)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(viewModel.statusTextColor(for: status, theme: theme))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 8).fill(viewModel.statusBackgroundColor(for: status, theme: theme)))
        } else {
            Text(item.completedAt == nil ? "PENDING" : "DONE")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(theme.onBackgroundVariant)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 8).fill(theme.surface))
        }
    }
}
