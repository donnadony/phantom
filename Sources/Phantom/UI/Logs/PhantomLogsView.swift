import SwiftUI

struct PhantomLogsView: View {

    @Environment(\.phantomTheme) private var theme
    @ObservedObject private var logger = PhantomLogger.shared
    @State private var searchText: String = ""
    @State private var selectedLevel: PhantomLogLevel? = nil

    private var filteredEvents: [PhantomLogItem] {
        var list = logger.events
        if let level = selectedLevel {
            list = list.filter { $0.level == level }
        }
        guard !searchText.isEmpty else { return list }
        return list.filter { item in
            let msg = item.message.lowercased()
            let tag = (item.tag ?? "").lowercased()
            let query = searchText.lowercased()
            return msg.contains(query) || tag.contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar()
            filterBar()
            if filteredEvents.isEmpty {
                Spacer()
                Text("No events yet.")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.onBackgroundVariant)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredEvents) { item in
                            logEventRow(item)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }
            }
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("Logs (\(logger.events.count))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { PhantomLogger.shared.clearAll() }) {
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
            TextField("Search by message or tag...", text: $searchText)
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
        Button(action: { selectedLevel = level }) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(selectedLevel == level ? theme.onPrimary : theme.onBackground)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedLevel == level ? theme.primary : theme.surface)
                )
        }
    }

    private func logEventRow(_ item: PhantomLogItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(item.level.emoji)
                .font(.system(size: 14))
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.level.rawValue)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(levelColor(item.level))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(levelColor(item.level).opacity(0.15))
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
                Text(timeText(item.createdAt))
                    .font(.system(size: 12))
                    .foregroundStyle(theme.onBackgroundVariant)
            }
            Spacer()
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(levelColor(item.level).opacity(0.3), lineWidth: 1))
    }

    private func levelColor(_ level: PhantomLogLevel) -> Color {
        switch level {
        case .info: return theme.info
        case .warning: return theme.warning
        case .error: return theme.error
        }
    }

    private func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
