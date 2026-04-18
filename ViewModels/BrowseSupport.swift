import Foundation

enum JournalDateRange: String, CaseIterable, Identifiable {
    case allTime
    case last7Days
    case last30Days
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .allTime:
            return "All Time"
        case .last7Days:
            return "Last 7 Days"
        case .last30Days:
            return "Last 30 Days"
        case .custom:
            return "Custom"
        }
    }

    func contains(_ date: Date, startDate: Date, endDate: Date, now: Date = Date()) -> Bool {
        let calendar = Calendar.current

        switch self {
        case .allTime:
            return true
        case .last7Days:
            guard let cutoff = calendar.date(byAdding: .day, value: -7, to: now) else {
                return true
            }
            return date >= cutoff
        case .last30Days:
            guard let cutoff = calendar.date(byAdding: .day, value: -30, to: now) else {
                return true
            }
            return date >= cutoff
        case .custom:
            let normalizedStart = calendar.startOfDay(for: min(startDate, endDate))
            let normalizedEndDay = calendar.startOfDay(for: max(startDate, endDate))
            guard let exclusiveEnd = calendar.date(byAdding: .day, value: 1, to: normalizedEndDay) else {
                return date >= normalizedStart
            }
            return date >= normalizedStart && date < exclusiveEnd
        }
    }
}

enum JournalRestaurantAttachmentFilter: String, CaseIterable, Identifiable {
    case all
    case attached
    case standalone

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:
            return "All Items"
        case .attached:
            return "Restaurant Attached"
        case .standalone:
            return "Standalone"
        }
    }
}

enum JournalSortOption: String, CaseIterable, Identifiable {
    case newestFirst
    case oldestFirst
    case highestTaste
    case highestOverall
    case alphabetical

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .newestFirst:
            return "Newest First"
        case .oldestFirst:
            return "Oldest First"
        case .highestTaste:
            return "Highest Taste"
        case .highestOverall:
            return "Highest Overall"
        case .alphabetical:
            return "Alphabetical"
        }
    }
}

struct JournalFilterState: Equatable {
    var itemType: ItemType?
    var dateRange: JournalDateRange = .allTime
    var customStartDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    var customEndDate: Date = Date()
    var minimumTaste: Int = 0
    var minimumQuality: Int = 0
    var minimumValue: Int = 0
    var restaurantAttachment: JournalRestaurantAttachmentFilter = .all

    var activeFilterCount: Int {
        activeFilterTokens.count
    }

    var hasActiveFilters: Bool {
        activeFilterCount > 0
    }

    var activeFilterTokens: [String] {
        var tokens: [String] = []

        if let itemType {
            tokens.append(itemType.displayName)
        }

        if dateRange != .allTime {
            tokens.append(dateRange.displayName)
        }

        if minimumTaste > 0 {
            tokens.append("Taste \(minimumTaste)+")
        }

        if minimumQuality > 0 {
            tokens.append("Quality \(minimumQuality)+")
        }

        if minimumValue > 0 {
            tokens.append("Value \(minimumValue)+")
        }

        if restaurantAttachment != .all {
            tokens.append(restaurantAttachment.displayName)
        }

        return tokens
    }
}

enum ItemBrowseScope: String, CaseIterable, Identifiable {
    case dishes
    case products
    case drinks

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dishes:
            return "Dishes"
        case .products:
            return "Products"
        case .drinks:
            return "Drinks"
        }
    }

    var itemType: ItemType {
        switch self {
        case .dishes:
            return .dish
        case .products:
            return .product
        case .drinks:
            return .drink
        }
    }
}

enum ItemBrowseSortOption: String, CaseIterable, Identifiable {
    case alphabetical
    case recentlyTried
    case highestOverall
    case mostLogged

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .alphabetical:
            return "Alphabetical"
        case .recentlyTried:
            return "Recently Tried"
        case .highestOverall:
            return "Highest Rated"
        case .mostLogged:
            return "Most Logged"
        }
    }
}

