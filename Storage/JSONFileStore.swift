import Foundation

/// A generic file store that saves and loads arrays of `Codable`
/// objects as JSON.  Uses the Application Support directory to avoid
/// storing files in user visible locations.  Errors during loading or
/// saving are returned to the caller and logged so persistence issues
/// are not silently swallowed.
public final class JSONFileStore<T: Codable> {
    private let filename: String
    private let directoryName = "FoodJournalApp"

    public init(filename: String) {
        self.filename = filename
    }

    private func directoryURL() throws -> URL {
        let fm = FileManager.default
        let baseDirectory = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let appDirectory = baseDirectory.appendingPathComponent(directoryName, isDirectory: true)
        try fm.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        return appDirectory
    }

    private func fileURL() throws -> URL {
        let dir = try directoryURL()
        return dir.appendingPathComponent(filename)
    }

    public func load() -> ([T], [String]) {
        let url: URL
        do {
            url = try fileURL()
        } catch {
            return ([], [logMessage("Failed to access storage directory for \(filename): \(error.localizedDescription)")])
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            return ([], [])
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            return ([], [logMessage("Failed to read \(filename): \(error.localizedDescription)")])
        }

        let decoder = JSONDecoder()
        do {
            return (try decoder.decode([T].self, from: data), [])
        } catch {
            return ([], [logMessage("Failed to decode \(filename): \(error.localizedDescription)")])
        }
    }

    public func save(_ items: [T]) -> [String] {
        let url: URL
        do {
            url = try fileURL()
        } catch {
            return [logMessage("Failed to access storage directory for \(filename): \(error.localizedDescription)")]
        }

        let encoder = JSONEncoder()
        let data: Data
        do {
            data = try encoder.encode(items)
        } catch {
            return [logMessage("Failed to encode \(filename): \(error.localizedDescription)")]
        }

        do {
            try data.write(to: url, options: .atomic)
            return []
        } catch {
            return [logMessage("Failed to save \(filename): \(error.localizedDescription)")]
        }
    }

    private func logMessage(_ message: String) -> String {
        print("JSONFileStore:", message)
        return message
    }
}
