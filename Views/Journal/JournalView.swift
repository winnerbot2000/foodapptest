import SwiftUI

/// Displays the chronological feed of food entries.  Allows users
/// to add new entries and delete existing ones.  Each row navigates
/// to a detailed view of the entry.
struct JournalView: View {
    @EnvironmentObject private var appState: AppState

    @State private var showAddEntry = false
    @State private var showFilters = false
    @State private var searchText = ""
    @State private var filters = JournalFilterState()
    @State private var sortOption: JournalSortOption = .newestFirst

    private var displayedEntries: [FoodEntry] {
        appState.filteredJournalEntries(
            searchText: searchText,
            filters: filters,
            sort: sortOption
        )
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Group {
                if appState.entries.isEmpty {
                    EmptyStateView(
                        title: "No entries yet",
                        message: "Your journal will collect dishes, drinks, products, places, and photos here.",
                        suggestion: "Add your first entry to start building a searchable food history.",
                        systemImage: "tray"
                    )
                } else {
                    journalList
                }
            }
            .navigationTitle("Journal")
            .searchable(text: $searchText, prompt: "Search items, restaurants, notes, places")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Sort By", selection: $sortOption) {
                            ForEach(JournalSortOption.allCases) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                    }

                    Button(action: { showFilters = true }) {
                        Image(systemName: filters.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Filter Journal")

                    Button(action: { showAddEntry = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddEntry) {
            AddEntryView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showFilters) {
            JournalFilterSheet(filters: $filters)
        }
    }

    private var journalList: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        summaryChip("\(displayedEntries.count) result\(displayedEntries.count == 1 ? "" : "s")")
                        summaryChip("Sort: \(sortOption.displayName)")

                        if !trimmedSearchText.isEmpty {
                            summaryChip("Search: \(trimmedSearchText)")
                        }

                        ForEach(filters.activeFilterTokens, id: \.self) { token in
                            summaryChip(token)
                        }

                        if filters.hasActiveFilters {
                            Button("Clear Filters") {
                                filters = JournalFilterState()
                            }
                            .font(AppTypography.caption)
                        }
                    }
                    .padding(.vertical, AppSpacing.xs)
                }
                .listRowInsets(EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.md, bottom: AppSpacing.xs, trailing: AppSpacing.md))
            }

            if displayedEntries.isEmpty {
                Section {
                    EmptyStateView(
                        title: "No matching entries",
                        message: "Nothing in your journal matches the current search and filter combination.",
                        suggestion: "Try a broader search, a different sort, or clear some filters.",
                        systemImage: "magnifyingglass"
                    )
                }
            } else {
                ForEach(displayedEntries) { entry in
                    NavigationLink {
                        EntryDetailView(entryID: entry.id)
                    } label: {
                        EntryRow(
                            entry: entry,
                            restaurant: entry.restaurantId.flatMap(appState.restaurant(for:)),
                            dish: entry.dishId.flatMap(appState.dish(for:))
                        )
                    }
                }
                .onDelete(perform: delete)
            }
        }
        .listStyle(.insetGrouped)
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

    private func delete(offsets: IndexSet) {
        for index in offsets {
            let entry = displayedEntries[index]
            appState.deleteEntry(entry)
        }
    }
}

private struct JournalFilterSheet: View {
    @Binding var filters: JournalFilterState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Item Type")) {
                    Picker("Item Type", selection: Binding(
                        get: { filters.itemType },
                        set: { filters.itemType = $0 }
                    )) {
                        Text("All Types").tag(ItemType?.none)
                        ForEach(ItemType.allCases) { type in
                            Text(type.displayName).tag(ItemType?.some(type))
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section(header: Text("Date Range")) {
                    Picker("Range", selection: $filters.dateRange) {
                        ForEach(JournalDateRange.allCases) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(.menu)

                    if filters.dateRange == .custom {
                        DatePicker("Start", selection: $filters.customStartDate, displayedComponents: .date)
                        DatePicker("End", selection: $filters.customEndDate, displayedComponents: .date)
                    }
                }

                Section(header: Text("Minimum Ratings")) {
                    Stepper("Taste \(filters.minimumTaste)+", value: $filters.minimumTaste, in: 0...10)
                    Stepper("Quality \(filters.minimumQuality)+", value: $filters.minimumQuality, in: 0...10)
                    Stepper("Value \(filters.minimumValue)+", value: $filters.minimumValue, in: 0...10)
                }

                Section(header: Text("Restaurant Attachment")) {
                    Picker("Restaurant Attachment", selection: $filters.restaurantAttachment) {
                        ForEach(JournalRestaurantAttachmentFilter.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }

                if filters.hasActiveFilters {
                    Section {
                        Button("Reset Filters", role: .destructive) {
                            filters = JournalFilterState()
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
