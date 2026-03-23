import Foundation

enum PhantomJSON {

    static func prettyPrint(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data),
              let formatted = try? JSONSerialization.data(
                withJSONObject: json,
                options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
              ),
              let string = String(data: formatted, encoding: .utf8) else {
            return nil
        }
        return string
    }

    static func prettyPrint(_ string: String) -> String? {
        guard let data = string.data(using: .utf8) else { return nil }
        return prettyPrint(data)
    }
}
