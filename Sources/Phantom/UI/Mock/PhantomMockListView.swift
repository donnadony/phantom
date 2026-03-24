#if DEBUG

import SwiftUI

struct PhantomMockListView: View {

    @Environment(\.phantomTheme) private var theme
    @ObservedObject private var interceptor = PhantomMockInterceptor.shared
    @State private var editingRule: PhantomMockRule?
    @State private var showAddSheet = false

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            if interceptor.rules.isEmpty {
                emptyState()
            } else {
                ruleList()
            }
        }
        .navigationTitle("Mock Services")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(theme.primary)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            PhantomMockEditView(onSave: { rule in
                interceptor.addRule(rule)
                showAddSheet = false
            })
            .environment(\.phantomTheme, theme)
        }
        .sheet(item: $editingRule) { rule in
            PhantomMockEditView(existingRule: rule, onSave: { updated in
                interceptor.updateRule(updated)
                editingRule = nil
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
            ForEach(interceptor.rules) { rule in
                ruleRow(rule)
                    .contentShape(Rectangle())
                    .onTapGesture { editingRule = rule }
            }
            .onDelete { indexSet in
                indexSet.forEach { interceptor.deleteRule(id: interceptor.rules[$0].id) }
            }
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
                        .background(RoundedRectangle(cornerRadius: 4).fill(methodColor(rule.httpMethod)))
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
                            .foregroundStyle(statusColor(active.statusCode))
                    }
                }
                Text("\(rule.responses.count) response\(rule.responses.count == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.onBackgroundVariant)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { _ in interceptor.toggleRule(id: rule.id) }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }

    private func methodColor(_ method: String) -> Color {
        switch method {
        case "GET": return theme.httpGet
        case "POST": return theme.httpPost
        case "PUT": return theme.httpPut
        case "DELETE": return theme.httpDelete
        default: return theme.onBackgroundVariant
        }
    }

    private func statusColor(_ code: Int) -> Color {
        if (200..<300).contains(code) { return theme.success }
        if (400..<500).contains(code) { return theme.warning }
        if code >= 500 { return theme.error }
        return theme.onBackgroundVariant
    }
}

#endif
