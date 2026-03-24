import SwiftUI

struct PhantomLogsView: View {

    @Environment(\.phantomTheme) private var theme
    @StateObject private var viewModel = PhantomLogsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            searchBar()
            filterBar()
            if viewModel.filteredEvents.isEmpty {
                Spacer()
                Text("No events yet.")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.onBackgroundVariant)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.filteredEvents) { item in
                            logEventRow(item)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }
            }
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("Logs (\(viewModel.totalCount))")
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
    }

    @ViewBuilder
    private func searchBar() -> some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.onBackgroundVariant)
            TextField("Search by message or tag...", text: $viewModel.searchText)
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

    @ViewBuilder
    private func filterBar() -> some View {
        HStack(spacing: 8) {
            filterButton(nil, label: "All")
            ForEach(PhantomLogLevel.allCases, id: \.self) { level in
                filterButton(level, label: level.rawValue)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func filterButton(_ level: PhantomLogLevel?, label: String) -> some View {
        Button(action: { viewModel.selectLevel(level) }) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(viewModel.selectedLevel == level ? theme.onPrimary : theme.onBackground)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(viewModel.selectedLevel == level ? theme.primary : theme.surface)
                )
        }
    }

    private func logEventRow(_ item: PhantomLogItem) -> some View {
        let color = viewModel.levelColor(item.level, theme: theme)
        return HStack(alignment: .top, spacing: 10) {
            Text(item.level.emoji)
                .font(.system(size: 14))
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.level.rawValue)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(color.opacity(0.15))
                        )
                    if let tag = item.tag {
                        Text(tag)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(theme.onBackgroundVariant)
                    }
                }
                Text(item.message)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.onBackground)
                Text(viewModel.timeText(item.createdAt))
                    .font(.system(size: 12))
                    .foregroundStyle(theme.onBackgroundVariant)
            }
            Spacer()
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.3), lineWidth: 1))
    }
}