enum RestaurantBrowseSortOption: String, CaseIterable, Identifiable {
    case mostVisited
    case newestAdded
    case alphabetical
    case mostRecentVisit

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mostVisited:
            return "Most Visited"
        case .newestAdded:
            return "Newest Added"
        case .alphabetical:
            return "Alphabetical"
        case .mostRecentVisit:
            return "Most Recent Visit"
        }
    }
}

struct LoggedItemSummary: Identifiable, Hashable {
    let id: String
    let itemType: ItemType
    let name: String
    let subtitle: String?
    let logCount: Int
    let restaurantCount: Int
    let lastTried: Date?
    let bestOverallRating: Int
    let averageOverallRating: Double
    let photoReference: PhotoReference?
    let entryIDs: [UUID]
    let dishID: UUID?
}

struct RestaurantBrowseSummary: Identifiable, Hashable {
    let restaurant: Restaurant
    let itemCount: Int
    let visitCount: Int
    let lastVisitDate: Date?
    let averageOverallRating: Double
    let bestItemName: String?
    let photoReference: PhotoReference?

    var id: UUID { restaurant.id }
}

extension AppState {
    func filteredJournalEntries(
        searchText: String,
        filters: JournalFilterState,
        sort: JournalSortOption
    ) -> [FoodEntry] {
        let normalizedTerms = normalizedSearchTerms(from: searchText)

        let filteredEntries = entries.filter { entry in
            if let itemType = filters.itemType, entry.itemType != itemType {
                return false
            }

            if !filters.dateRange.contains(
                entry.date,
                startDate: filters.customStartDate,
                endDate: filters.customEndDate
            ) {
                return false
            }

            if entry.ratings.taste < filters.minimumTaste
                || entry.ratings.quality < filters.minimumQuality
                || entry.ratings.value < filters.minimumValue {
                return false
            }

            switch filters.restaurantAttachment {
            case .all:
                break
            case .attached:
                guard entry.restaurantId != nil else {
                    return false
                }
            case .standalone:
                guard entry.restaurantId == nil else {
                    return false
                }
            }

            guard !normalizedTerms.isEmpty else {
                return true
            }

            let searchableText = [
                displayName(for: entry),
                entry.restaurantId.flatMap { restaurant(for: $0)?.name },
                displayPlace(for: entry),
                entry.notes,
                entry.sides.joined(separator: " "),
                entry.sauces.joined(separator: " "),
                entry.modifications.joined(separator: " "),
                entry.drinkPairing,
                entry.brand,
                entry.storeName,
                entry.consistencyNotes,
                entry.tags.joined(separator: " ")
            ]
            .compactMap { $0 }
            .joined(separator: " ")

            return matchesSearchTerms(normalizedTerms, in: searchableText)
        }

        return filteredEntries.sorted { lhs, rhs in
            switch sort {
            case .newestFirst:
                return compareDatesDescending(lhs.date, rhs.date, fallback: compareNamesAscending(lhs, rhs))
            case .oldestFirst:
                return compareDatesAscending(lhs.date, rhs.date, fallback: compareNamesAscending(lhs, rhs))
            case .highestTaste:
                if lhs.ratings.taste != rhs.ratings.taste {
                    return lhs.ratings.taste > rhs.ratings.taste
                }
                return compareDatesDescending(lhs.date, rhs.date, fallback: compareNamesAscending(lhs, rhs))
            case .highestOverall:
                if lhs.ratings.overall != rhs.ratings.overall {
                    return lhs.ratings.overall > rhs.ratings.overall
                }
                return compareDatesDescending(lhs.date, rhs.date, fallback: compareNamesAscending(lhs, rhs))
            case .alphabetical:
                let comparison = displayName(for: lhs).localizedCaseInsensitiveCompare(displayName(for: rhs))
                if comparison != .orderedSame {
                    return comparison == .orderedAscending
                }
                return compareDatesDescending(lhs.date, rhs.date, fallback: false)
            }
        }
    }

