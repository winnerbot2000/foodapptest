import SwiftUI

/// Browses saved dishes plus logged products and drinks with search,
/// sorting, and lightweight summaries.
struct DishesView: View {
    @EnvironmentObject private var appState: AppState

    @State private var showAddDish = false
    @State private var showAddEntry = false
    @State private var searchText = ""
    @State private var selectedScope: ItemBrowseScope = .dishes
    @State private var sortOption: ItemBrowseSortOption = .recentlyTried

    private var displayedSummaries: [LoggedItemSummary] {
        appState.itemSummaries(
            for: selectedScope,
            searchText: searchText,
            sort: sortOption
        )
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var savedDishSummaries: [LoggedItemSummary] {
        displayedSummaries.filter { $0.dishID != nil }
    }

    private var derivedSummaries: [LoggedItemSummary] {
        displayedSummaries.filter { $0.dishID == nil }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Browse Scope", selection: $selectedScope) {
                    ForEach(ItemBrowseScope.allCases) { scope in
                        Text(scope.displayName).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)

                Group {
                    if displayedSummaries.isEmpty {
                        EmptyStateView(
                            title: emptyTitle,
                            message: emptyMessage,
                            suggestion: emptySuggestion,
                            systemImage: emptySystemImage
                        )
                    } else {
                        List {
                            Section {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: AppSpacing.sm) {
                                        summaryChip("\(displayedSummaries.count) result\(displayedSummaries.count == 1 ? "" : "s")")
                                        summaryChip("Sort: \(sortOption.displayName)")

                                        if !trimmedSearchText.isEmpty {
                                            summaryChip("Search: \(trimmedSearchText)")
                                        }
                                    }
                                    .padding(.vertical, AppSpacing.xs)
                                }
                                .listRowInsets(EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.md, bottom: AppSpacing.xs, trailing: AppSpacing.md))
                            }

                            if selectedScope == .dishes {
                                if !savedDishSummaries.isEmpty {
                                    Section(header: Text("Saved Dishes")) {
                                        ForEach(savedDishSummaries) { summary in
                                            if let dishID = summary.dishID, let dish = appState.dish(for: dishID) {
                                                NavigationLink {
                                                    DishDetailView(dishID: dish.id)
                                                } label: {
                                                    DishRow(dish: dish, entries: appState.entries, summary: summary)
                                                }
                                            }
                                        }
                                        .onDelete(perform: deleteSavedDishes)
                                    }
                                }

                                if !derivedSummaries.isEmpty {
                                    Section(header: Text("Logged Without Saved Dish")) {
                                        ForEach(derivedSummaries) { summary in
                                            NavigationLink {
                                                ItemHistoryDetailView(summary: summary)
                                            } label: {
                                                DerivedItemSummaryRow(summary: summary)
                                            }
                                        }
                                    }
                                }
                            } else {
                                ForEach(displayedSummaries) { summary in
                                    NavigationLink {
                                        ItemHistoryDetailView(summary: summary)
                                    } label: {
                                        DerivedItemSummaryRow(summary: summary)
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
            }
            .navigationTitle("Items")
            .searchable(text: $searchText, prompt: "Search dishes, products, drinks")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Sort By", selection: $sortOption) {
                            ForEach(ItemBrowseSortOption.allCases) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                    }

                    Button(action: primaryAddAction) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddDish) {
            AddDishView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showAddEntry) {
            AddEntryView(preferredItemType: selectedScope.itemType)
                .environmentObject(appState)
        }
    }

    private func deleteSavedDishes(offsets: IndexSet) {
        for index in offsets {
            let summary = savedDishSummaries[index]
            if let dishID = summary.dishID, let dish = appState.dish(for: dishID) {
                appState.deleteDish(dish)
            }
        }
    }

    private func primaryAddAction() {
        switch selectedScope {
        case .dishes:
            showAddDish = true
        case .products, .drinks:
            showAddEntry = true
        }
    }

    private var emptyTitle: String {
        if !trimmedSearchText.isEmpty {
            return "No matching \(selectedScope.displayName.lowercased())"
        }

        switch selectedScope {
        case .dishes:
            return "No dishes yet"
        case .products:
            return "No products logged yet"
        case .drinks:
            return "No drinks logged yet"
        }
    }

    private var emptyMessage: String {
        if !trimmedSearchText.isEmpty {
            return "Nothing in this item category matches your current search."
        }

        switch selectedScope {
        case .dishes:
            return "Saved dishes and custom logged dishes will appear here with ratings and history."
        case .products:
            return "Packaged foods and other product-style items are grouped here once you log them."
        case .drinks:
            return "Drinks you log will be grouped here so you can compare them over time."
        }
    }

    private var emptySuggestion: String {
        if !trimmedSearchText.isEmpty {
            return "Try a broader search term."
        }

        switch selectedScope {
        case .dishes:
            return "Add a dish or log a dish entry to start comparing favorites."
        case .products:
            return "Log a product entry to start tracking brands, stores, and repeat buys."
        case .drinks:
            return "Log a drink entry to start tracking pairings, sizes, and favorites."
        }
    }

    private var emptySystemImage: String {
        switch selectedScope {
        case .dishes:
            return "fork"
        case .products:
            return "shippingbox"
        case .drinks:
            return "wineglass"
        }
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

private struct DerivedItemSummaryRow: View {
    let summary: LoggedItemSummary

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            if let photoReference = summary.photoReference {
                LocalPhotoThumbnailView(reference: photoReference, size: 60, cornerRadius: 16)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                    Image(systemName: summary.itemType.systemImage)
                        .foregroundColor(AppColors.primary)
                }
                .frame(width: 60, height: 60)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(summary.name)
                    .font(AppTypography.headline)
                    .lineLimit(2)

                if let subtitle = summary.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondary)
                }

                HStack(spacing: AppSpacing.sm) {
                    Text("\(summary.logCount) log\(summary.logCount == 1 ? "" : "s")")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondary)

                    if summary.restaurantCount > 0 {
                        Text("\(summary.restaurantCount) place\(summary.restaurantCount == 1 ? "" : "s")")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondary)
                    }
                }

                if let lastTried = summary.lastTried {
                    Text("Last tried \(lastTried.formatted(date: .abbreviated, time: .omitted))")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                Text(String(format: "%.1f", summary.averageOverallRating))
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.primary)

                Text("Avg")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondary)
            }
        }
        .padding(.vertical, AppSpacing.sm)
    }
}
