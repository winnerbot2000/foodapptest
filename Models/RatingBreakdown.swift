import Foundation

/// Captures a multi‑factor evaluation of a food experience.  Each rating
/// is on a 0–10 scale with 0 representing poor and 10 representing
/// excellent.  An empty breakdown uses zeros.  Use the `validate()`
/// method in debug builds to assert valid ranges.
public struct RatingBreakdown: Codable, Equatable {
    public var taste: Int
    public var quality: Int
    public var texture: Int
    public var presentation: Int
    public var portionSize: Int
    public var value: Int
    public var craving: Int
    public var overall: Int

    public init(
        taste: Int = 0,
        quality: Int = 0,
        texture: Int = 0,
        presentation: Int = 0,
        portionSize: Int = 0,
        value: Int = 0,
        craving: Int = 0,
        overall: Int = 0
    ) {
        self.taste = taste
        self.quality = quality
        self.texture = texture
        self.presentation = presentation
        self.portionSize = portionSize
        self.value = value
        self.craving = craving
        self.overall = overall
    }

    private enum CodingKeys: String, CodingKey {
        case taste
        case quality
        case texture
        case presentation
        case portionSize
        case value
        case craving
        case overall
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        taste = try container.decodeIfPresent(Int.self, forKey: .taste) ?? 0
        texture = try container.decodeIfPresent(Int.self, forKey: .texture) ?? 0
        presentation = try container.decodeIfPresent(Int.self, forKey: .presentation) ?? 0
        portionSize = try container.decodeIfPresent(Int.self, forKey: .portionSize) ?? 0
        value = try container.decodeIfPresent(Int.self, forKey: .value) ?? 0
        craving = try container.decodeIfPresent(Int.self, forKey: .craving) ?? 0
        overall = try container.decodeIfPresent(Int.self, forKey: .overall) ?? 0
        quality = try container.decodeIfPresent(Int.self, forKey: .quality)
            ?? max(presentation, texture)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(taste, forKey: .taste)
        try container.encode(quality, forKey: .quality)
        try container.encode(texture, forKey: .texture)
        try container.encode(presentation, forKey: .presentation)
        try container.encode(portionSize, forKey: .portionSize)
        try container.encode(value, forKey: .value)
        try container.encode(craving, forKey: .craving)
        try container.encode(overall, forKey: .overall)
    }

    /// Asserts that all ratings lie within the 0–10 range.  Use in debug
    /// builds to ensure data integrity.
    public func validate() {
        assert((0...10).contains(taste), "Taste rating must be 0–10")
        assert((0...10).contains(quality), "Quality rating must be 0–10")
        assert((0...10).contains(texture), "Texture rating must be 0–10")
        assert((0...10).contains(presentation), "Presentation rating must be 0–10")
        assert((0...10).contains(portionSize), "Portion rating must be 0–10")
        assert((0...10).contains(value), "Value rating must be 0–10")
        assert((0...10).contains(craving), "Craving rating must be 0–10")
        assert((0...10).contains(overall), "Overall rating must be 0–10")
    }

    /// Convenience empty breakdown with all values zero.
    public static var empty: RatingBreakdown {
        RatingBreakdown()
    }
}
