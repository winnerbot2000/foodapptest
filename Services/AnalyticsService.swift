import Foundation

/// Computes personal insights from the user’s food data.  All methods
/// operate on collections passed by the caller and never mutate
/// state.  Insights are strictly personal and make no external API calls.
public struct AnalyticsService {
    private static func visitCount(for entries: [FoodEntry]) -> Int {
        let uniqueVisitIDs = Set(entries.compactMap { $0.visitId })
        if !uniqueVisitIDs.isEmpty {
            return uniqueVisitIDs.count
        }
        return entries.count
    }

    /// Returns the top rated dishes sorted by average overall rating.
    /// Dishes with no ratings are excluded.  The limit parameter caps
    /// the result count.
    public static func topRatedDishes(entries: [FoodEntry], dishes: [Dish], limit: Int = 5) -> [(dish: Dish, averageScore: Double)] {
        let entriesByDish = Dictionary(grouping: entries) { $0.dishId }
        var results: [(Dish, Double)] = []
        for dish in dishes {
            guard let list = entriesByDish[dish.id], !list.isEmpty else { continue }
            let total = list.reduce(0.0) { $0 + Double($1.ratings.overall) }
            let average = total / Double(list.count)
            results.append((dish, average))
        }
        return results.sorted { $0.1 > $1.1 }.prefix(limit).map { $0 }
    }

    /// Returns restaurants sorted by visit frequency in descending order.
    public static func mostVisitedRestaurants(entries: [FoodEntry], restaurants: [Restaurant], limit: Int = 5) -> [(restaurant: Restaurant, visits: Int)] {
        let entriesByRestaurant = Dictionary(grouping: entries) { $0.restaurantId }
        var results: [(Restaurant, Int)] = []
        for restaurant in restaurants {
            guard let list = entriesByRestaurant[restaurant.id], !list.isEmpty else { continue }
            results.append((restaurant, visitCount(for: list)))
        }
        return results.sorted { $0.1 > $1.1 }.prefix(limit).map { $0 }
    }

    /// Computes average overall rating by dish category.  Categories with no
    /// entries are omitted.  Returns a dictionary keyed by category.
    public static func averageScoreByCategory(entries: [FoodEntry], dishes: [Dish]) -> [DishCategory: Double] {
        var totals: [DishCategory: (Double, Int)] = [:]
        let dishById = Dictionary(uniqueKeysWithValues: dishes.map { ($0.id, $0) })
        for entry in entries {
            guard let dishId = entry.dishId, let dish = dishById[dishId] else { continue }
            let overall = Double(entry.ratings.overall)
            if var current = totals[dish.category] {
                current.0 += overall
                current.1 += 1
                totals[dish.category] = current
            } else {
                totals[dish.category] = (overall, 1)
            }
        }
        return totals.mapValues { $0.0 / Double($0.1) }
    }

    /// Returns dishes the user would order again sorted by the most recent
    /// entry date.  Only entries with `wouldOrderAgain == true` contribute
    /// to the result.  The limit parameter caps the result.
    public static func wouldOrderAgainList(entries: [FoodEntry], dishes: [Dish], limit: Int = 5) -> [(dish: Dish, lastDate: Date)] {
        let dishById = Dictionary(uniqueKeysWithValues: dishes.map { ($0.id, $0) })
        var lastDateByDish: [UUID: Date] = [:]
        for entry in entries where entry.wouldOrderAgain {
            guard let dishId = entry.dishId else { continue }
            if let current = lastDateByDish[dishId] {
                if entry.date > current { lastDateByDish[dishId] = entry.date }
            } else {
                lastDateByDish[dishId] = entry.date
            }
        }
        let sorted = lastDateByDish.sorted { $0.value > $1.value }.prefix(limit)
        return sorted.compactMap { pair in
            guard let dish = dishById[pair.key] else { return nil }
            return (dish, pair.value)
        }
    }

    /// Returns the entry with the highest overall rating for a given dish.  If
    /// multiple entries share the same highest rating, the most recent is
    /// returned.  Returns nil if no entry exists for the dish.
    public static func bestEntry(for dish: Dish, entries: [FoodEntry]) -> FoodEntry? {
        let filtered = entries.filter { $0.dishId == dish.id }
        guard !filtered.isEmpty else { return nil }
        return filtered.max { lhs, rhs in
            if lhs.ratings.overall == rhs.ratings.overall {
                return lhs.date < rhs.date
            }
            return lhs.ratings.overall < rhs.ratings.overall
        }
    }

    /// Computes categories ranked by descending average score.
    public static func rankedCategories(entries: [FoodEntry], dishes: [Dish]) -> [(category: DishCategory, averageScore: Double)] {
        let averages = averageScoreByCategory(entries: entries, dishes: dishes)
        return averages.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }

    /// Filters dishes marked as wish list.
    public static func wishlistDishes(dishes: [Dish]) -> [Dish] {
        dishes.filter { $0.wishlist }
    }

    /// Filters restaurants marked as wish list.
    public static func wishlistRestaurants(restaurants: [Restaurant]) -> [Restaurant] {
        restaurants.filter { $0.wishlist }
    }

    /// Suggests restaurants worth revisiting based on high average rating (>= 8)
    /// and low visit count (< 3).  Returns up to `limit` results.
    public static func revisitSuggestions(entries: [FoodEntry], restaurants: [Restaurant], limit: Int = 3) -> [(restaurant: Restaurant, averageScore: Double, visits: Int)] {
        let entriesByRestaurant = Dictionary(grouping: entries) { $0.restaurantId }
        var candidates: [(Restaurant, Double, Int)] = []
        for restaurant in restaurants {
            guard let list = entriesByRestaurant[restaurant.id], !list.isEmpty else { continue }
            let avg = list.reduce(0.0) { $0 + Double($1.ratings.overall) } / Double(list.count)
            let visits = visitCount(for: list)
            if avg >= 8.0 && visits < 3 {
                candidates.append((restaurant, avg, visits))
            }
        }
        return candidates.sorted { $0.1 > $1.1 }.prefix(limit).map { $0 }
    }

    /// Identifies hidden gems: dishes with only one recorded entry and an
    /// overall rating >= 8.  Returns up to `limit` results.
    public static func hiddenGems(entries: [FoodEntry], dishes: [Dish], limit: Int = 3) -> [(dish: Dish, averageScore: Double)] {
        let entriesByDish = Dictionary(grouping: entries) { $0.dishId }
        var results: [(Dish, Double)] = []
        for dish in dishes {
            guard let list = entriesByDish[dish.id], list.count == 1 else { continue }
            let entry = list[0]
            let avg = Double(entry.ratings.overall)
            if avg >= 8.0 {
                results.append((dish, avg))
            }
        }
        return results.sorted { $0.1 > $1.1 }.prefix(limit).map { $0 }
    }
}
