import SwiftUI

/// A row representing a restaurant in a list.  Shows the name,
/// location, average overall rating, visit count and icons for
/// favourite and wish list status.
struct RestaurantRow: View {
    let restaurant: Restaurant
    let entries: [FoodEntry]
    var summary: RestaurantBrowseSummary? = nil

    private var averageRating: Double {
        if let summary {
            return summary.averageOverallRating
        }

        let relevant = entries.filter { $0.restaurantId == restaurant.id }
        guard !relevant.isEmpty else { return 0 }
        let total = relevant.reduce(0.0) { $0 + Double($1.ratings.overall) }
        return total / Double(relevant.count)
    }

    private var itemCount: Int {
        summary?.itemCount ?? entries.filter { $0.restaurantId == restaurant.id }.count
    }

    private var visitCount: Int {
        summary?.visitCount ?? Set(entries.filter { $0.restaurantId == restaurant.id }.compactMap(\.visitId)).count
    }

    private var lastVisitDate: Date? {
        summary?.lastVisitDate ?? entries.filter { $0.restaurantId == restaurant.id }.map(\.date).max()
    }

    private var bestItemName: String? {
        summary?.bestItemName
    }

    private var photoReference: PhotoReference? {
        restaurant.photoReferences.first ?? summary?.photoReference
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            if let photoReference {
                LocalPhotoThumbnailView(reference: photoReference, size: 60, cornerRadius: 16)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(restaurant.name)
                    .font(AppTypography.headline)

                if !restaurant.locationText.isEmpty {
                    Text(restaurant.locationText)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondary)
                }

                HStack(spacing: AppSpacing.sm) {
                    Text("\(visitCount) visit\(visitCount == 1 ? "" : "s")")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondary)

                    Text("\(itemCount) item\(itemCount == 1 ? "" : "s")")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondary)
                }

                if let lastVisitDate {
                    Text("Last visit \(lastVisitDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondary)
                }

                if let bestItemName, !bestItemName.isEmpty {
                    Text("Top item: \(bestItemName)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondary)
                        .lineLimit(1)
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
            if restaurant.favorite {
                Image(systemName: "heart.fill")
                    .foregroundColor(AppColors.favorite)
            }
            if restaurant.wishlist {
                Image(systemName: "bookmark.fill")
                    .foregroundColor(AppColors.wishlist)
            }
        }
        .padding(.vertical, AppSpacing.sm)
    }
}
