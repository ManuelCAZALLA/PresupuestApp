import Foundation
import Testing
@testable import QuoteCore

@Suite("Contabilidad del evaluador del parser")
struct ParserEvaluatorTests {
    private var firstItem: Item { Item(id: FixtureItemUUIDs.uuid(for: "part-a"), name: "Copper valve", unit: .unit) }
    private var similarItem: Item { Item(id: FixtureItemUUIDs.uuid(for: "part-b"), name: "Copper valves", unit: .unit) }
    private var itemIDsByUUID: [UUID: String] {
        [FixtureItemUUIDs.uuid(for: "part-a"): "part-a", FixtureItemUUIDs.uuid(for: "part-b"): "part-b"]
    }

    @Test func countsAutomaticWithWrongQuantityAsFalse() {
        let summary = evaluate(
            expected: [.init(itemID: "part-a", quantity: 2, status: .auto)],
            outputs: [line(firstItem, quantity: 1, status: .auto)]
        )
        #expect(summary.autoEmitted == 1)
        #expect(summary.correctAuto == 0)
        #expect(summary.falseAuto == 1)
        #expect(summary.autoRecallNumerator == 1)
    }

    @Test func comparesUUIDInsteadOfSimilarNames() {
        let summary = evaluate(
            expected: [.init(itemID: "part-a", quantity: 1, status: .auto)],
            outputs: [line(similarItem, quantity: 1, status: .auto)]
        )
        #expect(summary.correctAuto == 0)
        #expect(summary.falseAuto == 1)
    }

    @Test func automaticForExpectedAmbiguousIsFalse() {
        let summary = evaluate(
            expected: [.init(status: .ambiguous(["part-a", "part-b"]))],
            outputs: [line(firstItem, quantity: 1, status: .auto)]
        )
        #expect(summary.falseAuto == 1)
        #expect(summary.ambiguousRecallNumerator == 0)
    }

    @Test func automaticForExpectedNoneIsFalse() {
        let summary = evaluate(
            expected: [.init(status: .none)],
            outputs: [line(firstItem, quantity: 1, status: .auto)]
        )
        #expect(summary.falseAuto == 1)
        #expect(summary.noneAccuracyNumerator == 0)
    }

    @Test func extraAutomaticOutputIsFalseAndSegmentationMismatch() {
        let summary = evaluate(
            expected: [.init(itemID: "part-a", quantity: 1, status: .auto)],
            outputs: [line(firstItem, quantity: 1, status: .auto), line(similarItem, quantity: 1, status: .auto)]
        )
        #expect(summary.correctAuto == 1)
        #expect(summary.falseAuto == 1)
        #expect(summary.reports[0].segmentationMismatch)
        #expect(summary.reports[0].unmatchedEmittedCount == 1)
    }

    @Test func missingOutputLosesAutoRecallWithoutFalseAuto() {
        let summary = evaluate(
            expected: [
                .init(itemID: "part-a", quantity: 1, status: .auto),
                .init(itemID: "part-b", quantity: 1, status: .auto)
            ],
            outputs: [line(firstItem, quantity: 1, status: .auto)]
        )
        #expect(summary.correctAuto == 1)
        #expect(summary.falseAuto == 0)
        #expect(summary.autoRecallNumerator == 1)
        #expect(summary.autoRecallDenominator == 2)
        #expect(summary.reports[0].unmatchedExpectedCount == 1)
    }

    @Test func emittedLinesCannotReuseAnExpectation() {
        let summary = evaluate(
            expected: [.init(itemID: "part-a", quantity: 1, status: .auto)],
            outputs: [line(firstItem, quantity: 1, status: .auto), line(firstItem, quantity: 1, status: .auto)]
        )
        #expect(summary.correctAuto == 1)
        #expect(summary.falseAuto == 1)
        #expect(summary.autoPrecisionNumerator == 1)
        #expect(summary.autoPrecisionDenominator == 2)
    }

    @Test func mustNotAutoMatchesByUUID() {
        let expected = ParserExpectedLine(status: .allowed(["ambiguous", "none"]), mustNotAutoIDs: ["part-a"])
        let summary = evaluate(expected: [expected], outputs: [line(firstItem, quantity: 1, status: .auto)])
        #expect(summary.falseAuto == 1)
    }

    private func evaluate(expected: [ParserExpectedLine], outputs: [ParsedLine]) -> ParserEvaluationSummary {
        let testCase = ParserEvaluationCase(id: "case", input: "input", expected: expected)
        let engine = FixedOutputParser(outputsByInput: [testCase.input: outputs])
        return ParserMetricsEvaluator().evaluate(
            cases: [testCase],
            interpreter: engine,
            catalog: [firstItem, similarItem],
            fixtureIDsByUUID: itemIDsByUUID
        )
    }

    private func line(_ item: Item, quantity: Decimal, status: ParsedLine.Status) -> ParsedLine {
        ParsedLine(
            originalText: "input",
            quantity: quantity,
            quantityWasAssumed: false,
            candidates: [(item, 1)],
            status: status
        )
    }
}

private struct FixedOutputParser: RequestInterpreting {
    let outputsByInput: [String: [ParsedLine]]
    func interpret(text: String, catalog: [Item]) -> [ParsedLine] { outputsByInput[text] ?? [] }
}
