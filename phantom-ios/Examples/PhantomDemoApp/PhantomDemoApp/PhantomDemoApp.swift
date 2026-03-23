import SwiftUI
import Phantom

@main
struct PhantomDemoApp: App {

    init() {
        seedDemoData()
    }

    var body: some Scene {
        WindowGroup {
            PhantomView()
                .environment(\.phantomTheme, Phantom.theme)
        }
    }

    private func seedDemoData() {
        Phantom.registerConfig(
            "API Base URL",
            key: "api_base_url",
            defaultValue: "https://api.example.com"
        )
        Phantom.registerConfig(
            "Environment",
            key: "env",
            defaultValue: "production",
            type: .picker,
            options: ["production", "staging", "development"]
        )
        Phantom.registerConfig(
            "Dark Mode",
            key: "dark_mode",
            defaultValue: "false",
            type: .toggle
        )

        Phantom.log(.info, "App launched", tag: "Lifecycle")
        Phantom.log(.info, "User session restored", tag: "Auth")
        Phantom.log(.warning, "Token expires in 5 minutes", tag: "Auth")
        Phantom.log(.error, "Failed to load cached data", tag: "Storage")
        Phantom.log(.info, "Home screen loaded", tag: "Navigation")

        seedNetworkLogs()
    }

    private func seedNetworkLogs() {
        let usersURL = URL(string: "https://api.example.com/v1/users")!
        var usersRequest = URLRequest(url: usersURL)
        usersRequest.httpMethod = "GET"
        usersRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        usersRequest.setValue("Bearer token123", forHTTPHeaderField: "Authorization")
        Phantom.logRequest(usersRequest)
        Phantom.logResponse(
            url: usersURL,
            methodType: "GET",
            headers: "Content-Type: application/json",
            body: """
            [
              {"id": 1, "name": "Alice", "email": "alice@example.com", "active": true},
              {"id": 2, "name": "Bob", "email": "bob@example.com", "active": false}
            ]
            """,
            statusCode: 200
        )

        let loginURL = URL(string: "https://api.example.com/v1/auth/login")!
        var loginRequest = URLRequest(url: loginURL)
        loginRequest.httpMethod = "POST"
        loginRequest.httpBody = """
        {"email": "alice@example.com", "password": "***"}
        """.data(using: .utf8)
        loginRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        Phantom.logRequest(loginRequest)
        Phantom.logResponse(
            url: loginURL,
            methodType: "POST",
            headers: "Content-Type: application/json",
            body: """
            {"token": "eyJhbGciOiJIUzI1NiIs...", "expiresIn": 3600, "refreshToken": "rf_abc123"}
            """,
            statusCode: 200
        )

        let errorURL = URL(string: "https://api.example.com/v1/orders/999")!
        var errorRequest = URLRequest(url: errorURL)
        errorRequest.httpMethod = "GET"
        Phantom.logRequest(errorRequest)
        Phantom.logResponse(
            url: errorURL,
            methodType: "GET",
            headers: "Content-Type: application/json",
            body: """
            {"error": "Not Found", "message": "Order 999 does not exist"}
            """,
            statusCode: 404
        )
    }
}
