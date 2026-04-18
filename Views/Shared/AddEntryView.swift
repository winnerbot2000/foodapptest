import SwiftUI

/// Presents a form for creating or editing a tracked food item. The
/// flow supports dishes, products and drinks, and can attach multiple
/// items to the same restaurant visit through a shared visit ID.
struct AddEntryView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private let entryID: UUID?
    private let draftID: UUID
    private let originalPhotoReferences: [PhotoReference]

    // Classification and relationships
    @State private var itemType: ItemType = .dish
    @State private var selectedDishID: UUID?
    @State private var selectedRestaurantID: UUID?
    @State private var selectedVisitID: UUID?

    // Common fields
    @State private var customItemName: String = ""
    @State private var placeDisplayName: String = ""
    @State private var placeAddressText: String = ""
    @State private var placeLocalityText: String = ""
    @State private var placeLatitude: Double?
    @State private var placeLongitude: Double?
    @State private var placeSource: PlaceSource = .manual
    @State private var date: Date = Date()
    @State private var price: String = ""
    @State private var currency: Currency = .eur
    @State private var ratings = RatingBreakdown()
    @State private var photoReferences: [PhotoReference] = []
    @State private var notes: String = ""
    @State private var tagsText: String = ""

    // Structured details
    @State private var sidesText: String = ""
    @State private var saucesText: String = ""
    @State private var modificationsText: String = ""
    @State private var drinkPairing: String = ""

    // Product fields
    @State private var brand: String = ""
    @State private var storeName: String = ""
    @State private var consistencyNotes: String = ""

    // Drink fields
    @State private var drinkSize: DrinkSize?
    @State private var drinkTemperature: DrinkTemperature?
    @State private var sweetnessLevel: Int = 0
    @State private var carbonationLevel: Int = 0
    @State private var strengthLevel: Int = 0

    // Existing compatibility fields
    @State private var wouldOrderAgain = false
    @State private var highlighted = false
    @State private var occasion: Occasion?
    @State private var spiceLevel: SpiceLevel?
    @State private var isBestVersion = false
    @State private var neverOrderAgain = false

    // Photo suggestions and cleanup state
    @State private var suggestedCaptureDate: Date?
    @State private var suggestedLatitude: Double?
    @State private var suggestedLongitude: Double?
    @State private var importedPhotoReferences: [PhotoReference] = []
    @State private var didPersistChanges = false
    @State private var didRunDiscardCleanup = false

    // Sheet toggles
    @State private var showAddDish = false
    @State private var showAddRestaurant = false
    @State private var showMenuScanner = false
    @State private var stagedMenuItems: [ParsedMenuItem] = []
    @StateObject private var currentLocationService = CurrentLocationService()

    init(entry: FoodEntry? = nil, preferredItemType: ItemType? = nil) {
        self.entryID = entry?.id
        self.draftID = entry?.id ?? UUID()
        self.originalPhotoReferences = entry?.photoReferences ?? []

        _itemType = State(initialValue: entry?.itemType ?? preferredItemType ?? .dish)
        _selectedDishID = State(initialValue: entry?.dishId)
        _selectedRestaurantID = State(initialValue: entry?.restaurantId)
        _selectedVisitID = State(initialValue: entry?.visitId)
        _customItemName = State(initialValue: entry?.customDishName ?? "")
        _placeDisplayName = State(initialValue: entry?.place?.displayName ?? entry?.placeName ?? "")
        _placeAddressText = State(initialValue: entry?.place?.addressText ?? "")
        _placeLocalityText = State(initialValue: entry?.place?.localityText ?? "")
        _placeLatitude = State(initialValue: entry?.place?.latitude)
        _placeLongitude = State(initialValue: entry?.place?.longitude)
        _placeSource = State(initialValue: entry?.place?.source ?? .manual)
        _date = State(initialValue: entry?.date ?? Date())
        _price = State(initialValue: entry?.price.map { String($0) } ?? "")
        _currency = State(initialValue: entry?.currency ?? .eur)
        _ratings = State(initialValue: entry?.ratings ?? RatingBreakdown())
        _photoReferences = State(initialValue: entry?.photoReferences ?? [])
        _notes = State(initialValue: entry?.notes ?? "")
        _tagsText = State(initialValue: entry?.tags.joined(separator: ", ") ?? "")
        _sidesText = State(initialValue: entry?.sides.joined(separator: ", ") ?? "")
        _saucesText = State(initialValue: entry?.sauces.joined(separator: ", ") ?? "")
        _modificationsText = State(initialValue: entry?.modifications.joined(separator: ", ") ?? "")
        _drinkPairing = State(initialValue: entry?.drinkPairing ?? "")
        _brand = State(initialValue: entry?.brand ?? "")
        _storeName = State(initialValue: entry?.storeName ?? "")
        _consistencyNotes = State(initialValue: entry?.consistencyNotes ?? "")
        _drinkSize = State(initialValue: entry?.drinkSize)
        _drinkTemperature = State(initialValue: entry?.drinkTemperature)
        _sweetnessLevel = State(initialValue: entry?.sweetnessLevel ?? 0)
        _carbonationLevel = State(initialValue: entry?.carbonationLevel ?? 0)
        _strengthLevel = State(initialValue: entry?.strengthLevel ?? 0)
        _wouldOrderAgain = State(initialValue: entry?.wouldOrderAgain ?? false)
        _highlighted = State(initialValue: entry?.highlighted ?? false)
        _occasion = State(initialValue: entry?.occasion)
        _spiceLevel = State(initialValue: entry?.spiceLevel)
        _isBestVersion = State(initialValue: entry?.isBestVersion ?? false)
        _neverOrderAgain = State(initialValue: entry?.neverOrderAgain ?? false)
    }

    private var availableVisits: [VisitSummary] {
        guard let selectedRestaurantID else {
            return []
        }

        return appState.visits(for: selectedRestaurantID)
    }

    private var selectedVisitSummary: VisitSummary? {
        guard
            let selectedRestaurantID,
            let selectedVisitID,
            let visitSummary = appState.visit(for: selectedVisitID),
            visitSummary.restaurantId == selectedRestaurantID
        else {
            return nil
        }
        return visitSummary
    }

    private var recentPlaces: [PlaceRecord] {
        appState.recentPlaces(for: selectedRestaurantID, limit: 6)
    }

    private var hasAttachedCoordinates: Bool {
        placeLatitude != nil && placeLongitude != nil
    }

    private var coordinateText: String? {
        guard let placeLatitude, let placeLongitude else {
            return nil
        }
        return String(format: "%.5f, %.5f", placeLatitude, placeLongitude)
    }

    private var photoCoordinateText: String? {
        guard let suggestedLatitude, let suggestedLongitude else {
            return nil
        }
        return String(format: "%.5f, %.5f", suggestedLatitude, suggestedLongitude)
    }

    private var originalPhotoPaths: Set<String> {
        Set(originalPhotoReferences.map(\.relativePath))
    }

    var body: some View {
        NavigationStack {
            Form {
                itemTypeSection
                itemSection
                menuScanSection
                whereSection
                if selectedRestaurantID != nil {
                    visitSection
                }
                dateAndPriceSection
                suggestionsSection
                ratingsSection
                structuredDetailsSection
                if itemType == .drink {
                    drinkDetailsSection
                }
                if itemType == .product {
                    productDetailsSection
                }
                PhotoAttachmentSection(
                    title: "Photos",
                    owner: .entry,
                    ownerID: draftID,
                    photoReferences: $photoReferences,
                    emptyStateText: "Attach photos from your library. Images stay stored locally on this device."
                ) { result in
                    importedPhotoReferences = mergePhotoReferences(importedPhotoReferences, with: result.references)
                    if suggestedCaptureDate == nil {
                        suggestedCaptureDate = result.suggestedCaptureDate
                    }
                    if suggestedLatitude == nil {
                        suggestedLatitude = result.suggestedLatitude
                    }
                    if suggestedLongitude == nil {
                        suggestedLongitude = result.suggestedLongitude
                    }
                } onRemovePhoto: { reference in
                    handleRemovedPhoto(reference)
                }
                flagsSection
                notesAndTagsSection
                advancedSection
            }
            .navigationTitle(entryID == nil ? "Add Entry" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(entryID == nil ? "Save" : "Update") {
                        didPersistChanges = true
                        saveEntry()
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
        .sheet(isPresented: $showAddDish) {
            AddDishView { newDish in
                selectedDishID = newDish.id
                itemType = .dish
            }
            .environmentObject(appState)
        }
        .sheet(isPresented: $showAddRestaurant) {
            AddRestaurantView { newRestaurant in
                selectedRestaurantID = newRestaurant.id
            }
            .environmentObject(appState)
        }
        .sheet(isPresented: $showMenuScanner) {
            MenuScanReviewSheet(ownerID: draftID, restaurantID: selectedRestaurantID) { submission in
                applyMenuScanSubmission(submission)
            }
            .environmentObject(appState)
        }
        .onChange(of: selectedRestaurantID) { _ in
            syncVisitSelectionToRestaurant()
        }
        .onDisappear {
            cleanupDiscardedPhotosIfNeeded()
        }
    }

    private var itemTypeSection: some View {
        Section(header: Text("Type")) {
            Picker("Item Type", selection: $itemType) {
                ForEach(ItemType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var itemSection: some View {
        Section(header: Text("Item")) {
            if itemType == .dish {
                Picker("Saved Dish", selection: $selectedDishID) {
                    Text("Custom Dish").tag(UUID?.none)
                    ForEach(appState.dishes) { dish in
                        Text(dish.name).tag(UUID?.some(dish.id))
                    }
                }
                .pickerStyle(.menu)

                Button("Add New Dish") {
                    showAddDish = true
                }

                if selectedDishID == nil {
                    TextField("Dish Name", text: $customItemName)
                }
            } else {
                TextField(itemType == .drink ? "Drink Name" : "Product Name", text: $customItemName)
            }
        }
    }

    private var whereSection: some View {
        Section(header: Text("Where")) {
            Picker("Restaurant Brand", selection: $selectedRestaurantID) {
                Text("None").tag(UUID?.none)
                ForEach(appState.restaurants) { restaurant in
                    Text(restaurant.name).tag(UUID?.some(restaurant.id))
                }
            }
            .pickerStyle(.menu)

            Button("Add New Restaurant") {
                showAddRestaurant = true
            }

            TextField("Branch / Place Name", text: $placeDisplayName)
            TextField("Address (Optional)", text: $placeAddressText)
            TextField("City / Area (Optional)", text: $placeLocalityText)

            if !recentPlaces.isEmpty {
                Menu("Use Recent Place") {
                    ForEach(recentPlaces) { place in
                        Button(recentPlaceLabel(for: place)) {
                            applyRecentPlace(place)
                        }
                    }
                }
            }

            Button(currentLocationService.isRequestingLocation ? "Finding Current Location..." : "Use Current Location") {
                Task {
                    await attachCurrentLocation()
                }
            }
            .disabled(currentLocationService.isRequestingLocation)

            if let errorMessage = currentLocationService.errorMessage {
                Text(errorMessage)
                    .font(AppTypography.caption)
                    .foregroundColor(.red)
            }

            if let coordinateText {
                Label(coordinateText, systemImage: "location.fill")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondary)

                Text("Location source: \(placeSource.displayName)")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondary)

                Button("Remove Attached Coordinates", role: .destructive) {
                    placeLatitude = nil
                    placeLongitude = nil
                    if placeDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        placeSource = .manual
                    }
                }
            }
        }
    }

    private var menuScanSection: some View {
        Section(header: Text("Menu Scan")) {
            Button("Scan Menu Photo") {
                showMenuScanner = true
            }

            Text("Use a menu photo to recognize text on-device, confirm the items you want, and optionally queue additional entries from the same visit.")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondary)

            if !stagedMenuItems.isEmpty {
                Text("Additional selected menu items")
                    .font(AppTypography.subheadline)

                Text("These will be saved as separate \(itemType.displayName.lowercased()) entries in the same visit.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondary)

                ForEach(stagedMenuItems.indices, id: \.self) { index in
                    let itemID = stagedMenuItems[index].id

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        TextField("Item Name", text: $stagedMenuItems[index].name)

                        TextField(
                            "Price (Optional)",
                            text: Binding(
                                get: { stagedMenuItems[index].priceText ?? "" },
                                set: {
                                    stagedMenuItems[index].priceText = $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? nil
                                        : $0
                                }
                            )
                        )
                        .keyboardType(.decimalPad)

                        Button("Remove", role: .destructive) {
                            stagedMenuItems.removeAll { $0.id == itemID }
                        }
                        .font(AppTypography.caption)
                    }
                    .padding(.vertical, AppSpacing.xs)
                }
            }
        }
    }

    private var visitSection: some View {
        Section(header: Text("Visit")) {
            if availableVisits.isEmpty {
                Text("This item will start a new visit for the selected restaurant.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondary)
            } else {
                Picker("Attach to Visit", selection: $selectedVisitID) {
                    Text("Create New Visit").tag(UUID?.none)
                    ForEach(availableVisits) { visit in
                        Text(visitLabel(for: visit)).tag(UUID?.some(visit.id))
                    }
                }
                .pickerStyle(.menu)

                if let selectedVisitSummary {
                    Text("Adding to an existing visit with \(selectedVisitSummary.itemCount) item(s).")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondary)
                }
            }
        }
    }

    private var dateAndPriceSection: some View {
        Section(header: Text("Date & Price")) {
            DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])

            HStack {
                TextField("Price", text: $price)
                    .keyboardType(.decimalPad)

                Picker("Currency", selection: $currency) {
                    ForEach(Currency.allCases) { curr in
                        Text(curr.rawValue).tag(curr)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    @ViewBuilder
    private var suggestionsSection: some View {
        if suggestedCaptureDate != nil || photoCoordinateText != nil {
            Section(header: Text("Suggestions")) {
                if let suggestedCaptureDate {
                    Button("Use Photo Capture Date") {
                        date = suggestedCaptureDate
                    }

                    Text("Suggested from attached photo metadata: \(suggestedCaptureDate.formatted(date: .abbreviated, time: .shortened))")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondary)
                }

                if let photoCoordinateText,
                   let suggestedLatitude,
                   let suggestedLongitude {
                    Button("Use Photo Location") {
                        applyCoordinates(
                            latitude: suggestedLatitude,
                            longitude: suggestedLongitude,
                            source: .photoMetadata
                        )
                    }

                    Text("Suggested from attached photo GPS metadata: \(photoCoordinateText)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondary)
                }
            }
        }
    }

    private var ratingsSection: some View {
        Section(header: Text("Ratings")) {
            RatingSlider(label: "Taste", value: $ratings.taste)
            RatingSlider(label: "Quality", value: $ratings.quality)
            RatingSlider(label: "Value", value: $ratings.value)
            RatingSlider(label: "Overall", value: $ratings.overall)
        }
    }

    private var structuredDetailsSection: some View {
        Section(header: Text("Structured Details")) {
            TextField("Sides (comma separated)", text: $sidesText)
            TextField("Sauces (comma separated)", text: $saucesText)
            TextField("Modifications (comma separated)", text: $modificationsText)

            if itemType != .drink {
                TextField("Drink Pairing", text: $drinkPairing)
            }
        }
    }

    private var drinkDetailsSection: some View {
        Section(header: Text("Drink Details")) {
            Picker("Size", selection: Binding(
                get: { drinkSize },
                set: { drinkSize = $0 }
            )) {
                Text("None").tag(DrinkSize?.none)
                ForEach(DrinkSize.allCases) { size in
                    Text(size.displayName).tag(DrinkSize?.some(size))
                }
            }
            .pickerStyle(.menu)

            Picker("Temperature", selection: Binding(
                get: { drinkTemperature },
                set: { drinkTemperature = $0 }
            )) {
                Text("None").tag(DrinkTemperature?.none)
                ForEach(DrinkTemperature.allCases) { temperature in
                    Text(temperature.displayName).tag(DrinkTemperature?.some(temperature))
                }
            }
            .pickerStyle(.menu)

            Stepper("Sweetness: \(sweetnessLevel)", value: $sweetnessLevel, in: 0...5)
            Stepper("Carbonation: \(carbonationLevel)", value: $carbonationLevel, in: 0...5)
            Stepper("Strength: \(strengthLevel)", value: $strengthLevel, in: 0...5)
            TextField("Pairs Well With", text: $drinkPairing)
        }
    }

    private var productDetailsSection: some View {
        Section(header: Text("Product Details")) {
            TextField("Brand", text: $brand)
            TextField("Store or Chain", text: $storeName)
            TextField("Consistency Notes", text: $consistencyNotes, axis: .vertical)
        }
    }

    private var flagsSection: some View {
        Section(header: Text("Flags")) {
            Toggle("Would Order Again", isOn: $wouldOrderAgain)
            Toggle("Highlight", isOn: $highlighted)
            if itemType == .dish {
                Toggle("Best Version", isOn: $isBestVersion)
            }
            Toggle("Never Order Again", isOn: $neverOrderAgain)
        }
    }

    private var notesAndTagsSection: some View {
        Section(header: Text("Notes & Tags")) {
            TextField("Notes", text: $notes, axis: .vertical)
            TextField("Tags (comma separated)", text: $tagsText)
        }
    }

    private var advancedSection: some View {
        Section(header: Text("Advanced")) {
            Picker("Occasion", selection: Binding(
                get: { occasion },
                set: { occasion = $0 }
            )) {
                Text("None").tag(Occasion?.none)
                ForEach(Occasion.allCases) { occ in
                    Text(occ.displayName).tag(Occasion?.some(occ))
                }
            }
            .pickerStyle(.menu)

            Picker("Spice Level", selection: Binding(
                get: { spiceLevel },
                set: { spiceLevel = $0 }
            )) {
                Text("None").tag(SpiceLevel?.none)
                ForEach(SpiceLevel.allCases) { level in
                    Text(level.displayName).tag(SpiceLevel?.some(level))
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var trimmedItemName: String {
        customItemName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        if itemType == .dish {
            return selectedDishID != nil || !trimmedItemName.isEmpty
        }

        return !trimmedItemName.isEmpty
    }

    private func splitList(_ text: String) -> [String] {
        text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func visitLabel(for visit: VisitSummary) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        if let placeName = visit.placeName, !placeName.isEmpty {
            return "\(formatter.string(from: visit.date)) • \(visit.itemCount) items • \(placeName)"
        }

        return "\(formatter.string(from: visit.date)) • \(visit.itemCount) items"
    }

    private func recentPlaceLabel(for place: PlaceRecord) -> String {
        if let secondaryText = place.secondaryText, !secondaryText.isEmpty {
            return "\(place.displayName) • \(secondaryText)"
        }
        return place.displayName
    }

    private func attachCurrentLocation() async {
        guard let snapshot = await currentLocationService.requestCurrentLocation() else {
            return
        }

        applyCoordinates(
            latitude: snapshot.latitude,
            longitude: snapshot.longitude,
            source: .currentDeviceLocation
        )
    }

    private func applyCoordinates(latitude: Double, longitude: Double, source: PlaceSource) {
        placeLatitude = latitude
        placeLongitude = longitude
        placeSource = source

        if placeDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if let restaurantId = selectedRestaurantID, let restaurant = appState.restaurant(for: restaurantId) {
                placeDisplayName = restaurant.name
            } else {
                switch source {
                case .manual:
                    placeDisplayName = "Pinned Location"
                case .currentDeviceLocation:
                    placeDisplayName = "Current Location"
                case .photoMetadata:
                    placeDisplayName = "Photo Location"
                }
            }
        }
    }

    private func applyRecentPlace(_ place: PlaceRecord) {
        placeDisplayName = place.displayName
        placeAddressText = place.addressText ?? ""
        placeLocalityText = place.localityText ?? ""
        placeLatitude = place.latitude
        placeLongitude = place.longitude
        placeSource = place.source

        if selectedRestaurantID == nil, let restaurantId = place.restaurantId {
            selectedRestaurantID = restaurantId
        }
    }

    private func syncVisitSelectionToRestaurant() {
        guard let selectedVisitID else {
            return
        }

        if appState.visit(for: selectedVisitID)?.restaurantId != selectedRestaurantID {
            self.selectedVisitID = nil
        }
    }

    private func resolvedPlace() -> PlaceRecord? {
        let normalizedDisplayName = placeDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedAddressText = placeAddressText.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedLocalityText = placeLocalityText.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasCoordinates = placeLatitude != nil && placeLongitude != nil

        let displayName: String
        if !normalizedDisplayName.isEmpty {
            displayName = normalizedDisplayName
        } else if !normalizedAddressText.isEmpty {
            displayName = normalizedAddressText
        } else if !normalizedLocalityText.isEmpty {
            displayName = normalizedLocalityText
        } else if hasCoordinates {
            switch placeSource {
            case .manual:
                displayName = "Pinned Location"
            case .currentDeviceLocation:
                displayName = "Current Location"
            case .photoMetadata:
                displayName = "Photo Location"
            }
        } else {
            return nil
        }

        return PlaceRecord(
            displayName: displayName,
            addressText: normalizedAddressText.isEmpty ? nil : normalizedAddressText,
            localityText: normalizedLocalityText.isEmpty ? nil : normalizedLocalityText,
            latitude: placeLatitude,
            longitude: placeLongitude,
            source: hasCoordinates ? placeSource : .manual,
            restaurantId: selectedRestaurantID
        )
    }

    private func applyMenuScanSubmission(_ submission: MenuScanSubmission) {
        var parsedItems = submission.items
        guard !parsedItems.isEmpty else {
            return
        }

        let canPrefillCurrentEntry = selectedDishID == nil && trimmedItemName.isEmpty
        if canPrefillCurrentEntry, let firstItem = parsedItems.first {
            applyParsedMenuItemToCurrentEntry(firstItem)
            parsedItems.removeFirst()
        }

        stagedMenuItems = mergeMenuItems(stagedMenuItems, with: parsedItems)

        if !submission.importedPhotoReferences.isEmpty {
            photoReferences = mergePhotoReferences(photoReferences, with: submission.importedPhotoReferences)
            importedPhotoReferences = mergePhotoReferences(importedPhotoReferences, with: submission.importedPhotoReferences)
        }
    }

    private func applyParsedMenuItemToCurrentEntry(_ item: ParsedMenuItem) {
        if itemType == .dish {
            selectedDishID = nil
        }

        customItemName = item.name

        if price.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let normalizedPrice = normalizedPriceField(from: item.priceText) {
            price = normalizedPrice
        }
    }

    private func mergeMenuItems(_ existing: [ParsedMenuItem], with imported: [ParsedMenuItem]) -> [ParsedMenuItem] {
        var merged = existing
        var seenKeys = Set(existing.map(menuItemKey))

        for item in imported {
            let key = menuItemKey(item)
            if !seenKeys.contains(key) {
                seenKeys.insert(key)
                merged.append(item)
            }
        }

        return merged
    }

    private func menuItemKey(_ item: ParsedMenuItem) -> String {
        [
            item.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            item.priceText?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        ]
        .joined(separator: "|")
    }

    private func normalizedPriceField(from priceText: String?) -> String? {
        guard let trimmedPrice = priceText?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmedPrice.isEmpty else {
            return nil
        }

        let sanitized = trimmedPrice
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "£", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")

        return Double(sanitized) == nil ? nil : sanitized
    }

    private func saveEntry() {
        let priceValue = Double(price.replacingOccurrences(of: ",", with: "."))
        let normalizedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedDrinkPairing = drinkPairing.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedBrand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedStoreName = storeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedConsistencyNotes = consistencyNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedVisit = selectedVisitSummary
        let resolvedVisitID = selectedRestaurantID == nil ? nil : (resolvedVisit?.id ?? UUID())
        let resolvedDate = resolvedVisit?.date ?? date
        let resolvedDishID = itemType == .dish ? selectedDishID : nil
        let resolvedCustomName = resolvedDishID == nil ? trimmedItemName : nil
        let resolvedPlace = resolvedPlace()

        let tags = splitList(tagsText)
        let sides = splitList(sidesText)
        let sauces = splitList(saucesText)
        let modifications = splitList(modificationsText)

        if let entryID, let existingEntry = appState.entry(for: entryID) {
            var updatedEntry = existingEntry
            updatedEntry.itemType = itemType
            updatedEntry.restaurantId = selectedRestaurantID
            updatedEntry.visitId = resolvedVisitID
            updatedEntry.dishId = resolvedDishID
            updatedEntry.customDishName = resolvedCustomName
            updatedEntry.date = resolvedDate
            updatedEntry.place = resolvedPlace
            updatedEntry.placeName = resolvedPlace?.displayName
            updatedEntry.price = priceValue
            updatedEntry.currency = priceValue != nil ? currency : nil
            updatedEntry.ratings = ratings
            updatedEntry.notes = normalizedNotes.isEmpty ? nil : normalizedNotes
            updatedEntry.photoReferences = photoReferences
            updatedEntry.tags = tags
            updatedEntry.sides = sides
            updatedEntry.sauces = sauces
            updatedEntry.modifications = modifications
            updatedEntry.drinkPairing = normalizedDrinkPairing.isEmpty ? nil : normalizedDrinkPairing
            updatedEntry.drinkSize = itemType == .drink ? drinkSize : nil
            updatedEntry.drinkTemperature = itemType == .drink ? drinkTemperature : nil
            updatedEntry.sweetnessLevel = itemType == .drink ? sweetnessLevel : nil
            updatedEntry.carbonationLevel = itemType == .drink ? carbonationLevel : nil
            updatedEntry.strengthLevel = itemType == .drink ? strengthLevel : nil
            updatedEntry.brand = itemType == .product && !normalizedBrand.isEmpty ? normalizedBrand : nil
            updatedEntry.storeName = itemType == .product && !normalizedStoreName.isEmpty ? normalizedStoreName : nil
            updatedEntry.consistencyNotes = itemType == .product && !normalizedConsistencyNotes.isEmpty ? normalizedConsistencyNotes : nil
            updatedEntry.wouldOrderAgain = wouldOrderAgain
            updatedEntry.highlighted = highlighted
            updatedEntry.occasion = occasion
            updatedEntry.spiceLevel = spiceLevel
            updatedEntry.isBestVersion = itemType == .dish ? isBestVersion : false
            updatedEntry.neverOrderAgain = neverOrderAgain
            appState.updateEntry(updatedEntry)
        } else {
            let entry = FoodEntry(
                id: draftID,
                itemType: itemType,
                restaurantId: selectedRestaurantID,
                visitId: resolvedVisitID,
                dishId: resolvedDishID,
                customDishName: resolvedCustomName,
                date: resolvedDate,
                place: resolvedPlace,
                placeName: resolvedPlace?.displayName,
                price: priceValue,
                currency: priceValue != nil ? currency : nil,
                ratings: ratings,
                notes: normalizedNotes.isEmpty ? nil : normalizedNotes,
                photoReferences: photoReferences,
                tags: tags,
                sides: sides,
                sauces: sauces,
                modifications: modifications,
                drinkPairing: normalizedDrinkPairing.isEmpty ? nil : normalizedDrinkPairing,
                drinkSize: itemType == .drink ? drinkSize : nil,
                drinkTemperature: itemType == .drink ? drinkTemperature : nil,
                sweetnessLevel: itemType == .drink ? sweetnessLevel : nil,
                carbonationLevel: itemType == .drink ? carbonationLevel : nil,
                strengthLevel: itemType == .drink ? strengthLevel : nil,
                brand: itemType == .product && !normalizedBrand.isEmpty ? normalizedBrand : nil,
                storeName: itemType == .product && !normalizedStoreName.isEmpty ? normalizedStoreName : nil,
                consistencyNotes: itemType == .product && !normalizedConsistencyNotes.isEmpty ? normalizedConsistencyNotes : nil,
                wouldOrderAgain: wouldOrderAgain,
                highlighted: highlighted,
                occasion: occasion,
                spiceLevel: spiceLevel,
                isBestVersion: itemType == .dish ? isBestVersion : false,
                neverOrderAgain: neverOrderAgain
            )
            appState.addEntry(entry)
        }

        saveAdditionalMenuItems(
            using: stagedMenuItems,
            resolvedVisitID: resolvedVisitID,
            resolvedDate: resolvedDate,
            resolvedPlace: resolvedPlace
        )
    }

    private func saveAdditionalMenuItems(
        using items: [ParsedMenuItem],
        resolvedVisitID: UUID?,
        resolvedDate: Date,
        resolvedPlace: PlaceRecord?
    ) {
        for item in items {
            let trimmedName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else {
                continue
            }

            let parsedPrice = normalizedPriceField(from: item.priceText).flatMap(Double.init)

            let additionalEntry = FoodEntry(
                itemType: itemType,
                restaurantId: selectedRestaurantID,
                visitId: resolvedVisitID,
                dishId: nil,
                customDishName: trimmedName,
                date: resolvedDate,
                place: resolvedPlace,
                placeName: resolvedPlace?.displayName,
                price: parsedPrice,
                currency: parsedPrice != nil ? currency : nil,
                ratings: .empty,
                notes: nil,
                photoReferences: [],
                tags: [],
                sides: [],
                sauces: [],
                modifications: [],
                drinkPairing: nil,
                drinkSize: nil,
                drinkTemperature: nil,
                sweetnessLevel: nil,
                carbonationLevel: nil,
                strengthLevel: nil,
                brand: nil,
                storeName: nil,
                consistencyNotes: nil,
                wouldOrderAgain: false,
                highlighted: false,
                occasion: occasion,
                spiceLevel: nil,
                isBestVersion: false,
                neverOrderAgain: false
            )

            appState.addEntry(additionalEntry)
        }
    }

    private func cleanupDiscardedPhotosIfNeeded() {
        guard !didPersistChanges, !didRunDiscardCleanup else {
            return
        }

        didRunDiscardCleanup = true
        let photosToDelete = importedPhotoReferences.filter { !originalPhotoPaths.contains($0.relativePath) }

        guard !photosToDelete.isEmpty else {
            return
        }

        Task {
            await appState.deleteDraftPhotos(photosToDelete)
        }
    }

    private func mergePhotoReferences(_ existing: [PhotoReference], with imported: [PhotoReference]) -> [PhotoReference] {
        var seenPaths = Set(existing.map(\.relativePath))
        var merged = existing

        for reference in imported where !seenPaths.contains(reference.relativePath) {
            seenPaths.insert(reference.relativePath)
            merged.append(reference)
        }

        return merged
    }

    private func handleRemovedPhoto(_ reference: PhotoReference) {
        guard !originalPhotoPaths.contains(reference.relativePath) else {
            return
        }

        importedPhotoReferences.removeAll { $0.relativePath == reference.relativePath }
        Task {
            await appState.deleteDraftPhotos([reference])
        }
    }
}
