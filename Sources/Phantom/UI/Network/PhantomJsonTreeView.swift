import SwiftUI

struct PhantomJsonTreeView: View {

    @Environment(\.phantomTheme) private var theme
    let jsonString: String

    var body: some View {
        if let data = jsonString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) {
            PhantomJsonNodeView(key: "JSON", value: json, isRoot: true)
        } else {
            Text(jsonString)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(theme.onBackground)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct PhantomJsonNodeView: View {

    @Environment(\.phantomTheme) private var theme
    let key: String
    let value: Any
    let isRoot: Bool

    @State private var isExpanded: Bool = true

    var body: some View {
        switch categorize(value) {
        case .dictionary(let dict):
            dictionaryView(dict)
        case .array(let arr):
            arrayView(arr)
        case .stringValue(let str):
            leafRow(icon: "■", iconColor: theme.jsonString, displayValue: "\"\(str)\"")
        case .numberValue(let num):
            leafRow(icon: "■", iconColor: theme.jsonNumber, displayValue: "\(num)")
        case .boolValue(let val):
            leafRow(icon: "■", iconColor: theme.jsonBoolean, displayValue: val ? "true" : "false")
        case .nullValue:
            leafRow(icon: "■", iconColor: theme.jsonNull, displayValue: "null")
        }
    }

    @ViewBuilder
    private func dictionaryView(_ dict: [(String, Any)]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { isExpanded.toggle() }) {
                HStack(spacing: 4) {
                    Text(isExpanded ? "⊟" : "⊞")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(theme.onBackgroundVariant)
                    Text("{}")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(theme.onBackgroundVariant)
                    Text(key)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(theme.onBackground)
                    if !isExpanded {
                        Text("(\(dict.count))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(theme.onBackgroundVariant)
                    }
                }
            }
            .buttonStyle(.plain)
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(dict.enumerated()), id: \.offset) { _, entry in
                        PhantomJsonNodeView(key: entry.0, value: entry.1, isRoot: false)
                    }
                }
                .padding(.leading, 16)
            }
        }
    }

    @ViewBuilder
    private func arrayView(_ arr: [Any]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { isExpanded.toggle() }) {
                HStack(spacing: 4) {
                    Text(isExpanded ? "⊟" : "⊞")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(theme.onBackgroundVariant)
                    Text("[]")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(theme.onBackgroundVariant)
                    Text(key)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(theme.onBackground)
                    Text("[\(arr.count)]")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(theme.onBackgroundVariant)
                }
            }
            .buttonStyle(.plain)
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(arr.enumerated()), id: \.offset) { index, element in
                        PhantomJsonNodeView(key: "[\(index)]", value: element, isRoot: false)
                    }
                }
                .padding(.leading, 16)
            }
        }
    }

    @ViewBuilder
    private func leafRow(icon: String, iconColor: Color, displayValue: String) -> some View {
        HStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 6))
                .foregroundStyle(iconColor)
            Text(key)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(theme.onBackground)
            Text(":")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(theme.onBackgroundVariant)
            Text(displayValue)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(valueColor(displayValue))
                .lineLimit(3)
        }
        .padding(.vertical, 1)
    }

    private func valueColor(_ value: String) -> Color {
        if value.hasPrefix("\"") { return theme.jsonString }
        if value == "true" || value == "false" { return theme.jsonBoolean }
        if value == "null" { return theme.jsonNull }
        return theme.jsonNumber
    }

    private enum JsonCategory {
        case dictionary([(String, Any)])
        case array([Any])
        case stringValue(String)
        case numberValue(NSNumber)
        case boolValue(Bool)
        case nullValue
    }

    private func categorize(_ value: Any) -> JsonCategory {
        if let dict = value as? [String: Any] {
            let sorted = dict.sorted { $0.key < $1.key }
            return .dictionary(sorted)
        }
        if let arr = value as? [Any] {
            return .array(arr)
        }
        if let num = value as? NSNumber {
            if CFBooleanGetTypeID() == CFGetTypeID(num) {
                return .boolValue(num.boolValue)
            }
            return .numberValue(num)
        }
        if let str = value as? String {
            return .stringValue(str)
        }
        if value is NSNull {
            return .nullValue
        }
        return .stringValue("\(value)")
    }
}
