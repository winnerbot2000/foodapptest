import Foundation
import Combine
import PhotosUI

struct VisitSummary: Identifiable, Hashable {
    let id: UUID
    let restaurantId: UUID
    let date: Date
    let placeName: String?
    let itemCount: Int
}

/// Shared application state for the Food Journal.  Holds collections of
/// restaurants, dishes, entries and menus in memory and persists
/// changes through a `DataRepository`.  Provides convenience methods
/// for CRUD operations and seeding sample data.  Observed via the
/// `@EnvironmentObject` property wrapper in SwiftUI views.
@MainActor
final class AppState: ObservableObject {
    @Published private(set) var restaurants: [Restaurant] = []
    @Published private(set) var dishes: [Dish] = []
    @Published private(set) var entries: [FoodEntry] = []
    @Published private(set) var menus: [MenuRecord] = []
    @Published private(set) var storageErrorMessage: String?

    private let repository: DataRepository
    private let photoStorage = PhotoStorageService()

    /// Creates an app state and loads persisted data.  If no data is
    /// found on disk, sample data is loaded for an initial experience.
    init(repository: DataRepository = DataRepository()) {
        self.repository = repository
        let loadResult = repository.loadAll()
        if loadResult.restaurants.isEmpty && loadResult.dishes.isEmpty && loadResult.entries.isEmpty {
            // Seed with sample data on first launch
            restaurants = SampleData.restaurants()
            dishes = SampleData.dishes()
            entries = SampleData.entries(restaurants: restaurants, dishes: dishes)
            menus = []
            let didChangeRelationships = reconcileRelationships(updateTimestamps: false)
            let saveMessages = repository.saveAll(restaurants: restaurants, dishes: dishes, entries: entries, menus: menus)
            updateStorageMessage(with: loadResult.messages + saveMessages + (didChangeRelationships ? ["Sample data relationships were normalized on first launch."] : []))
        } else {
            restaurants = loadResult.restaurants
            dishes = loadResult.dishes
            entries = loadResult.entries
            menus = loadResult.menus

            if reconcileRelationships(updateTimestamps: false) {
                saveData(additionalMessages: loadResult.messages)
            } else {
                updateStorageMessage(with: loadResult.messages)
            }
        }

        Task { [weak self] in
            await self?.cleanupUnusedPhotos()
        }
    }

    /// Persists all collections to disk.  Called after each mutation.
    private func saveData(additionalMessages: [String] = []) {
        let messages = additionalMessages + repository.saveAll(
            restaurants: restaurants,
            dishes: dishes,
            entries: entries,
            menus: menus
        )
        updateStorageMessage(with: messages)
    }

    func restaurant(for id: UUID) -> Restaurant? {
        restaurants.first { $0.id == id }
    }

    func dish(for id: UUID) -> Dish? {
        dishes.first { $0.id == id }
    }

    func entry(for id: UUID) -> FoodEntry? {
        entries.first { $0.id == id }
    }

    func place(for entry: FoodEntry) -> PlaceRecord? {
        if let place = entry.place {
            return place
        }

        guard let trimmedPlace = entry.placeName?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmedPlace.isEmpty else {
            return nil
        }

        return PlaceRecord(
            displayName: trimmedPlace,
            source: .manual,
            restaurantId: entry.restaurantId
        )
    }

    func displayName(for entry: FoodEntry) -> String {
        if let dishId = entry.dishId, let dish = dish(for: dishId) {
            return dish.name
        }

        if let customName = entry.customDishName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !customName.isEmpty {
            return customName
        }

        return "Unknown Item"
    }

    func displayPlace(for entry: FoodEntry) -> String? {
        if let branch = displayBranch(for: entry) {
            return branch
        }

        if let restaurantId = entry.restaurantId, let restaurant = restaurant(for: restaurantId) {
            return restaurant.name
        }

        return place(for: entry)?.displayName
    }

