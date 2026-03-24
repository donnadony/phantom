#if DEBUG

import SwiftUI

struct PhantomMockEditView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.phantomTheme) private var theme
    @State private var ruleDescription: String
    @State private var urlPattern: String
    @State private var httpMethod: String
    @State private var responses: [PhantomMockResponse]
    @State private var activeResponseId: UUID?
    @State private var editingResponse: PhantomMockResponse?
    @State private var showResponseEditor = false
    @State private var inlineStatusCode: String
    @State private var inlineResponseBody: String

    private let existingRule: PhantomMockRule?
    private let onSave: (PhantomMockRule) -> Void
    private let httpMethods = ["ANY", "GET", "POST", "PUT", "DELETE"]

    init(existingRule: PhantomMockRule? = nil, onSave: @escaping (PhantomMockRule) -> Void) {
        self.existingRule = existingRule
        self.onSave = onSave
        _ruleDescription = State(initialValue: existingRule?.ruleDescription ?? "")
        _urlPattern = State(initialValue: existingRule?.urlPattern ?? "")
        _httpMethod = State(initialValue: existingRule?.httpMethod ?? "ANY")
        let initialResponses = existingRule?.responses ?? []
        _responses = State(initialValue: initialResponses)
        _activeResponseId = State(initialValue: existingRule?.activeResponseId)
        let firstResponse = existingRule?.activeResponse ?? initialResponses.first
        _inlineStatusCode = State(initialValue: firstResponse.map { String($0.statusCode) } ?? "200")
        _inlineResponseBody = State(initialValue: firstResponse?.responseBody ?? "{\n  \n}")
    }

    private var isValid: Bool {
        !ruleDescription.trimmingCharacters(in: .whitespaces).isEmpty
        && !urlPattern.trimmingCharacters(in: .whitespaces).isEmpty
        && (responses.count > 1 || Int(inlineStatusCode) != nil)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    fieldSection("Description", text: $ruleDescription, placeholder: "e.g. Empty response")
                    fieldSection("URL Pattern (partial match)", text: $urlPattern, placeholder: "e.g. /v1/users")
                    methodPicker()
                    responsesSection()
                    deleteButton()
                }
                .padding(16)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle(existingRule == nil ? "New Mock Rule" : "Edit Mock Rule")
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
                        .foregroundStyle(isValid ? theme.primary : theme.onBackgroundVariant)
                        .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showResponseEditor) {
                PhantomMockResponseEditView(
                    existingResponse: editingResponse,
                    responseIndex: editingResponse.flatMap { resp in responses.firstIndex(where: { $0.id == resp.id }).map { $0 + 1 } } ?? (responses.count + 1),
                    onSave: { response in
                        if let index = responses.firstIndex(where: { $0.id == response.id }) {
                            responses[index] = response
                        } else {
                            responses.append(response)
                            if responses.count == 1 {
                                activeResponseId = response.id
                            }
                        }
                        editingResponse = nil
                        showResponseEditor = false
                    }
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
                ForEach(httpMethods, id: \.self) { method in
                    Button(action: { httpMethod = method }) {
                        Text(method)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(httpMethod == method ? theme.onPrimary : theme.onBackground)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(httpMethod == method ? theme.primary : theme.surface)
                            )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func responsesSection() -> some View {
        if responses.count <= 1 {
            inlineResponseEditor()
        } else {
            multiResponseList()
        }
    }

    @ViewBuilder
    private func inlineResponseEditor() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            fieldSection("Status Code", text: $inlineStatusCode, placeholder: "200", keyboard: .numberPad)
            inlineBodyEditor()
            Button(action: {
                syncInlineToResponses()
                editingResponse = nil
                showResponseEditor = true
            }) {
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
                Button(action: {
                    guard let content = UIPasteboard.general.string else { return }
                    inlineResponseBody = content
                    formatInlineJson()
                }) {
                    Text("Paste")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.primary)
                }
                Button(action: formatInlineJson) {
                    Text("Format")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.primary)
                }
            }
            TextEditor(text: $inlineResponseBody)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(theme.onBackground)
                .frame(minHeight: 200)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(theme.surface))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.outlineVariant, lineWidth: 1))
        }
    }

    @ViewBuilder
    private func multiResponseList() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Responses (\(responses.count))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(theme.onBackground)
                Spacer()
                Button(action: {
                    editingResponse = nil
                    showResponseEditor = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(theme.primary)
                }
            }
            ForEach(responses) { response in
                responseRow(response)
            }
        }
    }

    @ViewBuilder
    private func responseRow(_ response: PhantomMockResponse) -> some View {
        let isActive = (activeResponseId == response.id) || (activeResponseId == nil && responses.first?.id == response.id)
        HStack(spacing: 10) {
            Button(action: { activeResponseId = response.id }) {
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isActive ? theme.primary : theme.onBackgroundVariant)
                    .font(.system(size: 20))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(response.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(theme.onBackground)
                    .lineLimit(1)
                Text("Status: \(response.statusCode)")
                    .font(.system(size: 12))
                    .foregroundStyle(statusColor(response.statusCode))
            }
            Spacer()
            Button(action: {
                editingResponse = response
                showResponseEditor = true
            }) {
                Image(systemName: "pencil")
                    .foregroundStyle(theme.primary)
                    .font(.system(size: 14))
            }
            Button(action: {
                responses.removeAll { $0.id == response.id }
                if activeResponseId == response.id {
                    activeResponseId = responses.first?.id
                }
            }) {
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
        if existingRule != nil {
            Button(action: {
                if let id = existingRule?.id {
                    PhantomMockInterceptor.shared.deleteRule(id: id)
                }
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

    private func syncInlineToResponses() {
        if responses.isEmpty {
            let newResponse = PhantomMockResponse(
                id: UUID(),
                name: "Response 1",
                statusCode: Int(inlineStatusCode) ?? 200,
                responseBody: inlineResponseBody
            )
            responses.append(newResponse)
            activeResponseId = newResponse.id
        } else if responses.count == 1 {
            responses[0] = PhantomMockResponse(
                id: responses[0].id,
                name: responses[0].name,
                statusCode: Int(inlineStatusCode) ?? 200,
                responseBody: inlineResponseBody
            )
            activeResponseId = responses[0].id
        }
    }

    private func formatInlineJson() {
        guard let data = inlineResponseBody.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let formatted = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]),
              let string = String(data: formatted, encoding: .utf8) else { return }
        inlineResponseBody = string
    }

    private func saveRule() {
        guard isValid else { return }
        if responses.count <= 1 {
            syncInlineToResponses()
        }
        let rule = PhantomMockRule(
            id: existingRule?.id ?? UUID(),
            isEnabled: existingRule?.isEnabled ?? true,
            urlPattern: urlPattern.trimmingCharacters(in: .whitespaces),
            httpMethod: httpMethod,
            responses: responses,
            activeResponseId: activeResponseId ?? responses.first?.id,
            ruleDescription: ruleDescription.trimmingCharacters(in: .whitespaces),
            createdAt: existingRule?.createdAt ?? Date()
        )
        onSave(rule)
    }

    private func statusColor(_ code: Int) -> Color {
        if (200..<300).contains(code) { return theme.success }
        if (400..<500).contains(code) { return theme.warning }
        if code >= 500 { return theme.error }
        return theme.onBackgroundVariant
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
            TextEditor(text: $responseBody)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(theme.onBackground)
                .frame(minHeight: 200)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(theme.surface))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.outlineVariant, lineWidth: 1))
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

#endif
