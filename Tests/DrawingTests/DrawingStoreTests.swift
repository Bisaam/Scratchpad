import CoreGraphics
import Foundation
import Testing
@testable import Scratchpad

private final class MockDrawingRepository: DrawingRepository {
    var documentsByDisplay: [DisplayIdentifier: DrawingDocument] = [:]
    private(set) var saveCount = 0

    func load(for display: DisplayIdentifier) -> DrawingDocument {
        documentsByDisplay[display] ?? .empty
    }

    func save(_ document: DrawingDocument, for display: DisplayIdentifier) throws {
        saveCount += 1
        documentsByDisplay[display] = document
    }

    func clear(for display: DisplayIdentifier) throws {
        documentsByDisplay.removeValue(forKey: display)
    }
}

struct DrawingStoreTests {

    private let display = DisplayIdentifier(rawValue: 1)

    @Test func loadsPersistedStrokesOnInit() {
        let repository = MockDrawingRepository()
        let stroke = Stroke(points: [StrokePoint(x: 0, y: 0)])
        repository.documentsByDisplay[display] = DrawingDocument(strokes: [stroke], updatedAt: Date())

        let store = DrawingStore(display: display, repository: repository)

        #expect(store.strokes == [stroke])
    }

    @Test func beginAppendEndBuildsACompletedStroke() {
        let store = DrawingStore(display: display, repository: MockDrawingRepository())

        store.beginStroke(at: CGPoint(x: 0, y: 0))
        store.appendPoint(CGPoint(x: 5, y: 5))
        store.appendPoint(CGPoint(x: 10, y: 10))
        store.endStroke()

        #expect(store.strokes.count == 1)
        #expect(store.strokes[0].points.map(\.cgPoint) == [
            CGPoint(x: 0, y: 0), CGPoint(x: 5, y: 5), CGPoint(x: 10, y: 10),
        ])
        #expect(store.strokeInProgress == nil)
    }

    @Test func endStrokeWithoutBeginDoesNothing() {
        let store = DrawingStore(display: display, repository: MockDrawingRepository())
        store.endStroke()
        #expect(store.strokes.isEmpty)
    }

    @Test func clearRemovesAllStrokesAndAnyInProgressStroke() {
        let store = DrawingStore(display: display, repository: MockDrawingRepository())
        store.beginStroke(at: CGPoint(x: 0, y: 0))
        store.appendPoint(CGPoint(x: 1, y: 1))
        store.endStroke()
        store.beginStroke(at: CGPoint(x: 2, y: 2))

        store.clear()

        #expect(store.strokes.isEmpty)
        #expect(store.strokeInProgress == nil)
    }
}
