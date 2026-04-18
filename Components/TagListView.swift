import SwiftUI

/// Displays a list of tags horizontally inside a scroll view.  Tags
/// wrap gracefully when there are many and use capsules for
/// styling.  If there are no tags the view collapses to zero height.
struct TagListView: View {
    let tags: [String]

    init(tags: [String]) {
        self.tags = tags
    }

    var body: some View {
        if tags.isEmpty {
            EmptyView()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(AppTypography.caption)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(AppColors.accent.opacity(0.2))
                            .foregroundColor(AppColors.accent)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}