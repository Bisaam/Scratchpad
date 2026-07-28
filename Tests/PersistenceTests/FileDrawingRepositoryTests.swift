import Foundation
import Testing
@testable import Scratchpad

struct FileDrawingRepositoryTests {

    private func makeRepository() -> (FileDrawingRepository, URL) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ScratchpadTests-\(UUID().uuidString)", isDirectory: true)
        return (FileDrawingRepository(directory: directory), directory)
    }

    @Test func loadingMissingDisplayReturnsEmptyDocument() {
        let (repository, directory) = makeRepository()
        defer { try? FileManager.default.removeItem(at: directory) }

        let document = repository.load(for: DisplayIdentifier(rawValue: 1))
        #expect(document == .empty)
    }

    @Test func savedDocumentRoundTripsThroughLoad() throws {
        let (repository, directory) = makeRepository()
        defer { try? FileManager.default.removeItem(at: directory) }

        let display = DisplayIdentifier(rawValue: 42)
        let stroke = Stroke(points: [StrokePoint(x: 0, y: 0), StrokePoint(x: 10, y: 10)])
        let document = DrawingDocument(strokes: [stroke], updatedAt: Date(timeIntervalSince1970: 0))

        try repository.save(document, for: display)
        let loaded = repository.load(for: display)

        #expect(loaded == document)
    }

    @Test func clearRemovesTheSavedDocument() throws {
        let (repository, directory) = makeRepository()
        defer { try? FileManager.default.removeItem(at: directory) }

        let display = DisplayIdentifier(rawValue: 7)
        try repository.save(DrawingDocument(strokes: [Stroke()], updatedAt: Date()), for: display)

        try repository.clear(for: display)

        #expect(repository.load(for: display) == .empty)
    }

    @Test func differentDisplaysArePersistedIndependently() throws {
        let (repository, directory) = makeRepository()
        defer { try? FileManager.default.removeItem(at: directory) }

        let first = DisplayIdentifier(rawValue: 1)
        let second = DisplayIdentifier(rawValue: 2)
        let firstDocument = DrawingDocument(strokes: [Stroke()], updatedAt: Date())

        try repository.save(firstDocument, for: first)

        #expect(repository.load(for: first) == firstDocument)
        #expect(repository.load(for: second) == .empty)
    }
}
