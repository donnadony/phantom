import Foundation

public enum PhantomLogLevel: String, CaseIterable, Equatable, Sendable {
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"

    public var emoji: String {
        switch self {
        case .info: return "🔵"
        case .warning: return "🟡"
        case .error: return "🔴"
        }
    }
}

public final class PhantomLogger: ObservableObject {

    public static let shared = PhantomLogger()

    @Published public private(set) var events: [PhantomLogItem] = []

    private let queue = DispatchQueue(label: "com.phantom.logger")

    private init() {}

    public func log(_ level: PhantomLogLevel = .info, _ message: String, tag: String? = nil) {
        let item = PhantomLogItem(level: level, message: message, tag: tag)
        queue.async {
            DispatchQueue.main.async {
                self.events.insert(item, at: 0)
            }
        }
    }

    public func info(_ message: String, tag: String? = nil) {
        log(.info, message, tag: tag)
    }

    public func warn(_ message: String, tag: String? = nil) {
        log(.warning, message, tag: tag)
    }

    public func error(_ message: String, tag: String? = nil) {
        log(.error, message, tag: tag)
    }

    public func clearAll() {
        queue.async {
            DispatchQueue.main.async {
                self.events.removeAll()
            }
        }
    }
}
