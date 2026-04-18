import Foundation

/// Represents a saved menu scan for a restaurant.  Stores the raw
/// extracted text, an array of parsed items, and metadata such as
/// language and creation date.  In the future this model can be
/// extended to include translation results or remote menu matches.
public struct MenuRecord: Identifiable, Codable, Equatable {
    public var id: UUID
    public var restaurantId: UUID?
    public var scannedText: String
    public var parsedItems: [ParsedMenuItem]
    public var language: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        restaurantId: UUID? = nil,
        scannedText: String,
        parsedItems: [ParsedMenuItem] = [],
        language: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.restaurantId = restaurantId
        self.scannedText = scannedText
        self.parsedItems = parsedItems
        self.language = language
        self.createdAt = createdAt
    }
}