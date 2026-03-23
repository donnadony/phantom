import SwiftUI

public struct PhantomThemeKey: EnvironmentKey {
    public static let defaultValue: PhantomTheme = .kodivex
}

public extension EnvironmentValues {

    var phantomTheme: PhantomTheme {
        get { self[PhantomThemeKey.self] }
        set { self[PhantomThemeKey.self] = newValue }
    }
}
