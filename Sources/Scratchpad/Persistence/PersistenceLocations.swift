import Foundation

/// Centralizes every on-disk path Scratchpad writes to, so no other file
/// hardcodes a path fragment.
enum PersistenceLocations {
    static var applicationSupportDirectory: URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
        return base.appendingPathComponent("Scratchpad", isDirectory: true)
    }

    static var drawingsDirectory: URL {
        applicationSupportDirectory.appendingPathComponent("Drawings", isDirectory: true)
    }
}
