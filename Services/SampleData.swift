import Foundation

/// Provides sample data for previews and first‑run seeding.  Sample data
/// enables the app to show meaningful content on initial launch without
/// requiring user input.  The sample lists are independent but
/// referenced together when generating entries.
public enum SampleData {
    /// Sample restaurants demonstrating various cuisine tags and flags.
    public static func restaurants() -> [Restaurant] {
        [
            Restaurant(
                name: "Burger Palace",
                locationText: "Erlangen",
                cuisineTags: ["American", "Fast Food"],
                notes: "Best fries in town",
                favorite: true,
                wishlist: false,
                visitDates: []
            ),
            Restaurant(
                name: "Sushi Zen",
                locationText: "Nürnberg",
                cuisineTags: ["Japanese", "Sushi"],
                notes: nil,
                favorite: false,
                wishlist: false,
                visitDates: []
            ),
            Restaurant(
                name: "Mama's Pasta",
                locationText: "Fürth",
                cuisineTags: ["Italian"],
                notes: "Homemade pasta",
                favorite: false,
                wishlist: false,
                visitDates: []
            )
        ]
    }

    /// Sample dishes demonstrating categories, notes and wish list flags.
    public static func dishes() -> [Dish] {
        [
            Dish(name: "Cheeseburger", category: .burger, notes: "Look for a juicy patty", wishlist: false),
            Dish(name: "Fries", category: .fries, notes: "Crispy on the outside, fluffy inside", wishlist: false),
            Dish(name: "Margherita Pizza", category: .pizza, notes: "Classic tomato & mozzarella", wishlist: false),
            Dish(name: "Spaghetti Carbonara", category: .pasta, notes: "Traditional Roman recipe", wishlist: false)
        ]
    }

