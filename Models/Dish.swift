import Foundation

/// Represents a type of food (e.g. “Cheeseburger”, “Margherita Pizza”).
/// Each dish belongs to a `DishCategory` and may include a more specific
/// subcategory.  Flags for wish list and a reference to the best entry
/// support richer insights.
public struct Dish: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var name: String
    public var category: DishCategory
    public var subcategory: String?
    public var notes: String?
    public var photoReferences: [PhotoReference]
    public var createdAt: Date
    public var updatedAt: Date
    public var wishlist: Bool
    public var bestEntryId: UUID?

    public init(
        id: UUID = UUID(),
        name: String,
        category: DishCategory,
        subcategory: String? = nil,
        notes: String? = nil,
        photoReferences: [PhotoReference] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        wishlist: Bool = false,
        bestEntryId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.subcategory = subcategory
        self.notes = notes
        self.photoReferences = photoReferences
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.wishlist = wishlist
        self.bestEntryId = bestEntryId
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case subcategory
        case notes
        case photoReferences
        case createdAt
        case updatedAt
        case wishlist
        case bestEntryId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let now = Date()

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(DishCategory.self, forKey: .category)
        subcategory = try container.decodeIfPresent(String.self, forKey: .subcategory)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        if let decodedPhotoReferences = try container.decodeIfPresent([PhotoReference].self, forKey: .photoReferences) {
            photoReferences = decodedPhotoReferences
        } else {
            let legacyPhotoReferences = try container.decodeIfPresent([String].self, forKey: .photoReferences) ?? []
            photoReferences = legacyPhotoReferences.map { PhotoReference(relativePath: $0) }
        }
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? now
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
        wishlist = try container.decodeIfPresent(Bool.self, forKey: .wishlist) ?? false
        bestEntryId = try container.decodeIfPresent(UUID.self, forKey: .bestEntryId)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(category, forKey: .category)
        try container.encodeIfPresent(subcategory, forKey: .subcategory)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(photoReferences, forKey: .photoReferences)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(wishlist, forKey: .wishlist)
        try container.encodeIfPresent(bestEntryId, forKey: .bestEntryId)
    }
}
