# Phantom

Cross-platform debug toolkit for mobile apps.

[![iOS](https://img.shields.io/badge/iOS-15%2B-blue)](phantom-ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)](phantom-ios/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

## Features

- **Logs** - App-level logging with levels (info, warning, error) and tag filtering
- **Network Inspector** - Capture and inspect HTTP requests/responses with JSON tree viewer
- **Mock Services** - Intercept network requests and return mock responses at runtime
- **Configuration** - Generic key-value override system for runtime config changes

## Platforms

| Platform | Status | Package |
|----------|--------|---------|
| iOS (Swift) | Available | `phantom-ios/` |
| Flutter | Planned | `phantom-flutter/` |
| Android (Kotlin) | Planned | `phantom-android/` |

## iOS - Quick Start

### Installation

Add `phantom-ios/` as a local Swift Package or via SPM:

```swift
.package(url: "https://github.com/donnadony/phantom.git", from: "0.0.1")
```

### Usage

```swift
import Phantom

// App logging
Phantom.log(.info, "User logged in", tag: "Auth")
Phantom.log(.error, "Failed to fetch data", tag: "API")

// Network logging - hook into your network layer
Phantom.logRequest(urlRequest)
Phantom.logResponse(for: urlRequest, body: responseData)

// Mock interceptor - check before making real request
if let (data, response) = Phantom.mockResponse(for: urlRequest) {
    // Return mock data instead of hitting the network
}

// Config overrides
Phantom.registerConfig("API Base URL", key: "api_base_url", defaultValue: "https://prod.api.com")
let url = Phantom.config("api_base_url") ?? defaultUrl

// Show debug panel
Phantom.view()
```

## Architecture

```
Phantom/
├── phantom-ios/           Swift Package (iOS 15+)
│   ├── Sources/Phantom/
│   │   ├── Core/          Platform-agnostic logic
│   │   ├── UI/            SwiftUI views
│   │   └── Extensions/    Internal helpers
│   └── Tests/
├── phantom-flutter/       Flutter package (planned)
└── phantom-android/       Kotlin module (planned)
```

## License

MIT
