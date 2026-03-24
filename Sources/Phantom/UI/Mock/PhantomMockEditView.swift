import SwiftUI

struct PhantomMockEditView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.phantomTheme) private var theme
    @StateObject private var viewModel: PhantomMockEditViewModel

    private let onSave: (PhantomMockRule) -> Void

    init(existingRule: PhantomMockRule? = nil, onSave: @escaping (PhantomMockRule) -> Void) {
        _viewModel = StateObject(wrappedValue: PhantomMockEditViewModel(existingRule: existingRule))
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    fieldSection("Description", text: $viewModel.ruleDescription, placeholder: "e.g. Empty response")
                    fieldSection("URL Pattern (partial match)", text: $viewModel.urlPattern, placeholder: "e.g. /v1/users")
                    methodPicker()
                    responsesSection()
                    deleteButton()
                }
                .padding(16)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .font(.system(size: 14))
                        .foregroundStyle(theme.onBackgroundVariant)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveRule() }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(viewModel.isValid ? theme.primary : theme.onBackgroundVariant)
                        .disabled(!viewModel.isValid)
                }
            }
            .sheet(item: $viewModel.responseEditorItem) { item in
                PhantomMockResponseEditView(
                    existingResponse: item.response,
                    responseIndex: item.response.flatMap { viewModel.responseIndex(for: $0) } ?? (viewModel.responses.count + 1),
                    onSave: { viewModel.handleResponseSave($0) }
                )
                .environment(\.phantomTheme, theme)
            }
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private func fieldSection(_ title: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(theme.onBackground)
            TextField(placeholder, text: text)
                .font(.system(size: 14))
                .foregroundStyle(theme.onBackground)
                .keyboardType(keyboard)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8).fill(theme.surface))
        }
    }

    @ViewBuilder
    private func methodPicker() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("HTTP Method")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(theme.onBackground)
            HStack(spacing: 8) {
                ForEach(viewModel.httpMethods, id: \.self) { method in
                    Button(action: { viewModel.selectMethod(method) }) {
                        Text(method)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(viewModel.httpMethod == method ? theme.onPrimary : theme.onBackground)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(viewModel.httpMethod == method ? theme.primary : theme.surface)
                            )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func responsesSection() -> some View {
        if viewModel.hasMultipleResponses {
            multiResponseList()
        } else {
            inlineResponseEditor()
        }
    }

    @ViewBuilder
    private func inlineResponseEditor() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            fieldSection("Status Code", text: $viewModel.inlineStatusCode, placeholder: "200", keyboard: .numberPad)
            inlineBodyEditor()
            Button(action: { viewModel.addResponse() }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Add another response")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(theme.primary)
            }
        }
    }

    @ViewBuilder
    private func inlineBodyEditor() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Response Body (JSON)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(theme.onBackground)
                Spacer()
                Button(action: { viewModel.pasteInlineBody() }) {
                    Text("Paste")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.primary)
                }
                Button(action: { viewModel.formatInlineJson() }) {
                    Text("Format")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.primary)
                }
            }
            PhantomThemedTextEditor(text: $viewModel.inlineResponseBody)
        }
    }

    @ViewBuilder
    private func multiResponseList() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Responses (\(viewModel.responses.count))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(theme.onBackground)
                Spacer()
                Button(action: { viewModel.responseEditorItem = .add }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(theme.primary)
                }
            }
            ForEach(viewModel.responses) { response in
                responseRow(response)
            }
        }
    }

    @ViewBuilder
    private func responseRow(_ response: PhantomMockResponse) -> some View {
        let isActive = viewModel.isActiveResponse(response)
        HStack(spacing: 10) {
            Button(action: { viewModel.setActiveResponse(response.id) }) {
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isActive ? theme.primary : theme.onBackgroundVariant)
                    .font(.system(size: 20))
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(response.name)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.onBackground)
                        .lineLimit(1)
                    if isActive {
                        Text("ACTIVE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(theme.onPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 4).fill(theme.primary))
                    }
                }
                Text("Status: \(response.statusCode)")
                    .font(.system(size: 12))
                    .foregroundStyle(viewModel.statusColor(response.statusCode, theme: theme))
            }
            Spacer()
            Button(action: { viewModel.editResponse(response) }) {
                Image(systemName: "pencil")
                    .foregroundStyle(theme.primary)
                    .font(.system(size: 14))
            }
            Button(action: { viewModel.deleteResponse(response) }) {
                Image(systemName: "trash")
                    .foregroundStyle(theme.error)
                    .font(.system(size: 14))
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(isActive ? theme.primary.opacity(0.08) : theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isActive ? theme.primary : .clear, lineWidth: 1))
    }

    @ViewBuilder
    private func deleteButton() -> some View {
        if viewModel.isEditing {
            Button(action: {
                viewModel.deleteExistingRule()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Delete Rule")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(theme.error)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 8).fill(theme.error.opacity(0.1)))
            }
        }
    }

    private func saveRule() {
        guard let rule = viewModel.buildRule() else { return }
        onSave(rule)
    }
}

