import SwiftUI

/// A row representing a dish in a list.  Shows the name, category,
/// average rating, wish list status and whether the dish has a
/// designated best entry.  Uses icons to convey status.
struct DishRow: View {
    let dish: Dish
    let entries: [FoodEntry]
    var summary: LoggedItemSummary? = nil

    private var averageRating: Double {
        if let summary {
            return summary.averageOverallRating
        }

        let relevant = entries.filter { $0.dishId == dish.id }
        guard !relevant.isEmpty else { return 0 }
        let total = relevant.reduce(0.0) { $0 + Double($1.ratings.overall) }
        return total / Double(relevant.count)
    }

    private var logCount: Int {
        summary?.logCount ?? entries.filter { $0.dishId == dish.id }.count
    }

    private var restaurantCount: Int {
        summary?.restaurantCount ?? Set(entries.filter { $0.dishId == dish.id }.compactMap(\.restaurantId)).count
    }

    private var lastTried: Date? {
        summary?.lastTried ?? entries.filter { $0.dishId == dish.id }.map(\.date).max()
    }

    private var photoReference: PhotoReference? {
        dish.photoReferences.first ?? summary?.photoReference
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            if let photoReference {
                LocalPhotoThumbnailView(reference: photoReference, size: 60, cornerRadius: 16)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(dish.name)
                    .font(AppTypography.headline)

                Text(dish.category.displayName)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondary)

                HStack(spacing: AppSpacing.sm) {
                    Text("\(logCount) log\(logCount == 1 ? "" : "s")")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondary)

                    if restaurantCount > 0 {
                        Text("\(restaurantCount) place\(restaurantCount == 1 ? "" : "s")")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondary)
                    }
                }

                if let lastTried {
                    Text("Last tried \(lastTried.formatted(date: .abbreviated, time: .omitted))")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondary)
                }

                if averageRating > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(AppColors.primary)
                        Text(String(format: "%.1f", averageRating))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            Spacer()

            if dish.wishlist {
                Image(systemName: "bookmark.fill")
                    .foregroundColor(AppColors.wishlist)
            }
            if dish.bestEntryId != nil {
                Image(systemName: "crown.fill")
                    .foregroundColor(AppColors.highlight)
            }
        }
        .padding(.vertical, AppSpacing.sm)
    }
}
