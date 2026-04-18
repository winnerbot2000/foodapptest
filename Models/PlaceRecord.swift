import Foundation

public enum PlaceSource: String, Codable, CaseIterable, Identifiable {
    case manual
    case currentDeviceLocation
    case photoMetadata

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .manual:
            return "Manual"
        case .currentDeviceLocation:
            return "Current Location"
        case .photoMetadata:
            return "Photo Metadata"
        }
    }
}

/// Lightweight place metadata stored with an entry. It can represent a
/// restaurant branch, store, or manually entered location without
/// depending on any online place service.
public struct PlaceRecord: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var displayName: String
    public var addressText: String?
    public var localityText: String?
    public var latitude: Double?
    public var longitude: Double?
    public var source: PlaceSource
    public var restaurantId: UUID?

    public init(
        id: UUID = UUID(),
        displayName: String,
        addressText: String? = nil,
        localityText: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        source: PlaceSource = .manual,
        restaurantId: UUID? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.addressText = addressText
        self.localityText = localityText
        self.latitude = latitude
        self.longitude = longitude
        self.source = source
        self.restaurantId = restaurantId
    }

    public var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }

    public var coordinateText: String? {
        guard let latitude, let longitude else {
            return nil
        }

        return String(format: "%.5f, %.5f", latitude, longitude)
    }

    public var secondaryText: String? {
        let parts = [addressText, localityText]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !parts.isEmpty else {
            return nil
        }

        return parts.joined(separator: " • ")
    }
}
