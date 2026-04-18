import Foundation

/// Stores a lightweight local reference to a photo saved inside the
/// app container. Metadata is optional and extracted locally when
/// available during import.
public struct PhotoReference: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var relativePath: String
    public var originalFilename: String?
    public var captureDate: Date?
    public var latitude: Double?
    public var longitude: Double?
    public var pixelWidth: Int?
    public var pixelHeight: Int?

    public init(
        id: UUID = UUID(),
        relativePath: String,
        originalFilename: String? = nil,
        captureDate: Date? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        pixelWidth: Int? = nil,
        pixelHeight: Int? = nil
    ) {
        self.id = id
        self.relativePath = relativePath
        self.originalFilename = originalFilename
        self.captureDate = captureDate
        self.latitude = latitude
        self.longitude = longitude
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }

    public var dimensionsText: String? {
        guard let pixelWidth, let pixelHeight else {
            return nil
        }
        return "\(pixelWidth) x \(pixelHeight)"
    }

    public var coordinateText: String? {
        guard let latitude, let longitude else {
            return nil
        }
        return String(format: "%.5f, %.5f", latitude, longitude)
    }
}
