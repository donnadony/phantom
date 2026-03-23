import Foundation

extension URLRequest {

    var phantomCURLCommand: String {
        guard let url = url?.absoluteString else { return "curl" }
        var parts: [String] = []
        parts.append("curl --location")
        parts.append("-X \(httpMethod ?? "GET")")
        parts.append("'\(url.phantomShellEscaped)'")
        if let headers = allHTTPHeaderFields {
            for (key, value) in headers where !key.isEmpty {
                parts.append("-H '\("\(key): \(value)".phantomShellEscaped)'")
            }
        }
        if let body = httpBody, let bodyString = String(data: body, encoding: .utf8), !bodyString.isEmpty {
            parts.append("--data-raw '\(bodyString.phantomShellEscaped)'")
        }
        return parts.joined(separator: " \\\n")
    }
}

extension String {

    var phantomShellEscaped: String {
        replacingOccurrences(of: "'", with: "'\"'\"'")
    }
}
