import Testing
import Foundation
@testable import Phantom

@Suite("PhantomNetworkLogger Tests")
struct PhantomNetworkLoggerTests {

    @Test("PhantomNetworkItem has correct default values")
    func networkItemDefaults() {
        let item = PhantomNetworkItem(
            url: URL(string: "https://api.example.com"),
            methodType: "GET",
            requestHeaders: "Content-Type: application/json",
            requestBody: "No body",
            createdAt: Date()
        )
        #expect(item.responseHeaders == "No headers")
        #expect(item.responseBody == "")
        #expect(item.responseSizeBytes == 0)
        #expect(item.statusCode == nil)
        #expect(item.completedAt == nil)
        #expect(item.durationMs == nil)
    }

    @Test("PhantomNetworkItem stores all properties")
    func networkItemAllProperties() {
        let now = Date()
        let item = PhantomNetworkItem(
            url: URL(string: "https://api.example.com/v1/users"),
            methodType: "POST",
            requestHeaders: "Authorization: Bearer token",
            requestBody: "{\"name\":\"test\"}",
            responseHeaders: "Content-Type: application/json",
            responseBody: "{\"id\":1}",
            responseSizeBytes: 8,
            statusCode: 201,
            completedAt: now,
            durationMs: 150,
            createdAt: now
        )
        #expect(item.url?.absoluteString == "https://api.example.com/v1/users")
        #expect(item.methodType == "POST")
        #expect(item.statusCode == 201)
        #expect(item.durationMs == 150)
        #expect(item.responseSizeBytes == 8)
    }

    @Test("PhantomJSON prettyPrint formats valid JSON")
    func prettyPrintValidJson() {
        let json = "{\"b\":2,\"a\":1}"
        let result = PhantomJSON.prettyPrint(json)
        #expect(result != nil)
        #expect(result?.contains("\"a\" : 1") == true)
        #expect(result?.contains("\"b\" : 2") == true)
    }

    @Test("PhantomJSON prettyPrint returns nil for invalid JSON")
    func prettyPrintInvalidJson() {
        let result = PhantomJSON.prettyPrint("not json")
        #expect(result == nil)
    }
}
