#if DEBUG

import SwiftUI

struct PhantomConfigView: View {

    @Environment(\.phantomTheme) private var theme
    @ObservedObject private var config = PhantomConfig.shared

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            if config.entries.isEmpty {
                emptyState()
            } else {
                configList()
            }
        }
        .navigationTitle("Configuration")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { PhantomConfig.shared.resetAll() }) {
                    Text("Reset All")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.error)
                }
            }
        }
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
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(config.entries) { entry in
                    configRow(entry)
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 12).fill(theme.surface))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    @ViewBuilder
    private func configRow(_ entry: PhantomConfigEntry) -> some View {
        let effectiveValue = PhantomConfig.shared.effectiveValue(for: entry.key) ?? entry.defaultValue
        let isOverridden = PhantomConfig.shared.value(for: entry.key) != nil

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
                Button(action: { PhantomConfig.shared.resetValue(for: entry.key) }) {
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
        let currentValue = PhantomConfig.shared.value(for: entry.key) ?? ""
        TextField(entry.defaultValue, text: Binding(
            get: { currentValue },
            set: { PhantomConfig.shared.setValue($0, for: entry.key) }
        ))
        .font(.system(size: 13, design: .monospaced))
        .foregroundStyle(theme.onBackground)
        .textInputAutocapitalization(.never)
        .disableAutocorrection(true)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(RoundedRectangle(cornerRadius: 8).fill(theme.inputBackground))
    }

    @ViewBuilder
    private func toggleEditor(_ entry: PhantomConfigEntry) -> some View {
        let isOn = (PhantomConfig.shared.effectiveValue(for: entry.key) ?? "false") == "true"
        Toggle("Enabled", isOn: Binding(
            get: { isOn },
            set: { PhantomConfig.shared.setValue($0 ? "true" : "false", for: entry.key) }
        ))
        .font(.system(size: 14))
        .foregroundStyle(theme.onBackground)
        .tint(theme.tint)
    }

    @ViewBuilder
    private func pickerEditor(_ entry: PhantomConfigEntry) -> some View {
        let currentValue = PhantomConfig.shared.effectiveValue(for: entry.key) ?? entry.defaultValue
        Picker(entry.label, selection: Binding(
            get: { currentValue },
            set: { PhantomConfig.shared.setValue($0, for: entry.key) }
        )) {
            ForEach(entry.options, id: \.self) { option in
                Text(option).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .tint(theme.tint)
    }
}

#endif