    /// Sample entries that link the sample restaurants and dishes.  Use
    /// matching names to look up the appropriate IDs.  Ratings and
    /// notes illustrate typical usage.  Flags and optional fields use
    /// default values.
    public static func entries(restaurants: [Restaurant], dishes: [Dish]) -> [FoodEntry] {
        // Helpers to find by name
        func restaurant(named name: String) -> Restaurant? {
            restaurants.first { $0.name == name }
        }
        func dish(named name: String) -> Dish? {
            dishes.first { $0.name == name }
        }
        guard
            let burgerPalace = restaurant(named: "Burger Palace"),
            let sushiZen = restaurant(named: "Sushi Zen"),
            let mamaPasta = restaurant(named: "Mama's Pasta"),
            let cheeseburger = dish(named: "Cheeseburger"),
            let fries = dish(named: "Fries"),
            let pizza = dish(named: "Margherita Pizza"),
            let carbonara = dish(named: "Spaghetti Carbonara")
        else { return [] }

        let burgerVisit = UUID()
        let pastaVisit = UUID()
        let sushiVisit = UUID()

        return [
            FoodEntry(
                itemType: .dish,
                restaurantId: burgerPalace.id,
                visitId: burgerVisit,
                dishId: cheeseburger.id,
                date: Date().addingTimeInterval(-86400 * 2),
                place: PlaceRecord(
                    displayName: "Burger Palace, Altstadt",
                    addressText: "Hauptstrasse 12",
                    localityText: "Erlangen",
                    source: .manual,
                    restaurantId: burgerPalace.id
                ),
                price: 8.5,
                currency: .eur,
                ratings: RatingBreakdown(taste: 8, quality: 8, texture: 7, presentation: 6, portionSize: 7, value: 8, craving: 9, overall: 8),
                notes: "Juicy burger, slightly overcooked bun",
                sides: ["Fries"],
                sauces: ["Burger Sauce"],
                tags: ["beef", "cheese"],
                wouldOrderAgain: true,
                highlighted: false,
                occasion: .casual,
                spiceLevel: .none,
                isBestVersion: false,
                neverOrderAgain: false
            ),
            FoodEntry(
                itemType: .dish,
                restaurantId: burgerPalace.id,
                visitId: burgerVisit,
                dishId: fries.id,
                date: Date().addingTimeInterval(-86400 * 2),
                place: PlaceRecord(
                    displayName: "Burger Palace, Altstadt",
                    addressText: "Hauptstrasse 12",
                    localityText: "Erlangen",
                    source: .manual,
                    restaurantId: burgerPalace.id
                ),
                price: 3.0,
                currency: .eur,
                ratings: RatingBreakdown(taste: 9, quality: 9, texture: 9, presentation: 7, portionSize: 8, value: 9, craving: 9, overall: 9),
                notes: "Crispy and perfectly salted",
                sauces: ["Ketchup", "Aioli"],
                tags: ["side"],
                wouldOrderAgain: true,
                highlighted: true,
                occasion: .casual,
                spiceLevel: .none,
                isBestVersion: true,
                neverOrderAgain: false
            ),
            FoodEntry(
                itemType: .drink,
                restaurantId: burgerPalace.id,
                visitId: burgerVisit,
                customDishName: "Cherry Cola",
                date: Date().addingTimeInterval(-86400 * 2),
                place: PlaceRecord(
                    displayName: "Burger Palace, Altstadt",
                    addressText: "Hauptstrasse 12",
                    localityText: "Erlangen",
                    source: .manual,
                    restaurantId: burgerPalace.id
                ),
                price: 2.8,
                currency: .eur,
                ratings: RatingBreakdown(taste: 7, quality: 7, value: 8, overall: 7),
                drinkPairing: "Cheeseburger",
                drinkSize: .medium,
                drinkTemperature: .iceCold,
                sweetnessLevel: 4,
                carbonationLevel: 5,
                strengthLevel: 0,
                notes: "Classic fast-food cola pairing",
                tags: ["soft drink"],
                wouldOrderAgain: true,
                highlighted: false,
                occasion: .casual,
                neverOrderAgain: false
            ),
            FoodEntry(
                itemType: .dish,
                restaurantId: sushiZen.id,
                visitId: sushiVisit,
                dishId: fries.id,
                date: Date().addingTimeInterval(-86400 * 5),
                place: PlaceRecord(
                    displayName: "Sushi Zen, Innenstadt",
                    localityText: "Nurnberg",
                    source: .manual,
                    restaurantId: sushiZen.id
                ),
                price: 3.5,
                currency: .eur,
                ratings: RatingBreakdown(taste: 7, quality: 7, texture: 7, presentation: 7, portionSize: 6, value: 7, craving: 6, overall: 7),
                notes: "Surprisingly good fries at a sushi place",
                tags: [],
                wouldOrderAgain: false,
                highlighted: false,
                occasion: .other,
                spiceLevel: .none,
                isBestVersion: false,
                neverOrderAgain: false
            ),
            FoodEntry(
                itemType: .dish,
                restaurantId: mamaPasta.id,
                visitId: pastaVisit,
                dishId: pizza.id,
                date: Date().addingTimeInterval(-86400 * 10),
                place: PlaceRecord(
                    displayName: "Mama's Pasta, Sudstadt",
                    localityText: "Furth",
                    source: .manual,
                    restaurantId: mamaPasta.id
                ),
                price: 9.0,
                currency: .eur,
                ratings: RatingBreakdown(taste: 8, quality: 8, texture: 8, presentation: 8, portionSize: 7, value: 8, craving: 7, overall: 8),
                notes: "Nice airy crust",
                modifications: ["Extra basil"],
                tags: [],
                wouldOrderAgain: true,
                highlighted: false,
                occasion: .celebration,
                spiceLevel: .none,
                isBestVersion: false,
                neverOrderAgain: false
            ),
            FoodEntry(
                itemType: .dish,
                restaurantId: mamaPasta.id,
                visitId: pastaVisit,
                dishId: carbonara.id,
                date: Date().addingTimeInterval(-86400 * 20),
                place: PlaceRecord(
                    displayName: "Mama's Pasta, Sudstadt",
                    localityText: "Furth",
                    source: .manual,
                    restaurantId: mamaPasta.id
                ),
                price: 11.0,
                currency: .eur,
                ratings: RatingBreakdown(taste: 9, quality: 9, texture: 9, presentation: 7, portionSize: 8, value: 8, craving: 8, overall: 9),
                notes: "Authentic carbonara without cream",
                drinkPairing: "Sparkling water",
                tags: [],
                wouldOrderAgain: true,
                highlighted: true,
                occasion: .date,
                spiceLevel: .none,
                isBestVersion: true,
                neverOrderAgain: false
            ),
            FoodEntry(
                itemType: .product,
                customDishName: "Truffle Potato Chips",
                date: Date().addingTimeInterval(-86400 * 1),
                place: PlaceRecord(
                    displayName: "REWE Erlangen Arcaden",
                    localityText: "Erlangen",
                    source: .manual
                ),
                price: 2.99,
                currency: .eur,
                ratings: RatingBreakdown(taste: 7, quality: 7, value: 6, overall: 7),
                notes: "Good crunch, truffle flavor is subtle.",
                photoReferences: [],
                tags: ["snack", "grocery"],
                brand: "Lorenz",
                storeName: "REWE",
                consistencyNotes: "Very crunchy with a light oil finish",
                wouldOrderAgain: true,
                highlighted: false,
                occasion: .other,
                neverOrderAgain: false
            )
        ]
    }
}
