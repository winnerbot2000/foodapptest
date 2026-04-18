import Foundation
import SwiftUI
import Photos
import PhotosUI
import ImageIO
import UniformTypeIdentifiers
import CryptoKit

enum PhotoOwnerKind: String, CaseIterable {
    case entry = "entries"
    case dish = "dishes"
    case restaurant = "restaurants"
}

struct PhotoImportResult {
    let references: [PhotoReference]
    let messages: [String]
    let suggestedCaptureDate: Date?
    let suggestedLatitude: Double?
    let suggestedLongitude: Double?
}

actor PhotoStorageService {
    private let directoryName = "FoodJournalApp"
    private let photosDirectoryName = "Photos"

    func importPhotos(
        from items: [PhotosPickerItem],
        owner: PhotoOwnerKind,
        ownerID: UUID
    ) async -> PhotoImportResult {
        var references: [PhotoReference] = []
        var messages: [String] = []
        var suggestedCaptureDate: Date?
        var suggestedLatitude: Double?
        var suggestedLongitude: Double?

        for item in items {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    messages.append(logMessage("A selected photo could not be loaded."))
                    continue
                }

                let metadataFromAsset = metadataFromAssetIdentifier(item.itemIdentifier)
                let metadataFromImage = metadataFromImageData(data)
                let filenameExtension = fileExtension(for: item, data: data) ?? "jpg"
                let fileHash = SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
                let filename = "photo-\(String(fileHash.prefix(20))).\(filenameExtension)"
                let ownerDirectory = try ownerDirectoryURL(owner: owner, ownerID: ownerID)
                let fileURL = ownerDirectory.appendingPathComponent(filename)

                if !FileManager.default.fileExists(atPath: fileURL.path) {
                    try data.write(to: fileURL, options: .atomic)
                }

                let relativePath = relativePath(for: fileURL)
                let metadata = mergedMetadata(asset: metadataFromAsset, image: metadataFromImage)
                let reference = PhotoReference(
                    relativePath: relativePath,
                    originalFilename: metadata.originalFilename,
                    captureDate: metadata.captureDate,
                    latitude: metadata.latitude,
                    longitude: metadata.longitude,
                    pixelWidth: metadata.pixelWidth,
                    pixelHeight: metadata.pixelHeight
                )
                references.append(reference)

                if suggestedCaptureDate == nil {
                    suggestedCaptureDate = metadata.captureDate
                }
                if suggestedLatitude == nil, let latitude = metadata.latitude {
                    suggestedLatitude = latitude
                }
                if suggestedLongitude == nil, let longitude = metadata.longitude {
                    suggestedLongitude = longitude
                }
            } catch {
                messages.append(logMessage("Failed to import a photo: \(error.localizedDescription)"))
            }
        }

        return PhotoImportResult(
            references: references,
            messages: messages,
            suggestedCaptureDate: suggestedCaptureDate,
            suggestedLatitude: suggestedLatitude,
            suggestedLongitude: suggestedLongitude
        )
    }

    func loadData(for reference: PhotoReference) async -> Data? {
        do {
            let fileURL = try fileURL(forRelativePath: reference.relativePath)
            return try Data(contentsOf: fileURL)
        } catch {
            print("PhotoStorageService: Failed to load image for \(reference.relativePath): \(error.localizedDescription)")
            return nil
        }
    }

    func deletePhotos(_ references: [PhotoReference]) async -> [String] {
        var messages: [String] = []
        for reference in references {
            do {
                let fileURL = try fileURL(forRelativePath: reference.relativePath)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    try FileManager.default.removeItem(at: fileURL)
                    try removeEmptyParentDirectories(startingAt: fileURL.deletingLastPathComponent())
                }
            } catch {
                messages.append(logMessage("Failed to delete photo at \(reference.relativePath): \(error.localizedDescription)"))
            }
        }
        return messages
    }

    func deleteAllPhotos(for owner: PhotoOwnerKind, ownerID: UUID) async -> [String] {
        do {
            let directoryURL = try ownerDirectoryURL(owner: owner, ownerID: ownerID)
            if FileManager.default.fileExists(atPath: directoryURL.path) {
                try FileManager.default.removeItem(at: directoryURL)
            }
            try removeEmptyParentDirectories(startingAt: directoryURL.deletingLastPathComponent())
            return []
        } catch {
            return [logMessage("Failed to delete photos for \(owner.rawValue)/\(ownerID.uuidString): \(error.localizedDescription)")]
        }
    }

    func deleteAllManagedPhotos() async -> [String] {
        do {
            let photosDirectory = try photosRootDirectoryURL()
            if FileManager.default.fileExists(atPath: photosDirectory.path) {
                try FileManager.default.removeItem(at: photosDirectory)
            }
            return []
        } catch {
            return [logMessage("Failed to clear local photos: \(error.localizedDescription)")]
        }
    }

    func cleanupUnusedFiles(referencedRelativePaths: Set<String>) async -> [String] {
        var messages: [String] = []

        do {
            let photosDirectory = try photosRootDirectoryURL()
            guard FileManager.default.fileExists(atPath: photosDirectory.path) else {
                return []
            }

            let enumerator = FileManager.default.enumerator(
                at: photosDirectory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )

            while let url = enumerator?.nextObject() as? URL {
                let resourceValues = try url.resourceValues(forKeys: [.isRegularFileKey])
                guard resourceValues.isRegularFile == true else {
                    continue
                }

                let relativePath = relativePath(for: url)
                guard !referencedRelativePaths.contains(relativePath) else {
                    continue
                }

                try FileManager.default.removeItem(at: url)
                try removeEmptyParentDirectories(startingAt: url.deletingLastPathComponent())
            }
        } catch {
            messages.append(logMessage("Failed to clean up unused photos: \(error.localizedDescription)"))
        }

        return messages
    }

    private func appDirectoryURL() throws -> URL {
        let fileManager = FileManager.default
        let baseDirectory = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let appDirectory = baseDirectory.appendingPathComponent(directoryName, isDirectory: true)
        try fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        return appDirectory
    }

    private func photosRootDirectoryURL() throws -> URL {
        let rootDirectory = try appDirectoryURL().appendingPathComponent(photosDirectoryName, isDirectory: true)
        try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        return rootDirectory
    }

    private func ownerDirectoryURL(owner: PhotoOwnerKind, ownerID: UUID) throws -> URL {
        let directory = try photosRootDirectoryURL()
            .appendingPathComponent(owner.rawValue, isDirectory: true)
            .appendingPathComponent(ownerID.uuidString.lowercased(), isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func fileURL(forRelativePath relativePath: String) throws -> URL {
        try appDirectoryURL().appendingPathComponent(relativePath)
    }

    private func relativePath(for fileURL: URL) -> String {
        let rootPath = (try? appDirectoryURL().path) ?? ""
        let fullPath = fileURL.path
        guard fullPath.hasPrefix(rootPath), !rootPath.isEmpty else {
            return fileURL.lastPathComponent
        }

        let startIndex = fullPath.index(fullPath.startIndex, offsetBy: rootPath.count)
        return String(fullPath[startIndex...]).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private func removeEmptyParentDirectories(startingAt directoryURL: URL) throws {
        let fileManager = FileManager.default
        let photosRoot = try photosRootDirectoryURL().path
        var currentURL = directoryURL

        while currentURL.path.hasPrefix(photosRoot), currentURL.path != photosRoot {
            let contents = try fileManager.contentsOfDirectory(atPath: currentURL.path)
            guard contents.isEmpty else {
                return
            }

            try fileManager.removeItem(at: currentURL)
            currentURL = currentURL.deletingLastPathComponent()
        }
    }

    private func fileExtension(for item: PhotosPickerItem, data: Data) -> String? {
        if let preferredType = item.supportedContentTypes.first,
           let fileExtension = preferredType.preferredFilenameExtension {
            return fileExtension
        }

        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let imageType = CGImageSourceGetType(imageSource) else {
            return nil
        }

        return UTType(imageType as String)?.preferredFilenameExtension
    }

    private func metadataFromAssetIdentifier(_ itemIdentifier: String?) -> AssetBackedPhotoMetadata? {
        guard let itemIdentifier else {
            return nil
        }

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [itemIdentifier], options: nil)
        guard let asset = assets.firstObject else {
            return nil
        }

        let originalFilename = PHAssetResource.assetResources(for: asset).first?.originalFilename
        return AssetBackedPhotoMetadata(
            originalFilename: originalFilename,
            captureDate: asset.creationDate,
            latitude: asset.location?.coordinate.latitude,
            longitude: asset.location?.coordinate.longitude,
            pixelWidth: asset.pixelWidth,
            pixelHeight: asset.pixelHeight
        )
    }

    private func metadataFromImageData(_ data: Data) -> EmbeddedPhotoMetadata {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
            return EmbeddedPhotoMetadata()
        }

        let width = properties[kCGImagePropertyPixelWidth] as? Int
        let height = properties[kCGImagePropertyPixelHeight] as? Int

        var captureDate: Date?
        if let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
           let dateTimeOriginal = exif[kCGImagePropertyExifDateTimeOriginal] as? String {
            captureDate = exifDateFormatter.date(from: dateTimeOriginal)
        }

        var latitude: Double?
        var longitude: Double?
        if let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any] {
            latitude = gps[kCGImagePropertyGPSLatitude] as? Double
            longitude = gps[kCGImagePropertyGPSLongitude] as? Double

            if let latitudeRef = gps[kCGImagePropertyGPSLatitudeRef] as? String, latitudeRef.uppercased() == "S" {
                latitude = latitude.map { -$0 }
            }
            if let longitudeRef = gps[kCGImagePropertyGPSLongitudeRef] as? String, longitudeRef.uppercased() == "W" {
                longitude = longitude.map { -$0 }
            }
        }

        return EmbeddedPhotoMetadata(
            captureDate: captureDate,
            latitude: latitude,
            longitude: longitude,
            pixelWidth: width,
            pixelHeight: height
        )
    }

    private func mergedMetadata(
        asset: AssetBackedPhotoMetadata?,
        image: EmbeddedPhotoMetadata
    ) -> AssetBackedPhotoMetadata {
        AssetBackedPhotoMetadata(
            originalFilename: asset?.originalFilename,
            captureDate: asset?.captureDate ?? image.captureDate,
            latitude: asset?.latitude ?? image.latitude,
            longitude: asset?.longitude ?? image.longitude,
            pixelWidth: asset?.pixelWidth ?? image.pixelWidth,
            pixelHeight: asset?.pixelHeight ?? image.pixelHeight
        )
    }

    private func logMessage(_ message: String) -> String {
        print("PhotoStorageService:", message)
        return message
    }

    private var exifDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter
    }
}

private struct AssetBackedPhotoMetadata {
    let originalFilename: String?
    let captureDate: Date?
    let latitude: Double?
    let longitude: Double?
    let pixelWidth: Int?
    let pixelHeight: Int?
}

private struct EmbeddedPhotoMetadata {
    var captureDate: Date? = nil
    var latitude: Double? = nil
    var longitude: Double? = nil
    var pixelWidth: Int? = nil
    var pixelHeight: Int? = nil
}
