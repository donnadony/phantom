import SwiftUI

public struct PhantomTheme {

    // MARK: - Surface / Background

    public var background: Color
    public var surface: Color
    public var surfaceVariant: Color

    // MARK: - Text

    public var onBackground: Color
    public var onBackgroundVariant: Color
    public var onPrimary: Color

    // MARK: - Primary / Accent

    public var primary: Color
    public var primaryContainer: Color

    // MARK: - Semantic Status

    public var info: Color
    public var warning: Color
    public var error: Color
    public var success: Color

    // MARK: - Outline

    public var outline: Color
    public var outlineVariant: Color

    // MARK: - HTTP Methods

    public var httpGet: Color
    public var httpPost: Color
    public var httpPut: Color
    public var httpDelete: Color

    // MARK: - JSON Tree

    public var jsonString: Color
    public var jsonNumber: Color
    public var jsonBoolean: Color
    public var jsonNull: Color

    // MARK: - Kodivex Default

    public static let kodivex = PhantomTheme(
        background: Color(hex: "#0b1326"),
        surface: Color(hex: "#171f33"),
        surfaceVariant: Color(hex: "#222a3d"),
        onBackground: Color(hex: "#dae2fd"),
        onBackgroundVariant: Color(hex: "#cbc3d7"),
        onPrimary: Color(hex: "#3c0091"),
        primary: Color(hex: "#d0bcff"),
        primaryContainer: Color(hex: "#a078ff"),
        info: Color(hex: "#5de6ff"),
        warning: Color(hex: "#ffb869"),
        error: Color(hex: "#ffb4ab"),
        success: Color(hex: "#5de6ff"),
        outline: Color(hex: "#958ea0"),
        outlineVariant: Color(hex: "#494454"),
        httpGet: Color(hex: "#5de6ff"),
        httpPost: Color(hex: "#d0bcff"),
        httpPut: Color(hex: "#ffb869"),
        httpDelete: Color(hex: "#ffb4ab"),
        jsonString: Color(hex: "#5de6ff"),
        jsonNumber: Color(hex: "#d0bcff"),
        jsonBoolean: Color(hex: "#ffb869"),
        jsonNull: Color(hex: "#958ea0")
    )

    // MARK: - Init

    public init(
        background: Color = Color(hex: "#0b1326"),
        surface: Color = Color(hex: "#171f33"),
        surfaceVariant: Color = Color(hex: "#222a3d"),
        onBackground: Color = Color(hex: "#dae2fd"),
        onBackgroundVariant: Color = Color(hex: "#cbc3d7"),
        onPrimary: Color = Color(hex: "#3c0091"),
        primary: Color = Color(hex: "#d0bcff"),
        primaryContainer: Color = Color(hex: "#a078ff"),
        info: Color = Color(hex: "#5de6ff"),
        warning: Color = Color(hex: "#ffb869"),
        error: Color = Color(hex: "#ffb4ab"),
        success: Color = Color(hex: "#5de6ff"),
        outline: Color = Color(hex: "#958ea0"),
        outlineVariant: Color = Color(hex: "#494454"),
        httpGet: Color = Color(hex: "#5de6ff"),
        httpPost: Color = Color(hex: "#d0bcff"),
        httpPut: Color = Color(hex: "#ffb869"),
        httpDelete: Color = Color(hex: "#ffb4ab"),
        jsonString: Color = Color(hex: "#5de6ff"),
        jsonNumber: Color = Color(hex: "#d0bcff"),
        jsonBoolean: Color = Color(hex: "#ffb869"),
        jsonNull: Color = Color(hex: "#958ea0")
    ) {
        self.background = background
        self.surface = surface
        self.surfaceVariant = surfaceVariant
        self.onBackground = onBackground
        self.onBackgroundVariant = onBackgroundVariant
        self.onPrimary = onPrimary
        self.primary = primary
        self.primaryContainer = primaryContainer
        self.info = info
        self.warning = warning
        self.error = error
        self.success = success
        self.outline = outline
        self.outlineVariant = outlineVariant
        self.httpGet = httpGet
        self.httpPost = httpPost
        self.httpPut = httpPut
        self.httpDelete = httpDelete
        self.jsonString = jsonString
        self.jsonNumber = jsonNumber
        self.jsonBoolean = jsonBoolean
        self.jsonNull = jsonNull
    }
}
