import Foundation

/// Persists each display's drawing as its own JSON file, named by that
/// display's stable identifier, under `PersistenceLocations.drawingsDirectory`.
final class FileDrawingRepository: DrawingRepository {
    private let fileManager: FileManager
    private let directory: URL
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(
        fileManager: FileManager = .default,
        directory: URL = PersistenceLocations.drawingsDirectory
    ) {
        self.fileManager = fileManager
        self.directory = directory
    }

    func load(for display: DisplayIdentifier) -> DrawingDocument {
        let url = fileURL(for: display)
        guard let data = try? Data(contentsOf: url) else { return .empty }
        return (try? decoder.decode(DrawingDocument.self, from: data)) ?? .empty
    }

    func save(_ document: DrawingDocument, for display: DisplayIdentifier) throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(document)
        try data.write(to: fileURL(for: display), options: .atomic)
    }

    func clear(for display: DisplayIdentifier) throws {
        let url = fileURL(for: display)
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }

    private func fileURL(for display: DisplayIdentifier) -> URL {
        directory.appendingPathComponent("\(display.filenameComponent).json")
    }
}
