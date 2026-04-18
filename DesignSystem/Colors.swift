import SwiftUI

/// Defines colour tokens for the Food Journal app. Use these values
/// consistently throughout the app to maintain a cohesive look and
/// feel. Colours are chosen to evoke a warm, premium food diary
/// experience. Modify these values to tune the look of the app.
struct AppColors {
    /// Base background for pages and lists.
    static let background = Color(.systemBackground)
    /// Background colour for cards and grouped content.
    static let cardBackground = Color(.secondarySystemBackground)
    /// Primary accent used for interactive elements.
    static let primary = Color.accentColor
    /// Secondary accent used for secondary text.
    static let secondary = Color(.secondaryLabel)
    /// Additional accent colour for tags and highlights.
    static let accent = Color.orange
    /// Colour indicating favourite items.
    static let favorite = Color.red
    /// Colour indicating wish list items.
    static let wishlist = Color.purple
    /// Colour used for highlighting the best version of a dish or entry.
    static let highlight = Color.yellow
}