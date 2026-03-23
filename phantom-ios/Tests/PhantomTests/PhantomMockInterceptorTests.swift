import Testing
import Foundation
@testable import Phantom

@Suite("PhantomMockInterceptor Tests", .serialized)
struct PhantomMockInterceptorTests {

    private func cleanInterceptor() -> PhantomMockInterceptor {
        let interceptor = PhantomMockInterceptor.shared
        interceptor.rules.removeAll()
        interceptor.save()
        return interceptor
    }

    @Test("returns nil when no rules match")
    func noMatchReturnsNil() {
        let interceptor = cleanInterceptor()
        let request = URLRequest(url: URL(string: "https://api.example.com/v1/users")!)
        #expect(interceptor.mockResponse(for: request) == nil)
    }

    @Test("matches rule by URL pattern and returns mock data")
    func matchesByURLPattern() throws {
        let interceptor = cleanInterceptor()
        let response = PhantomMockResponse(name: "Success", statusCode: 200, responseBody: "{\"ok\":true}")
        let rule = PhantomMockRule(
            urlPattern: "/v1/users",
            responses: [response],
            activeResponseId: response.id,
            ruleDescription: "Mock users"
        )
        interceptor.addRule(rule)

        let request = URLRequest(url: URL(string: "https://api.example.com/v1/users?page=1")!)
        let result = interceptor.mockResponse(for: request)
        #expect(result != nil)
        #expect(result?.1.statusCode == 200)

        let unwrappedResult = try #require(result)
        let bodyString = String(data: unwrappedResult.0, encoding: .utf8)
        #expect(bodyString == "{\"ok\":true}")
    }

    @Test("disabled rule is not matched")
    func disabledRuleNotMatched() {
        let interceptor = cleanInterceptor()
        let response = PhantomMockResponse(name: "Success", statusCode: 200, responseBody: "{}")
        let rule = PhantomMockRule(
            isEnabled: false,
            urlPattern: "/v1/users",
            responses: [response],
            ruleDescription: "Disabled mock"
        )
        interceptor.addRule(rule)

        let request = URLRequest(url: URL(string: "https://api.example.com/v1/users")!)
        #expect(interceptor.mockResponse(for: request) == nil)
    }

    @Test("matches by HTTP method")
    func matchesByHTTPMethod() {
        let interceptor = cleanInterceptor()
        let response = PhantomMockResponse(name: "Created", statusCode: 201, responseBody: "{}")
        let rule = PhantomMockRule(
            urlPattern: "/v1/users",
            httpMethod: "POST",
            responses: [response],
            activeResponseId: response.id,
            ruleDescription: "Mock create user"
        )
        interceptor.addRule(rule)

        var getRequest = URLRequest(url: URL(string: "https://api.example.com/v1/users")!)
        getRequest.httpMethod = "GET"
        #expect(interceptor.mockResponse(for: getRequest) == nil)

        var postRequest = URLRequest(url: URL(string: "https://api.example.com/v1/users")!)
        postRequest.httpMethod = "POST"
        let result = interceptor.mockResponse(for: postRequest)
        #expect(result != nil)
        #expect(result?.1.statusCode == 201)
    }

    @Test("ANY method matches all HTTP methods")
    func anyMethodMatchesAll() {
        let interceptor = cleanInterceptor()
        let response = PhantomMockResponse(name: "OK", statusCode: 200, responseBody: "{}")
        let rule = PhantomMockRule(
            urlPattern: "/v1/data",
            httpMethod: "ANY",
            responses: [response],
            activeResponseId: response.id,
            ruleDescription: "Mock any"
        )
        interceptor.addRule(rule)

        for method in ["GET", "POST", "PUT", "DELETE"] {
            var request = URLRequest(url: URL(string: "https://api.example.com/v1/data")!)
            request.httpMethod = method
            #expect(interceptor.mockResponse(for: request) != nil)
        }
    }

    @Test("toggle rule changes isEnabled")
    func toggleRule() {
        let interceptor = cleanInterceptor()
        let response = PhantomMockResponse(name: "OK", statusCode: 200, responseBody: "{}")
        let rule = PhantomMockRule(
            urlPattern: "/v1/test",
            responses: [response],
            ruleDescription: "Toggle test"
        )
        interceptor.addRule(rule)
        #expect(interceptor.rules.first?.isEnabled == true)

        interceptor.toggleRule(id: rule.id)
        #expect(interceptor.rules.first?.isEnabled == false)
    }

    @Test("delete rule removes it")
    func deleteRule() {
        let interceptor = cleanInterceptor()
        let response = PhantomMockResponse(name: "OK", statusCode: 200, responseBody: "{}")
        let rule = PhantomMockRule(
            urlPattern: "/v1/test",
            responses: [response],
            ruleDescription: "Delete test"
        )
        interceptor.addRule(rule)
        #expect(interceptor.rules.count == 1)

        interceptor.deleteRule(id: rule.id)
        #expect(interceptor.rules.isEmpty)
    }

    @Test("PhantomMockRule activeResponse returns first when no activeResponseId")
    func activeResponseFallback() {
        let r1 = PhantomMockResponse(name: "R1", statusCode: 200, responseBody: "{}")
        let r2 = PhantomMockResponse(name: "R2", statusCode: 404, responseBody: "{}")
        let rule = PhantomMockRule(
            urlPattern: "/test",
            responses: [r1, r2],
            activeResponseId: nil,
            ruleDescription: "Fallback test"
        )
        #expect(rule.activeResponse?.name == "R1")
    }

    @Test("PhantomMockRule activeResponse returns matching response")
    func activeResponseExact() {
        let r1 = PhantomMockResponse(name: "R1", statusCode: 200, responseBody: "{}")
        let r2 = PhantomMockResponse(name: "R2", statusCode: 404, responseBody: "{}")
        let rule = PhantomMockRule(
            urlPattern: "/test",
            responses: [r1, r2],
            activeResponseId: r2.id,
            ruleDescription: "Exact test"
        )
        #expect(rule.activeResponse?.name == "R2")
    }
}
