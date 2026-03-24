import Foundation
import SwiftUI

public enum Phantom {

    // MARK: - Theme

    public static var theme: PhantomTheme = .kodivex

    public static func setTheme(_ theme: PhantomTheme) {
        self.theme = theme
    }

    // MARK: - App Logging

    public static func log(_ level: PhantomLogLevel = .info, _ message: String, tag: String? = nil) {
        PhantomLogger.shared.log(level, message, tag: tag)
    }

    // MARK: - Network Logging

    public static func logRequest(_ urlRequest: URLRequest) {
        PhantomNetworkLogger.shared.logRequest(urlRequest)
    }

    public static func logResponse(for urlRequest: URLRequest, body: Data?) {
        PhantomNetworkLogger.shared.logResponse(for: urlRequest, body: body)
    }

    public static func logResponse(for urlRequest: URLRequest, errorMessage: String) {
        PhantomNetworkLogger.shared.logResponse(for: urlRequest, errorMessage: errorMessage)
    }

    public static func logResponse(
        url: URL?,
        methodType: String,
        headers: String,
        body: String,
        statusCode: Int?
    ) {
        PhantomNetworkLogger.shared.logResponse(
            url: url,
            methodType: methodType,
            headers: headers,
            body: body,
            statusCode: statusCode
        )
    }

    public static func updateResponseMetadata(url: URL?, headers: String, statusCode: Int?) {
        PhantomNetworkLogger.shared.updateResponseMetadata(url: url, headers: headers, statusCode: statusCode)
    }

    public static func logExternalEntry(_ jsonString: String, sourcePrefix: String = "[External]") {
        PhantomNetworkLogger.shared.logExternalEntry(jsonString, sourcePrefix: sourcePrefix)
    }

    // MARK: - Mock Interceptor

    public static func mockResponse(for request: URLRequest) -> (Data, HTTPURLResponse)? {
        PhantomMockInterceptor.shared.mockResponse(for: request)
    }

    // MARK: - Mock Import / Export

    @discardableResult
    public static func loadMocks(from fileName: String, in bundle: Bundle = .main) -> Bool {
        PhantomMockInterceptor.shared.loadMocks(from: fileName, in: bundle)
    }

    @discardableResult
    public static func loadMocks(from url: URL) -> Bool {
        PhantomMockInterceptor.shared.loadMocks(from: url)
    }

    @discardableResult
    public static func loadMocks(from data: Data) -> Bool {
        PhantomMockInterceptor.shared.loadMocks(from: data)
    }

    public static func exportMocks(name: String = "Phantom Mocks", description: String = "") -> Data? {
        PhantomMockInterceptor.shared.exportCollection(name: name, description: description)
    }

    // MARK: - Configuration

    public static func registerConfig(
        _ label: String,
        key: String,
        defaultValue: String,
        type: PhantomConfigType = .text,
        options: [String] = [],
        group: String = "General"
    ) {
        PhantomConfig.shared.register(label, key: key, defaultValue: defaultValue, type: type, options: options, group: group)
    }

    public static func config(_ key: String) -> String? {
        PhantomConfig.shared.effectiveValue(for: key)
    }

    public static func setConfig(_ key: String, value: String?) {
        PhantomConfig.shared.setValue(value, for: key)
    }

    // MARK: - Localization

    public static func registerLocalization(
        key: String,
        english: String,
        spanish: String,
        group: String = "General"
    ) {
        PhantomLocalizer.shared.register(key: key, english: english, spanish: spanish, group: group)
    }

    public static func localized(_ key: String, group: String? = nil) -> String {
        PhantomLocalizer.shared.localized(key, group: group)
    }

    public static func setLanguage(_ language: PhantomLanguage) {
        PhantomLocalizer.shared.setLanguage(language)
    }

    public static var currentLanguage: PhantomLanguage {
        PhantomLocalizer.shared.currentLanguage
    }

    // MARK: - Presentation

    public static func view() -> some View {
        PhantomView()
            .environment(\.phantomTheme, theme)
    }
}