    func itemSummaries(
        for scope: ItemBrowseScope,
        searchText: String,
        sort: ItemBrowseSortOption
    ) -> [LoggedItemSummary] {
        let normalizedTerms = normalizedSearchTerms(from: searchText)

        let summaries: [LoggedItemSummary]
        switch scope {
        case .dishes:
            summaries = savedDishSummaries() + customDishSummaries()
        case .products, .drinks:
            summaries = groupedEntrySummaries(for: scope.itemType)
        }

        let filteredSummaries = summaries.filter { summary in
            guard !normalizedTerms.isEmpty else {
                return true
            }

            let searchText = [
                summary.name,
                summary.subtitle,
                summary.entryIDs
                    .compactMap(entry(for:))
                    .compactMap { entry in
                        [
                            entry.restaurantId.flatMap { restaurant(for: $0)?.name },
                            displayPlace(for: entry),
                            entry.notes,
                            entry.brand,
                            entry.storeName
                        ]
                        .compactMap { $0 }
                        .joined(separator: " ")
                    }
                    .joined(separator: " ")
            ]
            .compactMap { $0 }
            .joined(separator: " ")

            return matchesSearchTerms(normalizedTerms, in: searchText)
        }

        return filteredSummaries.sorted { lhs, rhs in
            switch sort {
            case .alphabetical:
                let comparison = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
                if comparison != .orderedSame {
                    return comparison == .orderedAscending
                }
                return compareDatesDescending(lhs.lastTried, rhs.lastTried, fallback: lhs.logCount > rhs.logCount)
            case .recentlyTried:
                return compareDatesDescending(lhs.lastTried, rhs.lastTried, fallback: compareNamesAscending(lhs.name, rhs.name))
            case .highestOverall:
                if lhs.bestOverallRating != rhs.bestOverallRating {
                    return lhs.bestOverallRating > rhs.bestOverallRating
                }
                if lhs.averageOverallRating != rhs.averageOverallRating {
                    return lhs.averageOverallRating > rhs.averageOverallRating
                }
                return compareNamesAscending(lhs.name, rhs.name)
            case .mostLogged:
                if lhs.logCount != rhs.logCount {
                    return lhs.logCount > rhs.logCount
                }
                return compareDatesDescending(lhs.lastTried, rhs.lastTried, fallback: compareNamesAscending(lhs.name, rhs.name))
            }
        }
    }

    func restaurantSummaries(
        searchText: String,
        sort: RestaurantBrowseSortOption
    ) -> [RestaurantBrowseSummary] {
        let normalizedTerms = normalizedSearchTerms(from: searchText)

        let summaries = restaurants.map { restaurant in
            let restaurantEntries = entries.filter { $0.restaurantId == restaurant.id }
            let visitCount = Set(restaurantEntries.compactMap(\.visitId)).count
            let lastVisitDate = restaurantEntries.map(\.date).max()
            let averageOverallRating: Double
            if restaurantEntries.isEmpty {
                averageOverallRating = 0
            } else {
                let total = restaurantEntries.reduce(0.0) { partialResult, entry in
                    partialResult + Double(entry.ratings.overall)
                }
                averageOverallRating = total / Double(restaurantEntries.count)
            }

            let bestItemName = restaurantEntries
                .sorted {
                    if $0.ratings.overall == $1.ratings.overall {
                        return $0.date > $1.date
                    }
                    return $0.ratings.overall > $1.ratings.overall
                }
                .first
                .map(displayName(for:))

            let photoReference = restaurant.photoReferences.first
                ?? restaurantEntries
                .sorted(by: { $0.date > $1.date })
                .compactMap { $0.photoReferences.first }
                .first

            return RestaurantBrowseSummary(
                restaurant: restaurant,
                itemCount: restaurantEntries.count,
                visitCount: visitCount,
                lastVisitDate: lastVisitDate,
                averageOverallRating: averageOverallRating,
                bestItemName: bestItemName,
                photoReference: photoReference
            )
        }

        let filteredSummaries = summaries.filter { summary in
            guard !normalizedTerms.isEmpty else {
                return true
            }

            let matchingEntries = entries.filter { $0.restaurantId == summary.restaurant.id }
            let branchText = matchingEntries
                .compactMap { displayBranch(for: $0) }
                .joined(separator: " ")

            let searchableText = [
                summary.restaurant.name,
                summary.restaurant.locationText,
                summary.restaurant.notes,
                summary.restaurant.cuisineTags.joined(separator: " "),
                summary.bestItemName,
                branchText
            ]
            .compactMap { $0 }
            .joined(separator: " ")

            return matchesSearchTerms(normalizedTerms, in: searchableText)
        }

        return filteredSummaries.sorted { lhs, rhs in
            switch sort {
            case .mostVisited:
                if lhs.visitCount != rhs.visitCount {
                    return lhs.visitCount > rhs.visitCount
                }
                if lhs.itemCount != rhs.itemCount {
                    return lhs.itemCount > rhs.itemCount
                }
                return compareNamesAscending(lhs.restaurant.name, rhs.restaurant.name)
            case .newestAdded:
                return compareDatesDescending(lhs.restaurant.createdAt, rhs.restaurant.createdAt, fallback: compareNamesAscending(lhs.restaurant.name, rhs.restaurant.name))
            case .alphabetical:
                return compareNamesAscending(lhs.restaurant.name, rhs.restaurant.name)
            case .mostRecentVisit:
                return compareDatesDescending(lhs.lastVisitDate, rhs.lastVisitDate, fallback: compareNamesAscending(lhs.restaurant.name, rhs.restaurant.name))
            }
        }
    }