    func displayBranch(for entry: FoodEntry) -> String? {
        guard let place = place(for: entry) else {
            return nil
        }

        if let restaurantId = entry.restaurantId,
           let restaurant = restaurant(for: restaurantId),
           normalizedPlaceKeyComponent(place.displayName) == normalizedPlaceKeyComponent(restaurant.name) {
            return place.secondaryText
        }

        return place.displayName
    }

    func recentPlaces(for restaurantId: UUID? = nil, limit: Int = 8) -> [PlaceRecord] {
        var latestPlaceByKey: [String: (place: PlaceRecord, date: Date)] = [:]

        for entry in entries.sorted(by: { $0.date > $1.date }) {
            guard var place = place(for: entry) else {
                continue
            }

            if let restaurantId, place.restaurantId != restaurantId {
                continue
            }

            place.restaurantId = place.restaurantId ?? entry.restaurantId
            let key = normalizedPlaceKey(for: place)
            let latestDate = latestPlaceByKey[key]?.date ?? .distantPast
            if entry.date >= latestDate {
                latestPlaceByKey[key] = (place, entry.date)
            }
        }

        return latestPlaceByKey.values
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map(\.place)
    }

    func visits(for restaurantId: UUID) -> [VisitSummary] {
        visitSummaries().values
            .filter { $0.restaurantId == restaurantId }
            .sorted { $0.date > $1.date }
    }

    func visit(for id: UUID) -> VisitSummary? {
        visitSummaries()[id]
    }

    private func updateStorageMessage(with messages: [String]) {
        let filteredMessages = messages.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        storageErrorMessage = filteredMessages.isEmpty ? nil : filteredMessages.joined(separator: "\n")
    }

    func importPhotos(
        from items: [PhotosPickerItem],
        owner: PhotoOwnerKind,
        ownerID: UUID
    ) async -> PhotoImportResult {
        let result = await photoStorage.importPhotos(from: items, owner: owner, ownerID: ownerID)
        if !result.messages.isEmpty {
            updateStorageMessage(with: result.messages)
        }
        return result
    }

    func loadPhotoData(_ reference: PhotoReference) async -> Data? {
        await photoStorage.loadData(for: reference)
    }

    func deleteDraftPhotos(_ references: [PhotoReference]) async {
        guard !references.isEmpty else {
            return
        }

        let messages = await photoStorage.deletePhotos(references)
        if !messages.isEmpty {
            updateStorageMessage(with: messages)
        }
    }

    private func visitSummaries() -> [UUID: VisitSummary] {
        var groupedEntries: [UUID: [FoodEntry]] = [:]
        for entry in entries {
            guard let visitId = entry.visitId, let restaurantId = entry.restaurantId else {
                continue
            }
            groupedEntries[visitId, default: []].append(entry)
        }

        return Dictionary(uniqueKeysWithValues: groupedEntries.compactMap { visitId, groupedEntries in
            guard let restaurantId = groupedEntries.compactMap(\.restaurantId).first else {
                return nil
            }

            let mostRecentDate = groupedEntries.map(\.date).max() ?? Date()
            let placeName = groupedEntries
                .compactMap { entry -> String? in
                    guard let place = place(for: entry) else {
                        return nil
                    }

                    if let restaurantId = entry.restaurantId,
                       let restaurant = restaurant(for: restaurantId),
                       normalizedPlaceKeyComponent(place.displayName) == normalizedPlaceKeyComponent(restaurant.name) {
                        return place.secondaryText
                    }

                    return place.displayName
                }
                .first { !$0.isEmpty }

            return (
                visitId,
                VisitSummary(
                    id: visitId,
                    restaurantId: restaurantId,
                    date: mostRecentDate,
                    placeName: placeName,
                    itemCount: groupedEntries.count
                )
            )
        })
    }

