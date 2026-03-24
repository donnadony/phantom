import SwiftUI
import UniformTypeIdentifiers

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
            if let toast = viewModel.toastMessage {
                toastView(toast)
            }
        }
        .navigationTitle("Mock Services")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    importExportMenu()
                    Button(action: { viewModel.showAddSheet = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(theme.primary)
                    }
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
        .sheet(isPresented: $viewModel.showImportPicker) {
            PhantomDocumentPicker { url in
                viewModel.importMocks(from: url)
            }
        }
        .sheet(isPresented: $viewModel.showExportShare) {
            if let data = viewModel.exportData {
                PhantomShareSheet(data: data, fileName: "phantom_mocks.json")
            }
        }
    }

    @ViewBuilder
    private func importExportMenu() -> some View {
        Menu {
            Button(action: { viewModel.showImportPicker = true }) {
                Label("Import from file", systemImage: "square.and.arrow.down")
            }
            if viewModel.hasRules {
                Button(action: { viewModel.exportMocks() }) {
                    Label("Export all mocks", systemImage: "square.and.arrow.up")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundColor(theme.primary)
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
            Text("Tap + to create a rule, import from a JSON file, or use \"Mock this\" from the Network view.")
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

    @ViewBuilder
    private func toastView(_ message: String) -> some View {
        VStack {
            Spacer()
            Text(message)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.onPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 10).fill(theme.primary))
                .padding(.bottom, 32)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut, value: message)
    }
}

// MARK: - Document Picker

struct PhantomDocumentPicker: UIViewControllerRepresentable {

    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}

// MARK: - Share Sheet

struct PhantomShareSheet: UIViewControllerRepresentable {

    let data: Data
    let fileName: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? data.write(to: tempURL)
        return UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