    private func savedDishSummaries() -> [LoggedItemSummary] {
        let entriesByDish = Dictionary(grouping: entries.filter { $0.itemType == .dish && $0.dishId != nil }) { entry in
            entry.dishId ?? UUID()
        }

        return dishes.map { dish in
            let dishEntries = entriesByDish[dish.id] ?? []
            let restaurantCount = Set(dishEntries.compactMap(\.restaurantId)).count
            let averageOverallRating: Double
            if dishEntries.isEmpty {
                averageOverallRating = 0
            } else {
                let total = dishEntries.reduce(0.0) { $0 + Double($1.ratings.overall) }
                averageOverallRating = total / Double(dishEntries.count)
            }

            let subtitleComponents = [dish.category.displayName, dish.subcategory]
                .compactMap { component -> String? in
                    guard let component = component?.trimmingCharacters(in: .whitespacesAndNewlines), !component.isEmpty else {
                        return nil
                    }
                    return component
                }

            return LoggedItemSummary(
                id: "dish-\(dish.id.uuidString)",
                itemType: .dish,
                name: dish.name,
                subtitle: subtitleComponents.joined(separator: " • "),
                logCount: dishEntries.count,
                restaurantCount: restaurantCount,
                lastTried: dishEntries.map(\.date).max(),
                bestOverallRating: dishEntries.map(\.ratings.overall).max() ?? 0,
                averageOverallRating: averageOverallRating,
                photoReference: dish.photoReferences.first
                    ?? dishEntries.sorted(by: { $0.date > $1.date }).compactMap { $0.photoReferences.first }.first,
                entryIDs: dishEntries.map(\.id),
                dishID: dish.id
            )
        }
    }

