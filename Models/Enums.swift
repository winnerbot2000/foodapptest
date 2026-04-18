import Foundation

/// High‑level categories for dishes.  These categories group dishes
/// broadly and are used for filtering and insights.  Additional cases
/// can be added in future versions.
public enum DishCategory: String, CaseIterable, Codable, Identifiable {
    case burger
    case fries
    case pizza
    case pasta
    case sushi
    case dessert
    case drink
    case salad
    case soup
    case other

    public var id: String { rawValue }

    /// Human readable display name for the category.
    public var displayName: String {
        switch self {
        case .burger: return "Burger"
        case .fries: return "Fries"
        case .pizza: return "Pizza"
        case .pasta: return "Pasta"
        case .sushi: return "Sushi"
        case .dessert: return "Dessert"
        case .drink: return "Drink"
        case .salad: return "Salad"
        case .soup: return "Soup"
        case .other: return "Other"
        }
    }
}

/// Broad entry classification for food tracking.  Dishes can link to a
/// reusable `Dish` model, while products and drinks can be tracked as
/// standalone named items.
public enum ItemType: String, CaseIterable, Codable, Identifiable {
    case dish
    case product
    case drink

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .dish: return "Dish"
        case .product: return "Product"
        case .drink: return "Drink"
        }
    }

    public var systemImage: String {
        switch self {
        case .dish: return "fork.knife"
        case .product: return "bag"
        case .drink: return "cup.and.saucer"
        }
    }
}

/// Supported currencies for pricing.  Only a few common currencies are
/// included to keep the sample concise.  The `localeIdentifier` can be
/// used with a `NumberFormatter` to display prices.
public enum Currency: String, CaseIterable, Codable, Identifiable {
    case eur = "EUR"
    case usd = "USD"
    case gbp = "GBP"
    case jpy = "JPY"

    public var id: String { rawValue }

    public var localeIdentifier: String {
        switch self {
        case .eur: return "de_DE"
        case .usd: return "en_US"
        case .gbp: return "en_GB"
        case .jpy: return "ja_JP"
        }
    }
}

/// The context or mood associated with a meal.  Optional on entries.
public enum Occasion: String, CaseIterable, Codable, Identifiable {
    case casual
    case celebration
    case travel
    case business
    case lateNight
    case date
    case other

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .casual: return "Casual"
        case .celebration: return "Celebration"
        case .travel: return "Travel"
        case .business: return "Business"
        case .lateNight: return "Late Night"
        case .date: return "Date"
        case .other: return "Other"
        }
    }
}

/// Perceived spice level of a dish.  Optional on entries.  Represented as
/// an integer scale from 0 (none) to 5 (extreme).
public enum SpiceLevel: Int, CaseIterable, Codable, Identifiable {
    case none = 0
    case mild = 1
    case medium = 2
    case hot = 3
    case extraHot = 4
    case extreme = 5

    public var id: Int { rawValue }

    public var displayName: String {
        switch self {
        case .none: return "None"
        case .mild: return "Mild"
        case .medium: return "Medium"
        case .hot: return "Hot"
        case .extraHot: return "Extra Hot"
        case .extreme: return "Extreme"
        }
    }
}

/// Common size descriptors for drinks.
public enum DrinkSize: String, CaseIterable, Codable, Identifiable {
    case small
    case medium
    case large
    case bottle
    case can
    case pint

    public var id: String { rawValue }

    public var displayName: String {
        rawValue.capitalized
    }
}

/// Temperature states used for drink entries.
public enum DrinkTemperature: String, CaseIterable, Codable, Identifiable {
    case iceCold
    case chilled
    case roomTemperature
    case warm
    case hot

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .iceCold: return "Ice Cold"
        case .chilled: return "Chilled"
        case .roomTemperature: return "Room Temperature"
        case .warm: return "Warm"
        case .hot: return "Hot"
        }
    }
}
