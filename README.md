# Phantom

Cross-platform debug toolkit for mobile apps.

[![iOS](https://img.shields.io/badge/iOS-15%2B-blue)](phantom-ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)](phantom-ios/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

## Screenshots

<p align="center">
  <img src="Screenshots/home.jpeg" width="200" />
  <img src="Screenshots/logs.jpeg" width="200" />
  <img src="Screenshots/network.jpeg" width="200" />
</p>
<p align="center">
  <img src="Screenshots/mock_list.jpeg" width="200" />
  <img src="Screenshots/mock_new.jpeg" width="200" />
  <img src="Screenshots/mock_edit.jpeg" width="200" />
</p>

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

### Theme Configuration

Phantom ships with a dark theme (Kodivex) by default. You can customize every color by providing a `PhantomTheme` before presenting the debug panel:

```swift
// Use the default Kodivex dark theme (no setup needed)
Phantom.view()

// Customize specific colors
let customTheme = PhantomTheme(
    background: Color(hex: "#1a1a2e"),
    surface: Color(hex: "#16213e"),
    primary: Color(hex: "#e94560"),
    tint: Color(hex: "#e94560"),
    inputBackground: Color(hex: "#0f3460")
)
Phantom.setTheme(customTheme)
```

All `PhantomTheme` properties have default values, so you only need to override the colors you want to change.

| Property | Description |
|----------|-------------|
| `background` | Main screen background |
| `surface` | Card and container backgrounds |
| `surfaceVariant` | Elevated surface backgrounds |
| `onBackground` | Primary text on background |
| `onBackgroundVariant` | Secondary/muted text |
| `onPrimary` | Text on primary-colored elements |
| `primary` | Accent color for buttons, links, selections |
| `primaryContainer` | Accent variant for filled containers |
| `tint` | Tint for interactive controls (toggles, pickers) |
| `inputBackground` | Background for text editors and input fields |
| `info` | Info-level log color |
| `warning` | Warning-level log / modified badge color |
| `error` | Error-level log / destructive action color |
| `success` | Success status color |
| `outline` | Border/divider color |
| `outlineVariant` | Subtle border color |
| `httpGet/Post/Put/Delete` | HTTP method badge colors |
| `jsonString/Number/Boolean/Null` | JSON tree viewer syntax colors |

## Architecture

```
Phantom/
├── phantom-ios/           Swift Package (iOS 15+, Swift 5.9+)
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
