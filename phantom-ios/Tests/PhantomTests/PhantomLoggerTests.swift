import Testing
import Foundation
@testable import Phantom

@Suite("PhantomLogger Tests")
struct PhantomLoggerTests {

    @Test("log level raw values are correct")
    func logLevelRawValues() {
        #expect(PhantomLogLevel.info.rawValue == "INFO")
        #expect(PhantomLogLevel.warning.rawValue == "WARN")
        #expect(PhantomLogLevel.error.rawValue == "ERROR")
    }

    @Test("log level emoji values are correct")
    func logLevelEmoji() {
        #expect(PhantomLogLevel.info.emoji == "🔵")
        #expect(PhantomLogLevel.warning.emoji == "🟡")
        #expect(PhantomLogLevel.error.emoji == "🔴")
    }

    @Test("all log levels are iterable")
    func allCases() {
        #expect(PhantomLogLevel.allCases.count == 3)
    }

    @Test("PhantomLogItem has correct properties")
    func logItemProperties() {
        let item = PhantomLogItem(level: .error, message: "Test error", tag: "Auth")
        #expect(item.level == .error)
        #expect(item.message == "Test error")
        #expect(item.tag == "Auth")
        #expect(item.id != UUID())
    }

    @Test("PhantomLogItem without tag has nil tag")
    func logItemNilTag() {
        let item = PhantomLogItem(level: .info, message: "No tag", tag: nil)
        #expect(item.tag == nil)
    }
}
