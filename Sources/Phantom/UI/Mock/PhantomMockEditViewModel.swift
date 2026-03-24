import Foundation
import SwiftUI

final class PhantomMockEditViewModel: ObservableObject {

    @Published var ruleDescription: String
    @Published var urlPattern: String
    @Published var httpMethod: String
    @Published var responses: [PhantomMockResponse]
    @Published var activeResponseId: UUID?
    @Published var responseEditorItem: ResponseEditorItem?
    @Published var inlineStatusCode: String
    @Published var inlineResponseBody: String

    let existingRule: PhantomMockRule?
    let httpMethods = ["ANY", "GET", "POST", "PUT", "DELETE"]

    var isEditing: Bool {
        existingRule != nil
    }

    var title: String {
        isEditing ? "Edit Mock Rule" : "New Mock Rule"
    }

    var isValid: Bool {
        !ruleDescription.trimmingCharacters(in: .whitespaces).isEmpty
        && !urlPattern.trimmingCharacters(in: .whitespaces).isEmpty
        && (responses.count > 1 || Int(inlineStatusCode) != nil)
    }

    var hasMultipleResponses: Bool {
        responses.count > 1
    }

    init(existingRule: PhantomMockRule? = nil) {
        self.existingRule = existingRule
        self.ruleDescription = existingRule?.ruleDescription ?? ""
        self.urlPattern = existingRule?.urlPattern ?? ""
        self.httpMethod = existingRule?.httpMethod ?? "ANY"
        let initialResponses = existingRule?.responses ?? []
        self.responses = initialResponses
        self.activeResponseId = existingRule?.activeResponseId
        let firstResponse = existingRule?.activeResponse ?? initialResponses.first
        self.inlineStatusCode = firstResponse.map { String($0.statusCode) } ?? "200"
        self.inlineResponseBody = firstResponse?.responseBody ?? "{\n  \n}"
    }

    func selectMethod(_ method: String) {
        httpMethod = method
    }

    func setActiveResponse(_ id: UUID) {
        activeResponseId = id
    }

    func isActiveResponse(_ response: PhantomMockResponse) -> Bool {
        activeResponseId == response.id ||
        (activeResponseId == nil && responses.first?.id == response.id)
    }

    func responseIndex(for response: PhantomMockResponse) -> Int? {
        responses.firstIndex(where: { $0.id == response.id }).map { $0 + 1 }
    }

    func handleResponseSave(_ response: PhantomMockResponse) {
        if let index = responses.firstIndex(where: { $0.id == response.id }) {
            responses[index] = response
        } else {
            responses.append(response)
            if responses.count == 1 {
                activeResponseId = response.id
            }
        }
        responseEditorItem = nil
    }

    func deleteResponse(_ response: PhantomMockResponse) {
        responses.removeAll { $0.id == response.id }
        if activeResponseId == response.id {
            activeResponseId = responses.first?.id
        }
    }

    func addResponse() {
        syncInlineToResponses()
        responseEditorItem = .add
    }

    func editResponse(_ response: PhantomMockResponse) {
        responseEditorItem = .edit(response)
    }

    func pasteInlineBody() {
        guard let content = UIPasteboard.general.string else { return }
        inlineResponseBody = content
        formatInlineJson()
    }

    func formatInlineJson() {
        guard let data = inlineResponseBody.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let formatted = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]),
              let string = String(data: formatted, encoding: .utf8) else { return }
        inlineResponseBody = string
    }

    func buildRule() -> PhantomMockRule? {
        guard isValid else { return nil }
        if responses.count <= 1 {
            syncInlineToResponses()
        }
        return PhantomMockRule(
            id: existingRule?.id ?? UUID(),
            isEnabled: existingRule?.isEnabled ?? true,
            urlPattern: urlPattern.trimmingCharacters(in: .whitespaces),
            httpMethod: httpMethod,
            responses: responses,
            activeResponseId: activeResponseId ?? responses.first?.id,
            ruleDescription: ruleDescription.trimmingCharacters(in: .whitespaces),
            createdAt: existingRule?.createdAt ?? Date()
        )
    }

    func deleteExistingRule() {
        guard let id = existingRule?.id else { return }
        PhantomMockInterceptor.shared.deleteRule(id: id)
    }

    func statusColor(_ code: Int, theme: PhantomTheme) -> Color {
        if (200..<300).contains(code) { return theme.success }
        if (400..<500).contains(code) { return theme.warning }
        if code >= 500 { return theme.error }
        return theme.onBackgroundVariant
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
}
