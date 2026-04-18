import SwiftUI

/// Provides typographic styles used throughout the Food Journal app.
/// Centralising font definitions makes it easy to adjust the
/// typography scale and weight across the entire interface.
struct AppTypography {
    /// Large title used for prominent headings.
    static let largeTitle = Font.system(size: 34, weight: .bold)
    /// Primary title used in detail views and section headers.
    static let title = Font.system(size: 28, weight: .bold)
    /// Headline used for card titles and subsection headings.
    static let headline = Font.system(size: 20, weight: .semibold)
    /// Body text used for main reading content.
    static let body = Font.system(size: 16, weight: .regular)
    /// Subheadline used for secondary labels.
    static let subheadline = Font.system(size: 14, weight: .regular)
    /// Caption used for small annotations and tags.
    static let caption = Font.system(size: 12, weight: .regular)
}