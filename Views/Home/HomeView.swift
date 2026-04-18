import SwiftUI

/// Serves as the dashboard for the Food Journal app.  Shows recent
/// entries, top dishes and suggestions for restaurants to revisit.
struct HomeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            Group {
                if appState.entries.isEmpty {
                    EmptyStateView(
                        title: "Start your food journal",
                        message: "Home will surface recent entries, top dishes, and revisit ideas once you log a few meals.",
                        suggestion: "Add your first entry from the Journal tab to build your history.",
                        systemImage: "house"
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppSpacing.lg) {
                            recentEntriesSection
                            topDishesSection
                            revisitSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Home")
        }
    }

    private var recentEntriesSection: some View {
        CardView {
            Text("Recent Entries")
                .font(AppTypography.headline)
            ForEach(appState.entries.sorted(by: { $0.date > $1.date }).prefix(3)) { entry in
                let restaurant = entry.restaurantId.flatMap { id in appState.restaurants.first(where: { $0.id == id }) }
                let dish = entry.dishId.flatMap { id in appState.dishes.first(where: { $0.id == id }) }
                NavigationLink {
                    EntryDetailView(entryID: entry.id)
                } label: {
                    EntryRow(entry: entry, restaurant: restaurant, dish: dish)
                        .padding(.vertical, AppSpacing.sm)
                }
            }
        }
    }

    private var topDishesSection: some View {
        let top = AnalyticsService.topRatedDishes(entries: appState.entries, dishes: appState.dishes, limit: 3)
        return Group {
            if !top.isEmpty {
                CardView {
                    Text("Top Dishes")
                        .font(AppTypography.headline)
                    ForEach(top, id: \.dish.id) { pair in
                        let dish = pair.dish
                        NavigationLink {
                            DishDetailView(dishID: dish.id)
                        } label: {
                            DishRow(dish: dish, entries: appState.entries)
                        }
                    }
                }
            }
        }
    }

    private var revisitSection: some View {
        let suggestions = AnalyticsService.revisitSuggestions(entries: appState.entries, restaurants: appState.restaurants, limit: 3)
        return Group {
            if !suggestions.isEmpty {
                CardView {
                    Text("Revisit Suggestions")
                        .font(AppTypography.headline)
                    ForEach(suggestions, id: \.restaurant.id) { suggestion in
                        let restaurant = suggestion.restaurant
                        NavigationLink {
                            RestaurantDetailView(restaurantID: restaurant.id)
                        } label: {
                            RestaurantRow(restaurant: restaurant, entries: appState.entries)
                        }
                    }
                }
            }
        }
    }
}
