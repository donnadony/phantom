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

    // MARK: - Import

    @discardableResult
    public func loadMocks(from fileName: String, in bundle: Bundle = .main) -> Bool {
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else { return false }
        return loadMocks(from: url)
    }

    @discardableResult
    public func loadMocks(from url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url) else { return false }
        return loadMocks(from: data)
    }

    @discardableResult
    public func loadMocks(from data: Data) -> Bool {
        if let collection = try? JSONDecoder().decode(PhantomMockCollection.self, from: data) {
            mergeRules(collection.rules)
            return true
        }
        if let rawRules = try? JSONDecoder().decode([PhantomMockRule].self, from: data) {
            mergeRules(rawRules)
            return true
        }
        return false
    }

    private func mergeRules(_ newRules: [PhantomMockRule]) {
        for newRule in newRules {
            if let index = rules.firstIndex(where: { $0.urlPattern == newRule.urlPattern && $0.httpMethod == newRule.httpMethod }) {
                rules[index] = newRule
            } else {
                rules.append(newRule)
            }
        }
        save()
    }

    // MARK: - Export

    public func exportCollection(name: String = "Phantom Mocks", description: String = "") -> Data? {
        let collection = PhantomMockCollection(name: name, description: description, rules: rules)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try? encoder.encode(collection)
    }
}
