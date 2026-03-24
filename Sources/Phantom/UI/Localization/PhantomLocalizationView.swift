import SwiftUI

struct PhantomLocalizationView: View {

    @Environment(\.phantomTheme) private var theme
    @StateObject private var viewModel = PhantomLocalizationViewModel()

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            if viewModel.hasEntries {
                localizationList()
            } else {
                emptyState()
            }
        }
        .navigationTitle("Localization")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                languagePicker()
            }
        }
        .onAppear { viewModel.initializeGroupSelection() }
    }

    @ViewBuilder
    private func emptyState() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .font(.system(size: 48))
                .foregroundStyle(theme.onBackgroundVariant)
            Text("No localization entries")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(theme.onBackground)
            Text("Use Phantom.registerLocalization() to add translatable strings.")
                .font(.system(size: 14))
                .foregroundStyle(theme.onBackgroundVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    @ViewBuilder
    private func localizationList() -> some View {
        VStack(spacing: 0) {
            if viewModel.hasMultipleGroups {
                groupFilter()
            }
            searchBar()
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredEntries) { entry in
                        localizationRow(entry)
                            .padding(16)
                            .background(RoundedRectangle(cornerRadius: 12).fill(theme.surface))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
        }
    }

    @ViewBuilder
    private func groupFilter() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                groupChip("All", isSelected: viewModel.selectedGroup == nil) {
                    viewModel.selectGroup(nil)
                }
                ForEach(viewModel.groups, id: \.self) { group in
                    groupChip(group, isSelected: viewModel.selectedGroup == group) {
                        viewModel.selectGroup(group)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private func groupChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                .foregroundStyle(isSelected ? theme.onPrimary : theme.onBackground)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? theme.primary : theme.inputBackground)
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func searchBar() -> some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.onBackgroundVariant)
            TextField("", text: $viewModel.searchText)
                .font(.system(size: 14))
                .foregroundStyle(theme.onBackground)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .placeholder(when: viewModel.searchText.isEmpty) {
                    Text("Search by key or value...")
                        .font(.system(size: 14))
                        .foregroundStyle(theme.onBackgroundVariant)
                }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(theme.inputBackground))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.outlineVariant, lineWidth: 1))
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func localizationRow(_ entry: PhantomLocalizationEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.key)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(theme.primary)
                Spacer()
                if viewModel.showGroupBadge {
                    Text(entry.group)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(theme.onPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(theme.info))
                }
            }
            HStack(spacing: 4) {
                Text("EN:")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(theme.onBackgroundVariant)
                Text(entry.englishValue)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.onBackground)
            }
            HStack(spacing: 4) {
                Text("ES:")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(theme.onBackgroundVariant)
                Text(entry.spanishValue)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.onBackground)
            }
            HStack(spacing: 4) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(theme.success)
                Text(entry.value(for: viewModel.currentLanguage))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.success)
            }
        }
    }

    @ViewBuilder
    private func languagePicker() -> some View {
        Menu {
            ForEach(PhantomLanguage.allCases, id: \.self) { language in
                Button(action: { viewModel.setLanguage(language) }) {
                    HStack {
                        Text(language.displayName)
                        if language == viewModel.currentLanguage {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "globe")
                Text(viewModel.currentLanguage.displayName)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(theme.primary)
        }
    }
}

private extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: .leading) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
