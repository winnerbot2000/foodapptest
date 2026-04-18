import SwiftUI

struct ItemHistoryDetailView: View {
    @EnvironmentObject private var appState: AppState

    let summary: LoggedItemSummary

    private var entries: [FoodEntry] {
        summary.entryIDs
            .compactMap(appState.entry(for:))
            .sorted(by: { $0.date > $1.date })
    }

    var body: some View {
        Group {
            if entries.isEmpty {
                EmptyStateView(
                    title: "No matching history",
                    message: "The saved browse result no longer has any entries attached to it.",
                    suggestion: "Add a new entry to keep tracking this item.",
                    systemImage: summary.itemType.systemImage
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        headerSection
                        statsSection

                        Text("History")
                            .font(AppTypography.headline)

                        ForEach(entries) { entry in
                            NavigationLink {
                                EntryDetailView(entryID: entry.id)
                            } label: {
                                EntryRow(
                                    entry: entry,
                                    restaurant: entry.restaurantId.flatMap(appState.restaurant(for:)),
                                    dish: entry.dishId.flatMap(appState.dish(for:))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(summary.itemType.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            if let photoReference = summary.photoReference {
                LocalPhotoThumbnailView(reference: photoReference, size: 72, cornerRadius: 18)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(summary.name)
                    .font(AppTypography.title)

                if let subtitle = summary.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.secondary)
                }

                Label(summary.itemType.displayName, systemImage: summary.itemType.systemImage)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.primary)
            }
        }
    }

    private var statsSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                statLine(title: "Times Logged", value: "\(summary.logCount)")
                statLine(title: "Best Overall", value: "\(summary.bestOverallRating)/10")
                if summary.averageOverallRating > 0 {
                    statLine(title: "Average Overall", value: String(format: "%.1f/10", summary.averageOverallRating))
                }
                if summary.restaurantCount > 0 {
                    statLine(title: "Restaurants", value: "\(summary.restaurantCount)")
                }
                if let lastTried = summary.lastTried {
                    statLine(title: "Last Tried", value: lastTried.formatted(date: .abbreviated, time: .omitted))
                }
            }
        }
    }

    private func statLine(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(AppTypography.body)
            Spacer()
            Text(value)
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.primary)
        }
    }
}