    private func groupedEntrySummaries(for itemType: ItemType) -> [LoggedItemSummary] {
        let relevantEntries = entries.filter { $0.itemType == itemType }
        var groupedEntries: [String: [FoodEntry]] = [:]

        for entry in relevantEntries {
            let name = displayName(for: entry)
            let keyComponents: [String]
            if itemType == .product {
                keyComponents = [
                    normalizedSearchComponent(name),
                    normalizedSearchComponent(entry.brand),
                    normalizedSearchComponent(entry.storeName)
                ]
            } else {
                keyComponents = [normalizedSearchComponent(name)]
            }

            let key = keyComponents.joined(separator: "|")
            groupedEntries[key, default: []].append(entry)
        }

        return groupedEntries.values.compactMap { groupedEntries in
            let sortedEntries = groupedEntries.sorted(by: { $0.date > $1.date })
            guard let representativeEntry = sortedEntries.first else {
                return nil
            }

            let name = displayName(for: representativeEntry)
            let subtitle: String?
            switch itemType {
            case .dish:
                subtitle = nil
            case .product:
                let components = [representativeEntry.brand, representativeEntry.storeName]
                    .compactMap { component -> String? in
                        guard let component = component?.trimmingCharacters(in: .whitespacesAndNewlines), !component.isEmpty else {
                            return nil
                        }
                        return component
                    }
                subtitle = components.isEmpty ? displayPlace(for: representativeEntry) : components.joined(separator: " • ")
            case .drink:
                subtitle = representativeEntry.restaurantId.flatMap { restaurant(for: $0)?.name }
                    ?? displayPlace(for: representativeEntry)
            }

            let restaurantCount = Set(sortedEntries.compactMap(\.restaurantId)).count
            let averageOverallRating = sortedEntries.isEmpty
                ? 0
                : sortedEntries.reduce(0.0) { $0 + Double($1.ratings.overall) } / Double(sortedEntries.count)

            return LoggedItemSummary(
                id: "\(itemType.rawValue)-\(normalizedSearchComponent(name))-\(normalizedSearchComponent(representativeEntry.brand))-\(normalizedSearchComponent(representativeEntry.storeName))",
                itemType: itemType,
                name: name,
                subtitle: subtitle,
                logCount: sortedEntries.count,
                restaurantCount: restaurantCount,
                lastTried: sortedEntries.first?.date,
                bestOverallRating: sortedEntries.map(\.ratings.overall).max() ?? 0,
                averageOverallRating: averageOverallRating,
                photoReference: sortedEntries.compactMap { $0.photoReferences.first }.first,
                entryIDs: sortedEntries.map(\.id),
                dishID: nil
            )
        }
    }

    private func customDishSummaries() -> [LoggedItemSummary] {
        let customDishEntries = entries.filter { $0.itemType == .dish && $0.dishId == nil }
        var groupedEntries: [String: [FoodEntry]] = [:]

        for entry in customDishEntries {
            let key = normalizedSearchComponent(displayName(for: entry))
            groupedEntries[key, default: []].append(entry)
        }

        return groupedEntries.values.compactMap { groupedEntries in
            let sortedEntries = groupedEntries.sorted(by: { $0.date > $1.date })
            guard let representativeEntry = sortedEntries.first else {
                return nil
            }

            let restaurantCount = Set(sortedEntries.compactMap(\.restaurantId)).count
            let averageOverallRating = sortedEntries.reduce(0.0) { $0 + Double($1.ratings.overall) } / Double(sortedEntries.count)

            return LoggedItemSummary(
                id: "custom-dish-\(normalizedSearchComponent(displayName(for: representativeEntry)))",
                itemType: .dish,
                name: displayName(for: representativeEntry),
                subtitle: "Logged Dish",
                logCount: sortedEntries.count,
                restaurantCount: restaurantCount,
                lastTried: sortedEntries.first?.date,
                bestOverallRating: sortedEntries.map(\.ratings.overall).max() ?? 0,
                averageOverallRating: averageOverallRating,
                photoReference: sortedEntries.compactMap { $0.photoReferences.first }.first,
                entryIDs: sortedEntries.map(\.id),
                dishID: nil
            )
        }
    }

    private func normalizedSearchTerms(from searchText: String) -> [String] {
        searchText
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    private func matchesSearchTerms(_ terms: [String], in value: String) -> Bool {
        let searchableValue = value.lowercased()
        return terms.allSatisfy { searchableValue.contains($0) }
    }

    private func normalizedSearchComponent(_ value: String?) -> String {
        guard let value else {
            return ""
        }

        return value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func compareDatesDescending(_ lhs: Date?, _ rhs: Date?, fallback: Bool) -> Bool {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            if lhs != rhs {
                return lhs > rhs
            }
            return fallback
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            return fallback
        }
    }

    private func compareDatesAscending(_ lhs: Date?, _ rhs: Date?, fallback: Bool) -> Bool {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            if lhs != rhs {
                return lhs < rhs
            }
            return fallback
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            return fallback
        }
    }

    private func compareNamesAscending(_ lhs: FoodEntry, _ rhs: FoodEntry) -> Bool {
        compareNamesAscending(displayName(for: lhs), displayName(for: rhs))
    }

    private func compareNamesAscending(_ lhs: String, _ rhs: String) -> Bool {
        let comparison = lhs.localizedCaseInsensitiveCompare(rhs)
        return comparison == .orderedAscending
    }
}
