import Testing
@testable import Scratchpad

struct StrokeSmoothingTests {

    @Test func noPointsProducesNoSegments() {
        #expect(StrokeSmoothing.segments(for: []).isEmpty)
    }

    @Test func singlePointProducesADot() {
        let point = StrokePoint(x: 1, y: 2)
        let segments = StrokeSmoothing.segments(for: [point])
        #expect(segments == [.move(to: point), .line(to: point)])
    }

    @Test func twoPointsProduceAStraightLine() {
        let a = StrokePoint(x: 0, y: 0)
        let b = StrokePoint(x: 10, y: 10)
        let segments = StrokeSmoothing.segments(for: [a, b])
        #expect(segments == [.move(to: a), .line(to: b)])
    }

    @Test func threePointsProduceOneSmoothedCurveThenALineToTheEnd() {
        let a = StrokePoint(x: 0, y: 0)
        let b = StrokePoint(x: 10, y: 0)
        let c = StrokePoint(x: 20, y: 10)
        let segments = StrokeSmoothing.segments(for: [a, b, c])

        let expectedMidpoint = StrokePoint(x: 15, y: 5)
        #expect(segments == [
            .move(to: a),
            .quadCurve(to: expectedMidpoint, control: b),
            .line(to: c),
        ])
    }

    @Test func fourPointsProduceTwoSmoothedCurvesThenALineToTheEnd() {
        let points = [
            StrokePoint(x: 0, y: 0),
            StrokePoint(x: 10, y: 0),
            StrokePoint(x: 20, y: 0),
            StrokePoint(x: 30, y: 0),
        ]
        let segments = StrokeSmoothing.segments(for: points)

        #expect(segments.count == 4)
        #expect(segments.first == .move(to: points[0]))
        #expect(segments.last == .line(to: points[3]))
    }
}
