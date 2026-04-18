import SwiftUI

/// Presents personal analytics and insights based on the user’s data.
/// Displays category rankings, wish lists and hidden gem suggestions.
struct InsightsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    categoryRankingSection
                    wishlistDishesSection
                    wishlistRestaurantsSection
                    hiddenGemsSection
                }
                .padding()
            }
            .navigationTitle("Insights")
        }
    }

    private var categoryRankingSection: some View {
        let ranking = AnalyticsService.rankedCategories(entries: appState.entries, dishes: appState.dishes)
        return Group {
            if !ranking.isEmpty {
                CardView {
                    Text("Average Score by Category")
                        .font(AppTypography.headline)
                    ForEach(ranking, id: \.category) { item in
                        HStack {
                            Text(item.category.displayName)
                            Spacer()
                            Text(String(format: "%.1f", item.averageScore))
                        }
                        .font(AppTypography.body)
                    }
                }
            }
        }
    }

    private var wishlistDishesSection: some View {
        let dishes = AnalyticsService.wishlistDishes(dishes: appState.dishes)
        return Group {
            if !dishes.isEmpty {
                CardView {
                    Text("Wishlist Dishes")
                        .font(AppTypography.headline)
                    ForEach(dishes) { dish in
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

    private var wishlistRestaurantsSection: some View {
        let restaurants = AnalyticsService.wishlistRestaurants(restaurants: appState.restaurants)
        return Group {
            if !restaurants.isEmpty {
                CardView {
                    Text("Wishlist Restaurants")
                        .font(AppTypography.headline)
                    ForEach(restaurants) { restaurant in
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

    private var hiddenGemsSection: some View {
        let gems = AnalyticsService.hiddenGems(entries: appState.entries, dishes: appState.dishes)
        return Group {
            if !gems.isEmpty {
                CardView {
                    Text("Hidden Gems")
                        .font(AppTypography.headline)
                    ForEach(gems, id: \.dish.id) { item in
                        NavigationLink {
                            DishDetailView(dishID: item.dish.id)
                        } label: {
                            HStack {
                                DishRow(dish: item.dish, entries: appState.entries)
                                Spacer()
                                Text(String(format: "%.1f", item.averageScore))
                                    .font(AppTypography.body)
                            }
                        }
                    }
                }
            }
        }
    }
}
