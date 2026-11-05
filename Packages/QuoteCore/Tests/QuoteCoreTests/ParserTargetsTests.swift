import Testing

@Suite("Objetivos del motor del parser")
struct ParserTargetsTests {
    @Test func parserTargets() throws {
        let summaries = try ParserEvaluationTests().evaluateAllFixtures(report: false)
        for (fixture, summary) in summaries {
            #expect(
                summary.autoPrecisionDenominator == 0 || ratio(summary.autoPrecisionNumerator, summary.autoPrecisionDenominator) >= 0.98,
                "\(fixture): autoPrecision"
            )
            #expect(
                summary.falseAutoRateDenominator == 0 || ratio(summary.falseAutoRateNumerator, summary.falseAutoRateDenominator) <= 0.02,
                "\(fixture): falseAutoRate"
            )
            #expect(
                summary.ambiguousRecallDenominator == 0 || ratio(summary.ambiguousRecallNumerator, summary.ambiguousRecallDenominator) >= 0.90,
                "\(fixture): ambiguousRecall"
            )
            #expect(
                summary.noneAccuracyDenominator == 0 || ratio(summary.noneAccuracyNumerator, summary.noneAccuracyDenominator) >= 1.0,
                "\(fixture): noneAccuracy"
            )
            #expect(
                summary.top3RecallDenominator == 0 || ratio(summary.top3RecallNumerator, summary.top3RecallDenominator) >= 0.95,
                "\(fixture): top3Recall"
            )
        }
    }

    private func ratio(_ numerator: Int, _ denominator: Int) -> Double {
        guard denominator > 0 else { return 1 }
        return Double(numerator) / Double(denominator)
    }
}
