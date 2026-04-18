import SwiftUI

/// Browses restaurants with local search, sort options, and visit-aware
/// summaries.
struct RestaurantsView: View {
    @EnvironmentObject private var appState: AppState

    @State private var showAddRestaurant = false
    @State private var searchText = ""
    @State private var sortOption: RestaurantBrowseSortOption = .mostVisited

    private var displayedRestaurants: [RestaurantBrowseSummary] {
        appState.restaurantSummaries(
            searchText: searchText,
            sort: sortOption
        )
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Group {
                if displayedRestaurants.isEmpty {
                    EmptyStateView(
                        title: emptyTitle,
                        message: emptyMessage,
                        suggestion: emptySuggestion,
                        systemImage: "fork.knife"
                    )
                } else {
                    List {
                        Section {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppSpacing.sm) {
                                    summaryChip("\(displayedRestaurants.count) result\(displayedRestaurants.count == 1 ? "" : "s")")
                                    summaryChip("Sort: \(sortOption.displayName)")

                                    if !trimmedSearchText.isEmpty {
                                        summaryChip("Search: \(trimmedSearchText)")
                                    }
                                }
                                .padding(.vertical, AppSpacing.xs)
                            }
                            .listRowInsets(EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.md, bottom: AppSpacing.xs, trailing: AppSpacing.md))
                        }

                        ForEach(displayedRestaurants) { summary in
                            NavigationLink {
                                RestaurantDetailView(restaurantID: summary.restaurant.id)
                            } label: {
                                RestaurantRow(
                                    restaurant: summary.restaurant,
                                    entries: appState.entries,
                                    summary: summary
                                )
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Restaurants")
            .searchable(text: $searchText, prompt: "Search restaurants or branch places")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Sort By", selection: $sortOption) {
                            ForEach(RestaurantBrowseSortOption.allCases) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                    }

                    Button(action: { showAddRestaurant = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddRestaurant) {
            AddRestaurantView()
                .environmentObject(appState)
        }
    }

    private func delete(offsets: IndexSet) {
        for index in offsets {
            let summary = displayedRestaurants[index]
            appState.deleteRestaurant(summary.restaurant)
        }
    }

    private var emptyTitle: String {
        trimmedSearchText.isEmpty ? "No restaurants yet" : "No matching restaurants"
    }

    private var emptyMessage: String {
        if trimmedSearchText.isEmpty {
            return "Restaurants will show visit counts, recent places, and favorite items as you log them."
        }
        return "No restaurant or branch/place text matches your current search."
    }

    private var emptySuggestion: String {
        if trimmedSearchText.isEmpty {
            return "Add a restaurant to start organizing visits and repeat favorites."
        }
        return "Try a broader restaurant name or search for a different branch."
    }

    private func summaryChip(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.caption)
            .foregroundColor(AppColors.secondary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemBackground))
            .clipShape(Capsule())
    }
}