// MARK: - Response Edit View

struct PhantomMockResponseEditView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.phantomTheme) private var theme
    @State private var name: String
    @State private var statusCode: String
    @State private var responseBody: String

    private let existingResponse: PhantomMockResponse?
    private let responseIndex: Int
    private let onSave: (PhantomMockResponse) -> Void

    init(existingResponse: PhantomMockResponse? = nil, responseIndex: Int, onSave: @escaping (PhantomMockResponse) -> Void) {
        self.existingResponse = existingResponse
        self.responseIndex = responseIndex
        self.onSave = onSave
        _name = State(initialValue: existingResponse?.name ?? "Response \(responseIndex)")
        _statusCode = State(initialValue: existingResponse.map { String($0.statusCode) } ?? "200")
        _responseBody = State(initialValue: existingResponse?.responseBody ?? "{\n  \n}")
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && Int(statusCode) != nil
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    fieldSection("Name", text: $name, placeholder: "e.g. Success response")
                    fieldSection("Status Code", text: $statusCode, placeholder: "200", keyboard: .numberPad)
                    responseBodyEditor()
                }
                .padding(16)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle(existingResponse == nil ? "New Response" : "Edit Response")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .font(.system(size: 14))
                        .foregroundStyle(theme.onBackgroundVariant)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveResponse() }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isValid ? theme.primary : theme.onBackgroundVariant)
                        .disabled(!isValid)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private func fieldSection(_ title: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(theme.onBackground)
            TextField(placeholder, text: text)
                .font(.system(size: 14))
                .foregroundStyle(theme.onBackground)
                .keyboardType(keyboard)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8).fill(theme.surface))
        }
    }

    @ViewBuilder
    private func responseBodyEditor() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Response Body (JSON)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(theme.onBackground)
                Spacer()
                Button(action: pasteFromClipboard) {
                    Text("Paste")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.primary)
                }
                Button(action: formatJson) {
                    Text("Format")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.primary)
                }
            }
            PhantomThemedTextEditor(text: $responseBody)
        }
    }

    private func saveResponse() {
        guard isValid else { return }
        let response = PhantomMockResponse(
            id: existingResponse?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            statusCode: Int(statusCode) ?? 200,
            responseBody: responseBody
        )
        onSave(response)
    }

    private func pasteFromClipboard() {
        guard let content = UIPasteboard.general.string else { return }
        responseBody = content
        formatJson()
    }

    private func formatJson() {
        guard let data = responseBody.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let formatted = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]),
              let string = String(data: formatted, encoding: .utf8) else { return }
        responseBody = string
    }
}

// MARK: - Response Editor Item

struct ResponseEditorItem: Identifiable {
    let id: UUID
    let response: PhantomMockResponse?

    static var add: ResponseEditorItem {
        ResponseEditorItem(id: UUID(), response: nil)
    }

    static func edit(_ response: PhantomMockResponse) -> ResponseEditorItem {
        ResponseEditorItem(id: response.id, response: response)
    }
}

// MARK: - Themed TextEditor

struct PhantomThemedTextEditor: View {

    @Binding var text: String
    @Environment(\.phantomTheme) private var theme

    var body: some View {
        TextEditor(text: $text)
            .font(.system(size: 12, weight: .regular, design: .monospaced))
            .foregroundStyle(theme.onBackground)
            .phantomHideScrollBackground()
            .frame(minHeight: 200)
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).fill(theme.inputBackground))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.outlineVariant, lineWidth: 1))
    }
}

private extension View {

    @ViewBuilder
    func phantomHideScrollBackground() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self.onAppear { UITextView.appearance().backgroundColor = .clear }
        }
    }
}
