import Foundation

/// Records a single meal or food experience.  An entry may reference a
/// restaurant and/or a dish.  It stores item classification, structured
/// details, ratings, notes, and optional visit grouping so multiple
/// items can be attached to a single restaurant visit.
public struct FoodEntry: Identifiable, Codable, Equatable {
    public var id: UUID
    public var itemType: ItemType
    public var restaurantId: UUID?
    public var visitId: UUID?
    public var dishId: UUID?
    public var customDishName: String?
    public var date: Date
    public var place: PlaceRecord?
    public var placeName: String?
    public var price: Double?
    public var currency: Currency?
    public var ratings: RatingBreakdown
    public var notes: String?
    public var photoReferences: [PhotoReference]
    public var tags: [String]
    public var sides: [String]
    public var sauces: [String]
    public var modifications: [String]
    public var drinkPairing: String?
    public var drinkSize: DrinkSize?
    public var drinkTemperature: DrinkTemperature?
    public var sweetnessLevel: Int?
    public var carbonationLevel: Int?
    public var strengthLevel: Int?
    public var brand: String?
    public var storeName: String?
    public var consistencyNotes: String?
    public var wouldOrderAgain: Bool
    public var highlighted: Bool
    public var occasion: Occasion?
    public var spiceLevel: SpiceLevel?
    public var isBestVersion: Bool
    public var neverOrderAgain: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        itemType: ItemType = .dish,
        restaurantId: UUID? = nil,
        visitId: UUID? = nil,
        dishId: UUID? = nil,
        customDishName: String? = nil,
        date: Date = Date(),
        place: PlaceRecord? = nil,
        placeName: String? = nil,
        price: Double? = nil,
        currency: Currency? = nil,
        ratings: RatingBreakdown = .empty,
        notes: String? = nil,
        photoReferences: [PhotoReference] = [],
        tags: [String] = [],
        sides: [String] = [],
        sauces: [String] = [],
        modifications: [String] = [],
        drinkPairing: String? = nil,
        drinkSize: DrinkSize? = nil,
        drinkTemperature: DrinkTemperature? = nil,
        sweetnessLevel: Int? = nil,
        carbonationLevel: Int? = nil,
        strengthLevel: Int? = nil,
        brand: String? = nil,
        storeName: String? = nil,
        consistencyNotes: String? = nil,
        wouldOrderAgain: Bool = false,
        highlighted: Bool = false,
        occasion: Occasion? = nil,
        spiceLevel: SpiceLevel? = nil,
        isBestVersion: Bool = false,
        neverOrderAgain: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.itemType = itemType
        self.restaurantId = restaurantId
        self.visitId = visitId
        self.dishId = dishId
        self.customDishName = customDishName
        self.date = date
        self.place = place
        self.placeName = place?.displayName ?? placeName
        self.price = price
        self.currency = currency
        self.ratings = ratings
        self.notes = notes
        self.photoReferences = photoReferences
        self.tags = tags
        self.sides = sides
        self.sauces = sauces
        self.modifications = modifications
        self.drinkPairing = drinkPairing
        self.drinkSize = drinkSize
        self.drinkTemperature = drinkTemperature
        self.sweetnessLevel = sweetnessLevel
        self.carbonationLevel = carbonationLevel
        self.strengthLevel = strengthLevel
        self.brand = brand
        self.storeName = storeName
        self.consistencyNotes = consistencyNotes
        self.wouldOrderAgain = wouldOrderAgain
        self.highlighted = highlighted
        self.occasion = occasion
        self.spiceLevel = spiceLevel
        self.isBestVersion = isBestVersion
        self.neverOrderAgain = neverOrderAgain
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case itemType
        case restaurantId
        case visitId
        case dishId
        case customDishName
        case date
        case place
        case placeName
        case price
        case currency
        case ratings
        case notes
        case photoReferences
        case tags
        case sides
        case sauces
        case modifications
        case drinkPairing
        case drinkSize
        case drinkTemperature
        case sweetnessLevel
        case carbonationLevel
        case strengthLevel
        case brand
        case storeName
        case consistencyNotes
        case wouldOrderAgain
        case highlighted
        case occasion
        case spiceLevel
        case isBestVersion
        case neverOrderAgain
        case createdAt
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let now = Date()

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        restaurantId = try container.decodeIfPresent(UUID.self, forKey: .restaurantId)
        dishId = try container.decodeIfPresent(UUID.self, forKey: .dishId)
        itemType = try container.decodeIfPresent(ItemType.self, forKey: .itemType) ?? .dish
        visitId = try container.decodeIfPresent(UUID.self, forKey: .visitId)
        customDishName = try container.decodeIfPresent(String.self, forKey: .customDishName)
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? now
        place = try container.decodeIfPresent(PlaceRecord.self, forKey: .place)
        let legacyPlaceName = try container.decodeIfPresent(String.self, forKey: .placeName)
        if place == nil, let legacyPlaceName {
            place = PlaceRecord(displayName: legacyPlaceName, source: .manual, restaurantId: restaurantId)
        }
        placeName = place?.displayName ?? legacyPlaceName
        price = try container.decodeIfPresent(Double.self, forKey: .price)
        currency = try container.decodeIfPresent(Currency.self, forKey: .currency)
        ratings = try container.decodeIfPresent(RatingBreakdown.self, forKey: .ratings) ?? .empty
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        if let decodedPhotoReferences = try container.decodeIfPresent([PhotoReference].self, forKey: .photoReferences) {
            photoReferences = decodedPhotoReferences
        } else {
            let legacyPhotoReferences = try container.decodeIfPresent([String].self, forKey: .photoReferences) ?? []
            photoReferences = legacyPhotoReferences.map { PhotoReference(relativePath: $0) }
        }
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        sides = try container.decodeIfPresent([String].self, forKey: .sides) ?? []
        sauces = try container.decodeIfPresent([String].self, forKey: .sauces) ?? []
        modifications = try container.decodeIfPresent([String].self, forKey: .modifications) ?? []
        drinkPairing = try container.decodeIfPresent(String.self, forKey: .drinkPairing)
        drinkSize = try container.decodeIfPresent(DrinkSize.self, forKey: .drinkSize)
        drinkTemperature = try container.decodeIfPresent(DrinkTemperature.self, forKey: .drinkTemperature)
        sweetnessLevel = try container.decodeIfPresent(Int.self, forKey: .sweetnessLevel)
        carbonationLevel = try container.decodeIfPresent(Int.self, forKey: .carbonationLevel)
        strengthLevel = try container.decodeIfPresent(Int.self, forKey: .strengthLevel)
        brand = try container.decodeIfPresent(String.self, forKey: .brand)
        storeName = try container.decodeIfPresent(String.self, forKey: .storeName)
        consistencyNotes = try container.decodeIfPresent(String.self, forKey: .consistencyNotes)
        wouldOrderAgain = try container.decodeIfPresent(Bool.self, forKey: .wouldOrderAgain) ?? false
        highlighted = try container.decodeIfPresent(Bool.self, forKey: .highlighted) ?? false
        occasion = try container.decodeIfPresent(Occasion.self, forKey: .occasion)
        spiceLevel = try container.decodeIfPresent(SpiceLevel.self, forKey: .spiceLevel)
        isBestVersion = try container.decodeIfPresent(Bool.self, forKey: .isBestVersion) ?? false
        neverOrderAgain = try container.decodeIfPresent(Bool.self, forKey: .neverOrderAgain) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? date
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(itemType, forKey: .itemType)
        try container.encodeIfPresent(restaurantId, forKey: .restaurantId)
        try container.encodeIfPresent(visitId, forKey: .visitId)
        try container.encodeIfPresent(dishId, forKey: .dishId)
        try container.encodeIfPresent(customDishName, forKey: .customDishName)
        try container.encode(date, forKey: .date)
        try container.encodeIfPresent(place, forKey: .place)
        try container.encodeIfPresent(placeName, forKey: .placeName)
        try container.encodeIfPresent(price, forKey: .price)
        try container.encodeIfPresent(currency, forKey: .currency)
        try container.encode(ratings, forKey: .ratings)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(photoReferences, forKey: .photoReferences)
        try container.encode(tags, forKey: .tags)
        try container.encode(sides, forKey: .sides)
        try container.encode(sauces, forKey: .sauces)
        try container.encode(modifications, forKey: .modifications)
        try container.encodeIfPresent(drinkPairing, forKey: .drinkPairing)
        try container.encodeIfPresent(drinkSize, forKey: .drinkSize)
        try container.encodeIfPresent(drinkTemperature, forKey: .drinkTemperature)
        try container.encodeIfPresent(sweetnessLevel, forKey: .sweetnessLevel)
        try container.encodeIfPresent(carbonationLevel, forKey: .carbonationLevel)
        try container.encodeIfPresent(strengthLevel, forKey: .strengthLevel)
        try container.encodeIfPresent(brand, forKey: .brand)
        try container.encodeIfPresent(storeName, forKey: .storeName)
        try container.encodeIfPresent(consistencyNotes, forKey: .consistencyNotes)
        try container.encode(wouldOrderAgain, forKey: .wouldOrderAgain)
        try container.encode(highlighted, forKey: .highlighted)
        try container.encodeIfPresent(occasion, forKey: .occasion)
        try container.encodeIfPresent(spiceLevel, forKey: .spiceLevel)
        try container.encode(isBestVersion, forKey: .isBestVersion)
        try container.encode(neverOrderAgain, forKey: .neverOrderAgain)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
