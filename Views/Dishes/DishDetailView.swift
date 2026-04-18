import SwiftUI

/// Shows detailed information about a single dish including category,
/// subcategory, notes, the best recorded entry and a list of
/// associated entries.  Users can toggle the wish list status.
struct DishDetailView: View {
    @EnvironmentObject private var appState: AppState
    let dishID: UUID
    @State private var showEditDish = false

    private var dish: Dish? {
        appState.dish(for: dishID)
    }

    var body: some View {
        Group {
            if let dish {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        headerSection(dish: dish)
                        notesSection(dish: dish)
                        photosSection(dish: dish)
                        bestEntrySection(dish: dish)
                        entriesSection(dish: dish)
                    }
                    .padding()
                }
            } else {
                EmptyStateView(title: "Dish not found", systemImage: "fork.knife")
            }
        }
        .navigationTitle("Dish")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if dish != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showEditDish = true
                    }
                }
            }
        }
        .sheet(isPresented: $showEditDish) {
            if let dish {
                AddDishView(dish: dish)
                    .environmentObject(appState)
            }
        }
    }

    private func headerSection(dish: Dish) -> some View {
        HStack {
            Text(dish.name)
                .font(AppTypography.title)
            Spacer()
            Button(action: toggleWishlist) {
                Image(systemName: dish.wishlist ? "bookmark.fill" : "bookmark")
                    .foregroundColor(AppColors.wishlist)
            }
        }
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(dish.category.displayName)
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.secondary)
            if let sub = dish.subcategory, !sub.isEmpty {
                Text(sub)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.secondary)
            }
        }
    }

    private func notesSection(dish: Dish) -> some View {
        Group {
            if let notes = dish.notes, !notes.isEmpty {
                Text("Notes")
                    .font(AppTypography.headline)
                Text(notes)
                    .font(AppTypography.body)
            }
        }
    }

    private func photosSection(dish: Dish) -> some View {
        PhotoGallerySection(
            title: "Photos",
            photoReferences: dish.photoReferences,
            emptyStateText: "No photos attached to this dish."
        )
    }

    private func bestEntrySection(dish: Dish) -> some View {
        Group {
            if let bestId = dish.bestEntryId, let bestEntry = appState.entries.first(where: { $0.id == bestId }) {
                Text("Best Version")
                    .font(AppTypography.headline)
                let restaurant = bestEntry.restaurantId.flatMap { id in appState.restaurants.first(where: { $0.id == id }) }
                NavigationLink {
                    EntryDetailView(entryID: bestEntry.id)
                } label: {
                    EntryRow(entry: bestEntry, restaurant: restaurant, dish: dish)
                }
            }
        }
    }

    private func entriesSection(dish: Dish) -> some View {
        let dishEntries = appState.entries.filter { $0.dishId == dish.id }
        return Group {
            if dishEntries.isEmpty {
                EmptyStateView(title: "No entries yet", systemImage: "tray")
            } else {
                Text("Entries")
                    .font(AppTypography.headline)
                ForEach(dishEntries.sorted(by: { $0.date > $1.date })) { entry in
                    let restaurant = entry.restaurantId.flatMap { id in appState.restaurants.first(where: { $0.id == id }) }
                    NavigationLink {
                        EntryDetailView(entryID: entry.id)
                    } label: {
                        EntryRow(entry: entry, restaurant: restaurant, dish: dish)
                    }
                }
            }
        }
    }

    private func toggleWishlist() {
        guard var dish else { return }
        dish.wishlist.toggle()
        appState.updateDish(dish)
    }
}