    @discardableResult
    private func reconcileRelationships(updateTimestamps: Bool) -> Bool {
        struct LegacyVisitBucket: Hashable {
            let restaurantId: UUID
            let dayStart: Date
            let placeName: String?
        }

        let now = Date()
        let calendar = Calendar.current
        let restaurantIDs = Set(restaurants.map(\.id))
        let dishIDs = Set(dishes.map(\.id))
        var changed = false
        var flaggedEntryIndexesByDish: [UUID: [Int]] = [:]
        var generatedVisitIDsByBucket: [LegacyVisitBucket: UUID] = [:]

        func normalizedOptionalText(_ text: String?) -> String? {
            guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
                return nil
            }
            return trimmed
        }

        func normalizedTextArray(_ values: [String]) -> [String] {
            values
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }

        func normalizedPlace(
            _ place: PlaceRecord?,
            legacyPlaceName: String?,
            restaurantId: UUID?
        ) -> PlaceRecord? {
            var normalizedPlace = place

            if normalizedPlace == nil, let legacyPlaceName = normalizedOptionalText(legacyPlaceName) {
                normalizedPlace = PlaceRecord(
                    displayName: legacyPlaceName,
                    source: .manual,
                    restaurantId: restaurantId
                )
            }

            guard var place = normalizedPlace else {
                return nil
            }

            let normalizedDisplayName = normalizedOptionalText(place.displayName)
            let normalizedAddress = normalizedOptionalText(place.addressText)
            let normalizedLocality = normalizedOptionalText(place.localityText)

            place.displayName = normalizedDisplayName
                ?? normalizedAddress
                ?? normalizedLocality
                ?? (restaurantId.flatMap { id in restaurants.first(where: { $0.id == id })?.name })
                ?? "Pinned Location"
            place.addressText = normalizedAddress
            place.localityText = normalizedLocality
            place.restaurantId = restaurantId

            if place.latitude == nil || place.longitude == nil {
                place.latitude = nil
                place.longitude = nil
            }

            let hasVisibleText = !place.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            guard hasVisibleText || place.hasCoordinates else {
                return nil
            }

            return place
        }

        func normalizedPhotoReferences(_ references: [PhotoReference]) -> [PhotoReference] {
            var seenPaths: Set<String> = []

            return references.compactMap { reference in
                let trimmedPath = reference.relativePath.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedPath.isEmpty, !seenPaths.contains(trimmedPath) else {
                    return nil
                }

                seenPaths.insert(trimmedPath)

                var normalizedReference = reference
                normalizedReference.relativePath = trimmedPath
                return normalizedReference
            }
        }

        for index in entries.indices {
            var entry = entries[index]
            let originalEntry = entry

            if entry.itemType != .dish {
                entry.dishId = nil
                entry.isBestVersion = false
            }

            if let restaurantId = entry.restaurantId, !restaurantIDs.contains(restaurantId) {
                entry.restaurantId = nil
            }

            if let dishId = entry.dishId, !dishIDs.contains(dishId) {
                entry.dishId = nil
                entry.isBestVersion = false
            }

            entry.customDishName = normalizedOptionalText(entry.customDishName)
            entry.notes = normalizedOptionalText(entry.notes)
            entry.drinkPairing = normalizedOptionalText(entry.drinkPairing)
            entry.brand = normalizedOptionalText(entry.brand)
            entry.storeName = normalizedOptionalText(entry.storeName)
            entry.consistencyNotes = normalizedOptionalText(entry.consistencyNotes)
            entry.place = normalizedPlace(
                entry.place,
                legacyPlaceName: entry.placeName,
                restaurantId: entry.restaurantId
            )
            entry.placeName = entry.place?.displayName
            entry.photoReferences = normalizedPhotoReferences(entry.photoReferences)
            entry.tags = normalizedTextArray(entry.tags)
            entry.sides = normalizedTextArray(entry.sides)
            entry.sauces = normalizedTextArray(entry.sauces)
            entry.modifications = normalizedTextArray(entry.modifications)

            if entry.itemType != .drink {
                entry.drinkPairing = nil
                entry.drinkSize = nil
                entry.drinkTemperature = nil
                entry.sweetnessLevel = nil
                entry.carbonationLevel = nil
                entry.strengthLevel = nil
            }

            if entry.itemType != .product {
                entry.brand = nil
                entry.storeName = nil
                entry.consistencyNotes = nil
            }

            if entry.restaurantId == nil {
                entry.visitId = nil
                entry.place?.restaurantId = nil
            } else if let restaurantId = entry.restaurantId, entry.visitId == nil {
                let bucket = LegacyVisitBucket(
                    restaurantId: restaurantId,
                    dayStart: calendar.startOfDay(for: entry.date),
                    placeName: entry.place?.displayName.lowercased()
                )
                let visitId = generatedVisitIDsByBucket[bucket] ?? UUID()
                generatedVisitIDsByBucket[bucket] = visitId
                entry.visitId = visitId
            }

            if let dishId = entry.dishId, entry.isBestVersion {
                flaggedEntryIndexesByDish[dishId, default: []].append(index)
            }

            if entry != originalEntry {
                if updateTimestamps {
                    entry.updatedAt = now
                }
                entries[index] = entry
                changed = true
            }
        }

