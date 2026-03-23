# Phantom iOS

A debug toolkit for iOS apps. Inspect logs, network requests, mock API responses, and override configuration values — all from an in-app debug panel.

## Features

- **Logs** — App-level logging with levels (info, warning, error) and tags
- **Network** — Capture and inspect HTTP request/response pairs with JSON viewer
- **Mock Services** — Intercept requests and return mock responses by URL pattern
- **Configuration** — Register key-value overrides (text, toggle, picker) with persistence

## Requirements

- iOS 15.0+
- Swift 5.9+
- Xcode 15+

## Installation

### Swift Package Manager

Add Phantom to your project via Xcode:

1. Go to **File > Add Package Dependencies**
2. Enter the repository URL:

```
https://github.com/donnadony/phantom.git
```

3. Select the `phantom-ios` directory and add the `Phantom` library to your target

Or add it directly in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/donnadony/phantom.git", from: "0.0.1")
]
```

Then add `Phantom` to your target dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "Phantom", package: "phantom")
    ]
)
```

## Usage

Import the library:

```swift
import Phantom
```

### Logging

```swift
Phantom.log(.info, "User logged in", tag: "Auth")
Phantom.log(.warning, "Token expires soon", tag: "Auth")
Phantom.log(.error, "Request failed", tag: "Network")
```

### Network Logging

Log request/response pairs from your networking layer:

```swift
// Log outgoing request
Phantom.logRequest(urlRequest)

// Log response with data
Phantom.logResponse(for: urlRequest, body: responseData)

// Log response with error
Phantom.logResponse(for: urlRequest, errorMessage: "Connection timeout")
```

### Mock Interceptor

Check for mock responses before making real network calls:

```swift
if let (data, response) = Phantom.mockResponse(for: urlRequest) {
    // Use mock data
    return (data, response)
}
// Proceed with real request
```

Mock rules are created from the debug panel UI — tap "Mock this" on any network log entry, or create rules manually from the Mock Services tab.

### Configuration

Register configurable values at app startup:

```swift
Phantom.registerConfig("API Base URL", key: "api_url", defaultValue: "https://api.example.com")
Phantom.registerConfig("Environment", key: "env", defaultValue: "production", type: .picker, options: ["production", "staging", "development"])
Phantom.registerConfig("Dark Mode", key: "dark_mode", defaultValue: "false", type: .toggle)
```

Read config values anywhere in your app:

```swift
let baseURL = Phantom.config("api_url") ?? "https://api.example.com"
```

### Presenting the Debug Panel

Using the convenience method:

```swift
Phantom.view()
```

Or as a sheet:

```swift
struct ContentView: View {
    @State private var showDebug = false

    var body: some View {
        Button("Open Debug Panel") { showDebug = true }
            .sheet(isPresented: $showDebug) {
                Phantom.view()
            }
    }
}
```

The debug panel UI is only available in `DEBUG` builds.

### External Entries (WebView, Flutter Bridge)

Log network activity from non-native layers:

```swift
let json = """
{"url": "https://api.example.com/data", "method": "GET", "statusCode": 200, "responseBody": "{}"}
"""
Phantom.logExternalEntry(json, sourcePrefix: "[WebView]")
```

### Custom Theme

Override the default theme colors:

```swift
let customTheme = PhantomTheme(
    background: Color(hex: "#1a1a2e"),
    surface: Color(hex: "#16213e"),
    primary: Color(hex: "#e94560")
)
Phantom.setTheme(customTheme)
```

## License

MIT
