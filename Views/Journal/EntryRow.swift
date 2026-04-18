import SwiftUI

/// A row representing a single food entry in a list.  Shows the dish
/// or item name, its type, place, date and overall rating.
struct EntryRow: View {
    let entry: FoodEntry
    let restaurant: Restaurant?
    let dish: Dish?

    private var branchText: String? {
        let trimmedPlace = entry.place?.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? entry.placeName?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let trimmedPlace, !trimmedPlace.isEmpty else {
            return nil
        }

        if let restaurant,
           trimmedPlace.caseInsensitiveCompare(restaurant.name) == .orderedSame {
            return entry.place?.secondaryText
        }

        return trimmedPlace
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            if let photoReference = entry.photoReferences.first {
                LocalPhotoThumbnailView(reference: photoReference, size: 64, cornerRadius: 16)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                    Image(systemName: entry.itemType.systemImage)
                        .foregroundColor(AppColors.primary)
                }
                .frame(width: 64, height: 64)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(dish?.name ?? entry.customDishName ?? "Unknown Item")
                    .font(AppTypography.headline)
                    .lineLimit(2)

                HStack(spacing: AppSpacing.sm) {
                    Label(entry.itemType.displayName, systemImage: entry.itemType.systemImage)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.primary)

                    if !entry.photoReferences.isEmpty {
                        Label("\(entry.photoReferences.count)", systemImage: "photo")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondary)
                    }

                    if let restaurant = restaurant {
                        if let branchText, !branchText.isEmpty {
                            Text("\(restaurant.name) • \(branchText)")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondary)
                        } else {
                            Text(restaurant.name)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondary)
                        }
                    } else if let branchText, !branchText.isEmpty {
                        Text(branchText)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondary)
                    }
                }

                HStack(spacing: AppSpacing.sm) {
                    Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondary)

                    if entry.ratings.taste > 0 {
                        Text("Taste \(entry.ratings.taste)/10")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                Text(String(format: "%.1f", Double(entry.ratings.overall)))
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.primary)

                Text("Overall")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondary)

                if entry.highlighted {
                    Image(systemName: "star.fill")
                        .foregroundColor(AppColors.favorite)
                }
            }
        }
        .padding(.vertical, AppSpacing.sm)
    }
}
