import Foundation
import Combine

public final class PhantomNetworkLogger: ObservableObject {

    // MARK: - Properties

    public static let shared = PhantomNetworkLogger()
    @Published public private(set) var logs: [PhantomNetworkItem] = []

    private let storeQueue = DispatchQueue(label: "com.phantom.network.store")
    private var items: [PhantomNetworkItem] = []
    private var pendingByRequestKey: [String: [UUID]] = [:]
    private var pendingByURL: [String: [UUID]] = [:]

    // MARK: - Lifecycle

    private init() {}

    // MARK: - Public API

    public func logRequest(_ urlRequest: URLRequest) {
        let item = PhantomNetworkItem(
            url: urlRequest.url,
            methodType: urlRequest.httpMethod ?? "GET",
            requestHeaders: headersString(from: urlRequest),
            requestBody: requestBodyString(from: urlRequest),
            createdAt: Date()
        )
        mutate { storage in
            storage.append(item)
            self.addPending(id: item.id, for: urlRequest)
        }
    }

    public func logResponse(for urlRequest: URLRequest, body: Data?) {
        let responseBody = bodyString(from: body)
        let responseSize = body?.count ?? 0
        mutate { storage in
            if let index = self.indexOfPending(for: urlRequest, in: storage) {
                storage[index].responseBody = responseBody
                storage[index].completedAt = Date()
                storage[index].responseSizeBytes = responseSize
                storage[index].durationMs = self.durationMs(from: storage[index].createdAt, to: storage[index].completedAt)
                self.removePending(id: storage[index].id)
            } else {
                storage.append(
                    PhantomNetworkItem(
                        url: urlRequest.url,
                        methodType: urlRequest.httpMethod ?? "GET",
                        requestHeaders: self.headersString(from: urlRequest),
                        requestBody: self.requestBodyString(from: urlRequest),
                        responseBody: responseBody,
                        responseSizeBytes: responseSize,
                        completedAt: Date(),
                        createdAt: Date()
                    )
                )
            }
        }
    }

    public func logResponse(for urlRequest: URLRequest, errorMessage: String) {
        mutate { storage in
            if let index = self.indexOfPending(for: urlRequest, in: storage) {
                storage[index].responseBody = errorMessage
                storage[index].completedAt = Date()
                storage[index].responseSizeBytes = errorMessage.lengthOfBytes(using: .utf8)
                storage[index].durationMs = self.durationMs(from: storage[index].createdAt, to: storage[index].completedAt)
                self.removePending(id: storage[index].id)
            } else {
                storage.append(
                    PhantomNetworkItem(
                        url: urlRequest.url,
                        methodType: urlRequest.httpMethod ?? "GET",
                        requestHeaders: self.headersString(from: urlRequest),
                        requestBody: self.requestBodyString(from: urlRequest),
                        responseBody: errorMessage,
                        responseSizeBytes: errorMessage.lengthOfBytes(using: .utf8),
                        completedAt: Date(),
                        createdAt: Date()
                    )
                )
            }
        }
    }

    public func logResponse(
        url: URL?,
        methodType: String,
        headers: String,
        body: String,
        statusCode: Int?
    ) {
        mutate { storage in
            if let index = self.indexOfPending(for: url, in: storage) {
                storage[index].responseHeaders = headers
                storage[index].statusCode = statusCode
                if storage[index].responseBody.isEmpty {
                    storage[index].responseBody = body
                    storage[index].responseSizeBytes = body.lengthOfBytes(using: .utf8)
                }
                if storage[index].completedAt == nil {
                    storage[index].completedAt = Date()
                    storage[index].durationMs = self.durationMs(from: storage[index].createdAt, to: storage[index].completedAt)
                    self.removePending(id: storage[index].id)
                }
            } else {
                storage.append(
                    PhantomNetworkItem(
                        url: url,
                        methodType: methodType,
                        requestHeaders: "No headers",
                        requestBody: "No body",
                        responseHeaders: headers,
                        responseBody: body,
                        responseSizeBytes: body.lengthOfBytes(using: .utf8),
                        statusCode: statusCode,
                        completedAt: Date(),
                        createdAt: Date()
                    )
                )
            }
        }
    }

    public func updateResponseMetadata(
        url: URL?,
        headers: String,
        statusCode: Int?
    ) {
        mutate { storage in
            if let index = self.indexOfPending(for: url, in: storage) {
                storage[index].responseHeaders = headers
                storage[index].statusCode = statusCode
                storage[index].durationMs = self.durationMs(from: storage[index].createdAt, to: storage[index].completedAt)
                return
            }
            guard let fallbackIndex = self.indexOfLatestByURLWithoutStatus(for: url, in: storage) else { return }
            storage[fallbackIndex].responseHeaders = headers
            storage[fallbackIndex].statusCode = statusCode
            storage[fallbackIndex].durationMs = self.durationMs(from: storage[fallbackIndex].createdAt, to: storage[fallbackIndex].completedAt)
        }
    }

