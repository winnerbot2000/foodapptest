import Foundation

/// Represents a food source such as a restaurant, café, food truck or
/// home kitchen.  Stores metadata about the location and allows flags
/// for favourites and wish list.  Visit dates are recorded when entries
/// are added to enable insights.
public struct Restaurant: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var name: String
    public var locationText: String
    public var cuisineTags: [String]
    public var notes: String?
    public var photoReferences: [PhotoReference]
    public var createdAt: Date
    public var updatedAt: Date
    public var favorite: Bool
    public var wishlist: Bool
    public var visitDates: [Date]

    public init(
        id: UUID = UUID(),
        name: String,
        locationText: String = "",
        cuisineTags: [String] = [],
        notes: String? = nil,
        photoReferences: [PhotoReference] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        favorite: Bool = false,
        wishlist: Bool = false,
        visitDates: [Date] = []
    ) {
        self.id = id
        self.name = name
        self.locationText = locationText
        self.cuisineTags = cuisineTags
        self.notes = notes
        self.photoReferences = photoReferences
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.favorite = favorite
        self.wishlist = wishlist
        self.visitDates = visitDates
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case locationText
        case cuisineTags
        case notes
        case photoReferences
        case createdAt
        case updatedAt
        case favorite
        case wishlist
        case visitDates
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let now = Date()

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        locationText = try container.decodeIfPresent(String.self, forKey: .locationText) ?? ""
        cuisineTags = try container.decodeIfPresent([String].self, forKey: .cuisineTags) ?? []
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        if let decodedPhotoReferences = try container.decodeIfPresent([PhotoReference].self, forKey: .photoReferences) {
            photoReferences = decodedPhotoReferences
        } else {
            let legacyPhotoReferences = try container.decodeIfPresent([String].self, forKey: .photoReferences) ?? []
            photoReferences = legacyPhotoReferences.map { PhotoReference(relativePath: $0) }
        }
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? now
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
        favorite = try container.decodeIfPresent(Bool.self, forKey: .favorite) ?? false
        wishlist = try container.decodeIfPresent(Bool.self, forKey: .wishlist) ?? false
        visitDates = try container.decodeIfPresent([Date].self, forKey: .visitDates) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(locationText, forKey: .locationText)
        try container.encode(cuisineTags, forKey: .cuisineTags)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(photoReferences, forKey: .photoReferences)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(favorite, forKey: .favorite)
        try container.encode(wishlist, forKey: .wishlist)
        try container.encode(visitDates, forKey: .visitDates)
    }
}
