import SwiftUI

/// Displays the details of a single tracked item.  The view reflects
/// dishes, products and drinks with lightweight type‑specific sections
/// while still supporting linked restaurants and grouped visits.
struct EntryDetailView: View {
    @EnvironmentObject private var appState: AppState
    let entryID: UUID
    @State private var showEditEntry = false

    private var entry: FoodEntry? {
        appState.entry(for: entryID)
    }

    private func restaurant(for entry: FoodEntry) -> Restaurant? {
        entry.restaurantId.flatMap { appState.restaurant(for: $0) }
    }

    private func dish(for entry: FoodEntry) -> Dish? {
        entry.dishId.flatMap { appState.dish(for: $0) }
    }

    private func place(for entry: FoodEntry) -> PlaceRecord? {
        appState.place(for: entry)
    }

    private func visit(for entry: FoodEntry) -> VisitSummary? {
        entry.visitId.flatMap { appState.visit(for: $0) }
    }

    var body: some View {
        Group {
            if let entry {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        header(entry: entry)
                        contextSection(entry: entry)
                        placeMetadataSection(entry: entry)
                        ratingsSection(entry: entry)
                        structuredDetailsSection(entry: entry)
                        typeSpecificSection(entry: entry)
                        notesSection(entry: entry)
                        tagsSection(entry: entry)
                        photosSection(entry: entry)
                        flagsSection(entry: entry)
                    }
                    .padding()
                }
            } else {
                EmptyStateView(title: "Entry not found", systemImage: "tray")
            }
        }
        .navigationTitle("Entry Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if entry != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showEditEntry = true
                    }
                }
            }
        }
        .sheet(isPresented: $showEditEntry) {
            if let entry {
                AddEntryView(entry: entry)
                    .environmentObject(appState)
            }
        }
    }

    private func header(entry: FoodEntry) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(appState.displayName(for: entry))
                .font(AppTypography.title)

            HStack(spacing: AppSpacing.sm) {
                Label(entry.itemType.displayName, systemImage: entry.itemType.systemImage)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.primary)

                Text(entry.date, style: .date)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondary)
            }
        }
    }

    private func contextSection(entry: FoodEntry) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if let restaurant = restaurant(for: entry) {
                Label(restaurant.name, systemImage: "fork.knife")
                    .foregroundColor(AppColors.secondary)
                    .font(AppTypography.body)
            }

            if let branch = appState.displayBranch(for: entry), !branch.isEmpty {
                Label(branch, systemImage: "mappin.and.ellipse")
                    .foregroundColor(AppColors.secondary)
                    .font(AppTypography.body)
            }

            if let visit = visit(for: entry) {
                Label("Visit with \(visit.itemCount) item(s)", systemImage: "square.stack.3d.up")
                    .foregroundColor(AppColors.secondary)
                    .font(AppTypography.body)
            }

            if let dish = dish(for: entry), entry.itemType == .dish {
                Label(dish.category.displayName, systemImage: "list.bullet")
                    .foregroundColor(AppColors.secondary)
                    .font(AppTypography.body)
            }
        }
    }

    @ViewBuilder
    private func placeMetadataSection(entry: FoodEntry) -> some View {
        if let place = place(for: entry),
           place.secondaryText != nil || place.coordinateText != nil || place.source != .manual {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Place Details")
                    .font(AppTypography.headline)

                if let secondaryText = place.secondaryText, !secondaryText.isEmpty {
                    detailLine(title: "Address / Locality", value: secondaryText)
                }

                if let coordinateText = place.coordinateText {
                    detailLine(title: "Coordinates", value: coordinateText)
                }

                if place.source != .manual {
                    detailLine(title: "Source", value: place.source.displayName)
                }
            }
        }
    }

    private func ratingsSection(entry: FoodEntry) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Ratings")
                .font(AppTypography.headline)

            ratingLine(label: "Taste", value: entry.ratings.taste)
            ratingLine(label: "Quality", value: entry.ratings.quality)
            ratingLine(label: "Value", value: entry.ratings.value)
            ratingLine(label: "Overall", value: entry.ratings.overall)
        }
    }

    private func ratingLine(label: String, value: Int) -> some View {
        HStack {
            Text(label)
                .font(AppTypography.body)
            Spacer()
            Text("\(value)/10")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.primary)
        }
    }

    private func structuredDetailsSection(entry: FoodEntry) -> some View {
        Group {
            if !entry.sides.isEmpty || !entry.sauces.isEmpty || !entry.modifications.isEmpty || (entry.drinkPairing?.isEmpty == false) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Structured Details")
                        .font(AppTypography.headline)

                    if !entry.sides.isEmpty {
                        detailLine(title: "Sides", value: entry.sides.joined(separator: ", "))
                    }

                    if !entry.sauces.isEmpty {
                        detailLine(title: "Sauces", value: entry.sauces.joined(separator: ", "))
                    }

                    if !entry.modifications.isEmpty {
                        detailLine(title: "Modifications", value: entry.modifications.joined(separator: ", "))
                    }

                    if let drinkPairing = entry.drinkPairing, !drinkPairing.isEmpty {
                        detailLine(title: "Drink Pairing", value: drinkPairing)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func typeSpecificSection(entry: FoodEntry) -> some View {
        switch entry.itemType {
        case .dish:
            EmptyView()
        case .drink:
            if entry.drinkSize != nil || entry.drinkTemperature != nil || entry.sweetnessLevel != nil || entry.carbonationLevel != nil || entry.strengthLevel != nil {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Drink Details")
                        .font(AppTypography.headline)

                    if let drinkSize = entry.drinkSize {
                        detailLine(title: "Size", value: drinkSize.displayName)
                    }

                    if let drinkTemperature = entry.drinkTemperature {
                        detailLine(title: "Temperature", value: drinkTemperature.displayName)
                    }

                    if let sweetnessLevel = entry.sweetnessLevel {
                        detailLine(title: "Sweetness", value: "\(sweetnessLevel)/5")
                    }

                    if let carbonationLevel = entry.carbonationLevel {
                        detailLine(title: "Carbonation", value: "\(carbonationLevel)/5")
                    }

                    if let strengthLevel = entry.strengthLevel {
                        detailLine(title: "Strength", value: "\(strengthLevel)/5")
                    }
                }
            }
        case .product:
            if entry.brand != nil || entry.storeName != nil || entry.consistencyNotes != nil {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Product Details")
                        .font(AppTypography.headline)

                    if let brand = entry.brand, !brand.isEmpty {
                        detailLine(title: "Brand", value: brand)
                    }

                    if let storeName = entry.storeName, !storeName.isEmpty {
                        detailLine(title: "Store", value: storeName)
                    }

                    if let consistencyNotes = entry.consistencyNotes, !consistencyNotes.isEmpty {
                        detailLine(title: "Consistency", value: consistencyNotes)
                    }
                }
            }
        }
    }

    private func notesSection(entry: FoodEntry) -> some View {
        Group {
            if let notes = entry.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Notes")
                        .font(AppTypography.headline)
                    Text(notes)
                        .font(AppTypography.body)
                }
            }
        }
    }

    private func tagsSection(entry: FoodEntry) -> some View {
        Group {
            if !entry.tags.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Tags")
                        .font(AppTypography.headline)
                    TagListView(tags: entry.tags)
                }
            }
        }
    }

    private func photosSection(entry: FoodEntry) -> some View {
        PhotoGallerySection(
            title: "Photos",
            photoReferences: entry.photoReferences,
            emptyStateText: "No photos attached to this entry."
        )
    }

    private func flagsSection(entry: FoodEntry) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if entry.wouldOrderAgain {
                Label("Would order again", systemImage: "checkmark.circle")
                    .foregroundColor(AppColors.primary)
                    .font(AppTypography.body)
            }

            if entry.neverOrderAgain {
                Label("Never order again", systemImage: "xmark.circle")
                    .foregroundColor(AppColors.favorite)
                    .font(AppTypography.body)
            }

            if entry.itemType == .dish, entry.isBestVersion {
                Label("Best version", systemImage: "crown.fill")
                    .foregroundColor(AppColors.highlight)
                    .font(AppTypography.body)
            }

            if entry.highlighted {
                Label("Highlight", systemImage: "star.fill")
                    .foregroundColor(AppColors.favorite)
                    .font(AppTypography.body)
            }

            if let occasion = entry.occasion {
                Label(occasion.displayName, systemImage: "calendar")
                    .foregroundColor(AppColors.primary)
                    .font(AppTypography.body)
            }

            if let spice = entry.spiceLevel {
                Label(spice.displayName, systemImage: "flame")
                    .foregroundColor(AppColors.primary)
                    .font(AppTypography.body)
            }
        }
    }

    private func detailLine(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondary)
            Text(value)
                .font(AppTypography.body)
        }
    }
}
