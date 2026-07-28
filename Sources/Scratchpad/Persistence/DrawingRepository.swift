/// Loads and saves the drawing for a single display.
///
/// Backed by plain JSON files rather than a database: drawings are just an
/// ordered stroke list, and JSON is trivial to read/write from a future
/// Windows port of the same architecture.
protocol DrawingRepository {
    func load(for display: DisplayIdentifier) -> DrawingDocument
    func save(_ document: DrawingDocument, for display: DisplayIdentifier) throws
    func clear(for display: DisplayIdentifier) throws
}
