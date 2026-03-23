import Foundation
import Combine

public final class PhantomMockInterceptor: ObservableObject {

    // MARK: - Properties

    public static let shared = PhantomMockInterceptor()
    @Published public var rules: [PhantomMockRule] = []

    private let storageKey = "phantom_mock_rules"

    // MARK: - Lifecycle

    private init() {
        load()
    }

    // MARK: - Mock Matching

    public func mockResponse(for request: URLRequest) -> (Data, HTTPURLResponse)? {
        guard let url = request.url else { return nil }
        let method = request.httpMethod ?? "GET"
        let path = url.path
        let matchedRule = rules.first { rule in
            guard rule.isEnabled else { return false }
            guard rule.httpMethod == "ANY" || rule.httpMethod == method else { return false }
            return path.contains(rule.urlPattern)
        }
        guard let rule = matchedRule, let activeResponse = rule.activeResponse else { return nil }
        let data = activeResponse.responseBody.data(using: .utf8) ?? Data()
        guard let response = HTTPURLResponse(
            url: url,
            statusCode: activeResponse.statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        ) else { return nil }
        return (data, response)
    }

    // MARK: - CRUD

    public func addRule(_ rule: PhantomMockRule) {
        rules.append(rule)
        save()
    }

    public func updateRule(_ rule: PhantomMockRule) {
        guard let index = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        rules[index] = rule
        save()
    }

    public func deleteRule(id: UUID) {
        rules.removeAll { $0.id == id }
        save()
    }

    public func toggleRule(id: UUID) {
        guard let index = rules.firstIndex(where: { $0.id == id }) else { return }
        rules[index].isEnabled.toggle()
        save()
    }

    public func setActiveResponse(ruleId: UUID, responseId: UUID) {
        guard let index = rules.firstIndex(where: { $0.id == ruleId }) else { return }
        rules[index].activeResponseId = responseId
        save()
    }

    // MARK: - Persistence

    public func save() {
        guard let data = try? JSONEncoder().encode(rules) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    public func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([PhantomMockRule].self, from: data) else { return }
        rules = decoded
    }
}
