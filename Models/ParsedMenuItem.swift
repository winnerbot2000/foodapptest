import Foundation

/// Represents a single item parsed from a menu scan.  Contains the
/// detected name, an optional description, a price string and an
/// optional category.  Parsed items can be used to quickly create new
/// dishes or suggest matches when adding entries.
public struct ParsedMenuItem: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var description: String?
    public var priceText: String?
    public var category: String?
    public var sourceText: String?
    public var ocrConfidence: Double?

    public init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        priceText: String? = nil,
        category: String? = nil,
        sourceText: String? = nil,
        ocrConfidence: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.priceText = priceText
        self.category = category
        self.sourceText = sourceText
        self.ocrConfidence = ocrConfidence
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case priceText
        case category
        case sourceText
        case ocrConfidence
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        priceText = try container.decodeIfPresent(String.self, forKey: .priceText)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        sourceText = try container.decodeIfPresent(String.self, forKey: .sourceText)
        ocrConfidence = try container.decodeIfPresent(Double.self, forKey: .ocrConfidence)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(priceText, forKey: .priceText)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(sourceText, forKey: .sourceText)
        try container.encodeIfPresent(ocrConfidence, forKey: .ocrConfidence)
    }
}