        for entryIndexes in flaggedEntryIndexesByDish.values where entryIndexes.count > 1 {
            guard let selectedIndex = entryIndexes.max(by: { lhs, rhs in
                let leftEntry = entries[lhs]
                let rightEntry = entries[rhs]
                if leftEntry.date == rightEntry.date {
                    return leftEntry.updatedAt < rightEntry.updatedAt
                }
                return leftEntry.date < rightEntry.date
            }) else {
                continue
            }

            for index in entryIndexes where index != selectedIndex {
                entries[index].isBestVersion = false
                if updateTimestamps {
                    entries[index].updatedAt = now
                }
                changed = true
            }
        }

        var visitDatesByRestaurant: [UUID: [Date]] = [:]
        var visitDateByRestaurantAndVisit: [UUID: [UUID: Date]] = [:]
        var bestEntryByDish: [UUID: FoodEntry] = [:]

        for entry in entries {
            if let restaurantId = entry.restaurantId, let visitId = entry.visitId {
                if let currentDate = visitDateByRestaurantAndVisit[restaurantId]?[visitId] {
                    if entry.date > currentDate {
                        visitDateByRestaurantAndVisit[restaurantId, default: [:]][visitId] = entry.date
                    }
                } else {
                    visitDateByRestaurantAndVisit[restaurantId, default: [:]][visitId] = entry.date
                }
            }

            guard entry.itemType == .dish, let dishId = entry.dishId, entry.isBestVersion else {
                continue
            }

            if let existingBestEntry = bestEntryByDish[dishId] {
                if entry.date > existingBestEntry.date || (entry.date == existingBestEntry.date && entry.updatedAt > existingBestEntry.updatedAt) {
                    bestEntryByDish[dishId] = entry
                }
            } else {
                bestEntryByDish[dishId] = entry
            }
        }

        for (restaurantId, visitMap) in visitDateByRestaurantAndVisit {
            visitDatesByRestaurant[restaurantId] = visitMap.values.sorted(by: >)
        }

        for index in restaurants.indices {
            var restaurant = restaurants[index]
            let originalRestaurant = restaurant
            restaurant.photoReferences = normalizedPhotoReferences(restaurant.photoReferences)
            restaurant.visitDates = (visitDatesByRestaurant[restaurant.id] ?? []).sorted(by: >)

            if restaurant != originalRestaurant {
                if updateTimestamps {
                    restaurant.updatedAt = now
                }
                restaurants[index] = restaurant
                changed = true
            }
        }

        for index in dishes.indices {
            var dish = dishes[index]
            let originalDish = dish
            dish.photoReferences = normalizedPhotoReferences(dish.photoReferences)
            dish.bestEntryId = bestEntryByDish[dish.id]?.id

            if dish != originalDish {
                if updateTimestamps {
                    dish.updatedAt = now
                }
                dishes[index] = dish
                changed = true
            }
        }