    public func logExternalEntry(_ jsonString: String, sourcePrefix: String = "[External]") {
        guard let data = jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        let urlString = dict["url"] as? String ?? ""
        let method = dict["method"] as? String ?? "GET"
        let statusCode = dict["statusCode"] as? Int
        let requestHeaders = dict["requestHeaders"] as? String ?? "No headers"
        let responseBody = dict["responseBody"] as? String ?? ""
        let responseSizeBytes = dict["responseSizeBytes"] as? Int ?? 0
        let durationMs = dict["durationMs"] as? Int
        let now = Date()
        let createdAt = durationMs.map { now.addingTimeInterval(-Double($0) / 1000.0) } ?? now
        let item = PhantomNetworkItem(
            url: URL(string: urlString),
            methodType: "\(sourcePrefix) \(method)",
            requestHeaders: requestHeaders,
            requestBody: "No body",
            responseHeaders: "No headers",
            responseBody: responseBody,
            responseSizeBytes: responseSizeBytes,
            statusCode: statusCode,
            completedAt: now,
            durationMs: durationMs,
            createdAt: createdAt
        )
        mutate { storage in
            storage.append(item)
        }
    }

    public func clearAll() {
        mutate { storage in
            storage.removeAll()
            self.pendingByRequestKey.removeAll()
            self.pendingByURL.removeAll()
        }
    }

    // MARK: - Helpers

    private func mutate(_ block: (inout [PhantomNetworkItem]) -> Void) {
        storeQueue.sync {
            block(&items)
            let snapshot = items
            DispatchQueue.main.async {
                self.logs = snapshot
            }
        }
    }

    private func addPending(id: UUID, for request: URLRequest) {
        let requestKey = makeRequestKey(from: request)
        pendingByRequestKey[requestKey, default: []].append(id)
        if let urlKey = urlKey(from: request.url) {
            pendingByURL[urlKey, default: []].append(id)
        }
    }

    private func removePending(id: UUID) {
        pendingByRequestKey = pendingByRequestKey.compactMapValues { ids in
            let newIDs = ids.filter { $0 != id }
            return newIDs.isEmpty ? nil : newIDs
        }
        pendingByURL = pendingByURL.compactMapValues { ids in
            let newIDs = ids.filter { $0 != id }
            return newIDs.isEmpty ? nil : newIDs
        }
    }

    private func indexOfPending(for request: URLRequest, in storage: [PhantomNetworkItem]) -> Int? {
        let key = makeRequestKey(from: request)
        if let ids = pendingByRequestKey[key] {
            for id in ids {
                if let index = storage.firstIndex(where: { $0.id == id && $0.completedAt == nil }) {
                    return index
                }
            }
        }
        return indexOfPending(for: request.url, in: storage)
    }

    private func indexOfPending(for url: URL?, in storage: [PhantomNetworkItem]) -> Int? {
        guard let key = urlKey(from: url), let ids = pendingByURL[key] else { return nil }
        for id in ids {
            if let index = storage.firstIndex(where: { $0.id == id && $0.completedAt == nil }) {
                return index
            }
        }
        return nil
    }

    private func indexOfLatestByURLWithoutStatus(for url: URL?, in storage: [PhantomNetworkItem]) -> Int? {
        guard let key = urlKey(from: url) else { return nil }
        return storage.lastIndex {
            $0.url?.absoluteString == key && $0.statusCode == nil
        }
    }

    private func makeRequestKey(from request: URLRequest) -> String {
        let method = request.httpMethod ?? "GET"
        let url = urlKey(from: request.url) ?? "NoURL"
        let bodyHash = request.httpBody?.base64EncodedString() ?? "NoBody"
        return "\(method)|\(url)|\(bodyHash)"
    }

    private func urlKey(from url: URL?) -> String? {
        guard let absolute = url?.absoluteString, !absolute.isEmpty else { return nil }
        return absolute
    }

    private func headersString(from urlRequest: URLRequest) -> String {
        guard let headers = urlRequest.allHTTPHeaderFields, !headers.isEmpty else {
            return "No headers"
        }
        return headers.map { "\($0): \($1)" }.joined(separator: "\n")
    }

    private func requestBodyString(from urlRequest: URLRequest) -> String {
        bodyString(from: urlRequest.httpBody)
    }

    private func bodyString(from data: Data?) -> String {
        guard let data else { return "No body" }
        if let prettyJson = PhantomJSON.prettyPrint(data) {
            return prettyJson
        }
        return String(data: data, encoding: .utf8) ?? "No body"
    }

    private func durationMs(from start: Date, to end: Date?) -> Int? {
        guard let end else { return nil }
        return Int(end.timeIntervalSince(start) * 1000)
    }
}
