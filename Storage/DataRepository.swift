import Foundation

struct RepositoryLoadResult {
    let restaurants: [Restaurant]
    let dishes: [Dish]
    let entries: [FoodEntry]
    let menus: [MenuRecord]
    let messages: [String]
}

/// Provides a simple repository abstraction over `JSONFileStore`.  All
/// collections are loaded and saved together.  In future versions this
/// class can be replaced by Core Data or another persistence solution.
public final class DataRepository {
    private let restaurantStore = JSONFileStore<Restaurant>(filename: StorageKeys.restaurants)
    private let dishStore = JSONFileStore<Dish>(filename: StorageKeys.dishes)
    private let entryStore = JSONFileStore<FoodEntry>(filename: StorageKeys.entries)
    private let menuStore = JSONFileStore<MenuRecord>(filename: StorageKeys.menus)

    public init() {}

    func loadAll() -> RepositoryLoadResult {
        let (restaurants, restaurantMessages) = restaurantStore.load()
        let (dishes, dishMessages) = dishStore.load()
        let (entries, entryMessages) = entryStore.load()
        let (menus, menuMessages) = menuStore.load()

        return RepositoryLoadResult(
            restaurants: restaurants,
            dishes: dishes,
            entries: entries,
            menus: menus,
            messages: restaurantMessages + dishMessages + entryMessages + menuMessages
        )
    }

    func saveAll(restaurants: [Restaurant], dishes: [Dish], entries: [FoodEntry], menus: [MenuRecord]) -> [String] {
        return restaurantStore.save(restaurants)
            + dishStore.save(dishes)
            + entryStore.save(entries)
            + menuStore.save(menus)
    }
}
