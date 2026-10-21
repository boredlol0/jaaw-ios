import SwiftUI

// MARK: - Live Activity palette
// The widget extension can't see the app's theme, so the colours the Live
// Activity needs live here.

enum LiveActivityPalette {
    /// The lock screen field.
    static let field = Color(red: 0, green: 0, blue: 0)
    /// The bar's fill, and the live dot in the island — the same green the
    /// app uses for a course that is going well.
    static let live = Color(red: 47 / 255, green: 214 / 255, blue: 156 / 255)
    /// The unfilled part of the bar.
    static let track = Color(red: 47 / 255, green: 214 / 255, blue: 156 / 255, opacity: 0.22)
    /// Primary type.
    static let ink = Color.white
    /// Secondary type.
    static let inkSoft = Color.white.opacity(0.62)
    /// Tertiary type — the room and faculty line.
    static let inkFaint = Color.white.opacity(0.45)
}
