import SwiftUI

/// A simple placeholder view used when a list or section has no
/// content.  Displays an icon and a message to the user.
struct EmptyStateView: View {
    let title: String
    let message: String?
    let suggestion: String?
    let systemImage: String

    init(
        title: String,
        message: String? = nil,
        suggestion: String? = nil,
        systemImage: String = "tray"
    ) {
        self.title = title
        self.message = message
        self.suggestion = suggestion
        self.systemImage = systemImage
    }

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(AppColors.accent)

            Text(title)
                .font(AppTypography.headline)
                .multilineTextAlignment(.center)

            if let message, !message.isEmpty {
                Text(message)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.secondary)
                    .multilineTextAlignment(.center)
            }

            if let suggestion, !suggestion.isEmpty {
                Text(suggestion)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.primary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.xl)
    }
}