        return changed
    }

    // MARK: - Restaurant CRUD

    func addRestaurant(_ restaurant: Restaurant) {
        var restaurant = restaurant
        restaurant.updatedAt = restaurant.createdAt
        restaurants.append(restaurant)
        saveData()
    }

    func updateRestaurant(_ restaurant: Restaurant) {
        if let index = restaurants.firstIndex(where: { $0.id == restaurant.id }) {
            let removedPhotos = removedPhotoReferences(
                from: restaurants[index].photoReferences,
                comparedTo: restaurant.photoReferences
            )
            var updatedRestaurant = restaurant
            updatedRestaurant.createdAt = restaurants[index].createdAt
            updatedRestaurant.updatedAt = Date()
            restaurants[index] = updatedRestaurant
            saveData()
            schedulePhotoDeletion(removedPhotos)
        }
    }

    func deleteRestaurant(_ restaurant: Restaurant) {
        let removedEntries = entries.filter { $0.restaurantId == restaurant.id }
        restaurants.removeAll { $0.id == restaurant.id }
        entries.removeAll { $0.restaurantId == restaurant.id }
        _ = reconcileRelationships(updateTimestamps: true)
        saveData()
        scheduleOwnerPhotoDeletion(owner: .restaurant, ownerID: restaurant.id)
        for entry in removedEntries {
            scheduleOwnerPhotoDeletion(owner: .entry, ownerID: entry.id)
        }
    }

    // MARK: - Dish CRUD

    func addDish(_ dish: Dish) {
        var dish = dish
        dish.updatedAt = dish.createdAt
        dishes.append(dish)
        saveData()
    }

    func updateDish(_ dish: Dish) {
        if let index = dishes.firstIndex(where: { $0.id == dish.id }) {
            let removedPhotos = removedPhotoReferences(
                from: dishes[index].photoReferences,
                comparedTo: dish.photoReferences
            )
            var updatedDish = dish
            updatedDish.createdAt = dishes[index].createdAt
            updatedDish.updatedAt = Date()
            dishes[index] = updatedDish
            saveData()
            schedulePhotoDeletion(removedPhotos)
        }
    }

    func deleteDish(_ dish: Dish) {
        let removedEntries = entries.filter { $0.dishId == dish.id }
        dishes.removeAll { $0.id == dish.id }
        entries.removeAll { $0.dishId == dish.id }
        _ = reconcileRelationships(updateTimestamps: true)
        saveData()
        scheduleOwnerPhotoDeletion(owner: .dish, ownerID: dish.id)
        for entry in removedEntries {
            scheduleOwnerPhotoDeletion(owner: .entry, ownerID: entry.id)
        }
    }

    // MARK: - Entry CRUD

    func addEntry(_ entry: FoodEntry) {
        var entry = entry
        entry.updatedAt = entry.createdAt
        entries.append(entry)
        _ = reconcileRelationships(updateTimestamps: true)
        saveData()
    }

    func updateEntry(_ entry: FoodEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            let removedPhotos = removedPhotoReferences(
                from: entries[index].photoReferences,
                comparedTo: entry.photoReferences
            )
            var updatedEntry = entry
            updatedEntry.createdAt = entries[index].createdAt
            updatedEntry.updatedAt = Date()
            entries[index] = updatedEntry
            _ = reconcileRelationships(updateTimestamps: true)
            saveData()
            schedulePhotoDeletion(removedPhotos)
        }
    }

    func deleteEntry(_ entry: FoodEntry) {
        entries.removeAll { $0.id == entry.id }
        _ = reconcileRelationships(updateTimestamps: true)
        saveData()
        scheduleOwnerPhotoDeletion(owner: .entry, ownerID: entry.id)
    }

    // MARK: - Menu Records

    func addMenuRecord(_ menu: MenuRecord) {
        menus.append(menu)
        saveData()
    }

    // MARK: - Convenience Creators

    /// Creates a new restaurant and immediately adds it to the state.
    @discardableResult
    func createRestaurant(name: String, location: String, cuisineTags: [String], notes: String?) -> Restaurant {
        let normalizedTags = cuisineTags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let restaurant = Restaurant(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            locationText: location.trimmingCharacters(in: .whitespacesAndNewlines),
            cuisineTags: normalizedTags,
            notes: notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        addRestaurant(restaurant)
        return restaurant
    }

    /// Creates a new dish and immediately adds it to the state.
    @discardableResult
    func createDish(name: String, category: DishCategory, subcategory: String?, notes: String?) -> Dish {
        let dish = Dish(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            subcategory: subcategory?.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        addDish(dish)
        return dish
    }

    // MARK: - Data Reset

    /// Resets all data to the provided sample sets.  Intended for
    /// debugging or user‑initiated resets via Settings.
    func resetSampleData() {
        restaurants = SampleData.restaurants()
        dishes = SampleData.dishes()
        entries = SampleData.entries(restaurants: restaurants, dishes: dishes)
        menus = []
        _ = reconcileRelationships(updateTimestamps: false)
        saveData()
        scheduleDeleteAllManagedPhotos()
    }

    /// Clears all collections and saves an empty state.
    func clearAllData() {
        restaurants = []
        dishes = []
        entries = []
        menus = []
        saveData()
        scheduleDeleteAllManagedPhotos()
    }

    private func removedPhotoReferences(from oldReferences: [PhotoReference], comparedTo newReferences: [PhotoReference]) -> [PhotoReference] {
        let newPaths = Set(newReferences.map(\.relativePath))
        return oldReferences.filter { !newPaths.contains($0.relativePath) }
    }

    private func schedulePhotoDeletion(_ references: [PhotoReference]) {
        guard !references.isEmpty else {
            return
        }

        Task { [photoStorage] in
            let messages = await photoStorage.deletePhotos(references)
            await MainActor.run {
                if !messages.isEmpty {
                    self.updateStorageMessage(with: messages)
                }
            }
        }
    }

    private func scheduleOwnerPhotoDeletion(owner: PhotoOwnerKind, ownerID: UUID) {
        Task { [photoStorage] in
            let messages = await photoStorage.deleteAllPhotos(for: owner, ownerID: ownerID)
            await MainActor.run {
                if !messages.isEmpty {
                    self.updateStorageMessage(with: messages)
                }
            }
        }
    }

    private func scheduleDeleteAllManagedPhotos() {
        Task { [photoStorage] in
            let messages = await photoStorage.deleteAllManagedPhotos()
            await MainActor.run {
                if !messages.isEmpty {
                    self.updateStorageMessage(with: messages)
                }
            }
        }
    }

    private func cleanupUnusedPhotos() async {
        let referencedPaths = Set(
            entries.flatMap(\.photoReferences).map(\.relativePath)
            + dishes.flatMap(\.photoReferences).map(\.relativePath)
            + restaurants.flatMap(\.photoReferences).map(\.relativePath)
        )

        let messages = await photoStorage.cleanupUnusedFiles(referencedRelativePaths: referencedPaths)
        if !messages.isEmpty {
            updateStorageMessage(with: messages)
        }
    }

    private func normalizedPlaceKey(for place: PlaceRecord) -> String {
        [
            normalizedPlaceKeyComponent(place.displayName),
            normalizedPlaceKeyComponent(place.addressText),
            normalizedPlaceKeyComponent(place.localityText),
            place.restaurantId?.uuidString.lowercased() ?? "no-brand",
            roundedCoordinateComponent(place.latitude),
            roundedCoordinateComponent(place.longitude)
        ]
        .joined(separator: "|")
    }

    private func normalizedPlaceKeyComponent(_ value: String?) -> String {
        value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
    }

    private func roundedCoordinateComponent(_ value: Double?) -> String {
        guard let value else {
            return ""
        }

        return String(format: "%.4f", value)
    }
}
