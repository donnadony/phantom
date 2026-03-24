import SwiftUI

struct PhantomMockListView: View {

    @Environment(\.phantomTheme) private var theme
    @StateObject private var viewModel = PhantomMockListViewModel()

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            if viewModel.hasRules {
                ruleList()
            } else {
                emptyState()
            }
        }
        .navigationTitle("Mock Services")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.showAddSheet = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(theme.primary)
                }
            }
        }
        .sheet(isPresented: $viewModel.showAddSheet) {
            PhantomMockEditView(onSave: { rule in
                viewModel.addRule(rule)
            })
            .environment(\.phantomTheme, theme)
        }
        .sheet(item: $viewModel.editingRule) { rule in
            PhantomMockEditView(existingRule: rule, onSave: { updated in
                viewModel.updateRule(updated)
            })
            .environment(\.phantomTheme, theme)
        }
    }

    @ViewBuilder
    private func emptyState() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 48))
                .foregroundStyle(theme.onBackgroundVariant)
            Text("No mock rules")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(theme.onBackground)
            Text("Tap + to create a rule or use \"Mock this\" from the Network view.")
                .font(.system(size: 14))
                .foregroundStyle(theme.onBackgroundVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    @ViewBuilder
    private func ruleList() -> some View {
        List {
            ForEach(viewModel.rules) { rule in
                ruleRow(rule)
                    .contentShape(Rectangle())
                    .onTapGesture { viewModel.editingRule = rule }
            }
            .onDelete { viewModel.deleteRule(at: $0) }
            .listRowBackground(theme.background)
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private func ruleRow(_ rule: PhantomMockRule) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(rule.ruleDescription)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(theme.onBackground)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(rule.httpMethod)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.onPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(viewModel.methodColor(rule.httpMethod, theme: theme)))
                    Text(rule.urlPattern)
                        .font(.system(size: 12))
                        .foregroundStyle(theme.onBackgroundVariant)
                        .lineLimit(1)
                }
                if let active = rule.activeResponse {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(theme.primary)
                        Text("\(active.name) (\(active.statusCode))")
                            .font(.system(size: 12))
                            .foregroundStyle(viewModel.statusColor(active.statusCode, theme: theme))
                    }
                }
                Text("\(rule.responses.count) response\(rule.responses.count == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.onBackgroundVariant)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { _ in viewModel.toggleRule(id: rule.id) }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}
