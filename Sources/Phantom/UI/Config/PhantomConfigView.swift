import SwiftUI

struct PhantomConfigView: View {

    @Environment(\.phantomTheme) private var theme
    @StateObject private var viewModel = PhantomConfigViewModel()

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            if viewModel.hasEntries {
                configList()
            } else {
                emptyState()
            }
        }
        .navigationTitle("Configuration")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.resetAll() }) {
                    Text("Reset All")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.error)
                }
            }
        }
        .onAppear { viewModel.initializeGroupSelection() }
    }

    @ViewBuilder
    private func emptyState() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "gearshape")
                .font(.system(size: 48))
                .foregroundStyle(theme.onBackgroundVariant)
            Text("No configuration entries")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(theme.onBackground)
            Text("Use Phantom.registerConfig() to add configurable values.")
                .font(.system(size: 14))
                .foregroundStyle(theme.onBackgroundVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    @ViewBuilder
    private func configList() -> some View {
        VStack(spacing: 0) {
            if viewModel.hasMultipleGroups {
                groupFilter()
            }
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.groupedEntries, id: \.group) { section in
                        if viewModel.hasMultipleGroups && viewModel.selectedGroup == nil {
                            groupHeader(section.group)
                        }
                        ForEach(section.entries) { entry in
                            configRow(entry)
                                .padding(16)
                                .background(RoundedRectangle(cornerRadius: 12).fill(theme.surface))
                        }
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
    private func groupHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(theme.onBackgroundVariant)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private func configRow(_ entry: PhantomConfigEntry) -> some View {
        let effectiveValue = viewModel.effectiveValue(for: entry.key, defaultValue: entry.defaultValue)
        let isOverridden = viewModel.isOverridden(entry.key)

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.label)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(theme.onBackground)
                if isOverridden {
                    Text("Modified")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(theme.onPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(theme.warning))
                }
            }
            HStack(spacing: 4) {
                Text("Default:")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(theme.onBackgroundVariant)
                Text(entry.defaultValue)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(theme.onBackgroundVariant)
            }
            if isOverridden && entry.type != .toggle && entry.type != .picker {
                HStack(spacing: 4) {
                    Text("Current:")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(theme.success)
                    Text(effectiveValue)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(theme.success)
                }
            }
            switch entry.type {
            case .toggle:
                toggleEditor(entry)
            case .picker:
                pickerEditor(entry)
            case .text:
                textEditor(entry)
            }
            if isOverridden {
                Button(action: { viewModel.resetValue(for: entry.key) }) {
                    Text("Reset to Default")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(theme.error)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(theme.error.opacity(0.4), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func textEditor(_ entry: PhantomConfigEntry) -> some View {
        let currentValue = viewModel.value(for: entry.key) ?? ""
        ZStack(alignment: .leading) {
            if currentValue.isEmpty {
                Text(entry.defaultValue)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(theme.onBackgroundVariant)
                    .padding(.horizontal, 10)
            }
            TextField("", text: Binding(
                get: { currentValue },
                set: { viewModel.setValue($0, for: entry.key) }
            ))
            .font(.system(size: 13, design: .monospaced))
            .foregroundStyle(theme.onBackground)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .padding(.horizontal, 10)
        }
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(theme.inputBackground))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.outlineVariant, lineWidth: 1))
    }

    @ViewBuilder
    private func toggleEditor(_ entry: PhantomConfigEntry) -> some View {
        Toggle("Enabled", isOn: Binding(
            get: { viewModel.toggleValue(for: entry.key) },
            set: { viewModel.setToggle($0, for: entry.key) }
        ))
        .font(.system(size: 14))
        .foregroundStyle(theme.onBackground)
        .tint(theme.tint)
    }

    @ViewBuilder
    private func pickerEditor(_ entry: PhantomConfigEntry) -> some View {
        let currentValue = viewModel.effectiveValue(for: entry.key, defaultValue: entry.defaultValue)
        Picker(entry.label, selection: Binding(
            get: { currentValue },
            set: { viewModel.setValue($0, for: entry.key) }
        )) {
            ForEach(entry.options, id: \.self) { option in
                Text(option).tag(option)
            }
        }
        .pickerStyle(.segmented)
    }
}
