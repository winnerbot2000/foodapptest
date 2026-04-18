import SwiftUI

/// Shows detailed information about a single restaurant including
/// cuisine tags, notes and a list of associated entries.  Users can
/// toggle favourite and wish list status.
struct RestaurantDetailView: View {
    @EnvironmentObject private var appState: AppState
    let restaurantID: UUID
    @State private var showEditRestaurant = false

    private var restaurant: Restaurant? {
        appState.restaurant(for: restaurantID)
    }

    var body: some View {
        Group {
            if let restaurant {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        headerSection(restaurant: restaurant)
                        cuisineSection(restaurant: restaurant)
                        notesSection(restaurant: restaurant)
                        photosSection(restaurant: restaurant)
                        visitsSection(restaurant: restaurant)
                        entriesSection(restaurant: restaurant)
                    }
                    .padding()
                }
            } else {
                EmptyStateView(title: "Restaurant not found", systemImage: "fork.knife")
            }
        }
        .navigationTitle("Restaurant")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if restaurant != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showEditRestaurant = true
                    }
                }
            }
        }
        .sheet(isPresented: $showEditRestaurant) {
            if let restaurant {
                AddRestaurantView(restaurant: restaurant)
                    .environmentObject(appState)
            }
        }
    }

    private func headerSection(restaurant: Restaurant) -> some View {
        HStack {
            Text(restaurant.name)
                .font(AppTypography.title)
            Spacer()
            Button(action: toggleFavourite) {
                Image(systemName: restaurant.favorite ? "heart.fill" : "heart")
                    .foregroundColor(AppColors.favorite)
            }
            Button(action: toggleWishlist) {
                Image(systemName: restaurant.wishlist ? "bookmark.fill" : "bookmark")
                    .foregroundColor(AppColors.wishlist)
            }
        }
    }

    private func cuisineSection(restaurant: Restaurant) -> some View {
        Group {
            if !restaurant.locationText.isEmpty {
                Label(restaurant.locationText, systemImage: "mappin.and.ellipse")
                    .foregroundColor(AppColors.secondary)
                    .font(AppTypography.body)
            }
            if !restaurant.cuisineTags.isEmpty {
                TagListView(tags: restaurant.cuisineTags)
            }
        }
    }

    private func notesSection(restaurant: Restaurant) -> some View {
        Group {
            if let notes = restaurant.notes, !notes.isEmpty {
                Text("Notes")
                    .font(AppTypography.headline)
                Text(notes)
                    .font(AppTypography.body)
            }
        }
    }

    private func photosSection(restaurant: Restaurant) -> some View {
        PhotoGallerySection(
            title: "Photos",
            photoReferences: restaurant.photoReferences,
            emptyStateText: "No photos attached to this restaurant."
        )
    }

    private func entriesSection(restaurant: Restaurant) -> some View {
        let restaurantEntries = appState.entries.filter { $0.restaurantId == restaurant.id }
        return Group {
            if restaurantEntries.isEmpty {
                EmptyStateView(title: "No entries yet", systemImage: "tray")
            } else {
                Text("Entries")
                    .font(AppTypography.headline)
                ForEach(restaurantEntries.sorted(by: { $0.date > $1.date })) { entry in
                    let dish = entry.dishId.flatMap { id in appState.dishes.first(where: { $0.id == id }) }
                    NavigationLink {
                        EntryDetailView(entryID: entry.id)
                    } label: {
                        EntryRow(entry: entry, restaurant: restaurant, dish: dish)
                    }
                }
            }
        }
    }

    private func visitsSection(restaurant: Restaurant) -> some View {
        let visits = appState.visits(for: restaurant.id)
        return Group {
            if !visits.isEmpty {
                Text("Visits")
                    .font(AppTypography.headline)

                ForEach(visits) { visit in
                    CardView {
                        HStack {
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text(visit.date, style: .date)
                                    .font(AppTypography.body)
                                if let placeName = visit.placeName, !placeName.isEmpty {
                                    Text(placeName)
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.secondary)
                                }
                            }
                            Spacer()
                            Text("\(visit.itemCount) item\(visit.itemCount == 1 ? "" : "s")")
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.primary)
                        }
                    }
                }
            }
        }
    }

    private func toggleFavourite() {
        guard var restaurant else { return }
        restaurant.favorite.toggle()
        appState.updateRestaurant(restaurant)
    }

    private func toggleWishlist() {
        guard var restaurant else { return }
        restaurant.wishlist.toggle()
        appState.updateRestaurant(restaurant)
    }
}
