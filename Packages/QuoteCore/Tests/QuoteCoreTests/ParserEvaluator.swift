import Foundation
@testable import QuoteCore

enum ParserExpectedStatus: Equatable {
    case auto
    case ambiguous([String])
    case none
    case allowed([String])
}

struct ParserExpectedLine {
    let itemID: String?
    let quantity: Decimal?
    let unit: MeasureUnit?
    let status: ParserExpectedStatus
    let mustNotAutoIDs: [String]

    init(
        itemID: String? = nil,
        quantity: Decimal? = nil,
        unit: MeasureUnit? = nil,
        status: ParserExpectedStatus,
        mustNotAutoIDs: [String] = []
    ) {
        self.itemID = itemID
        self.quantity = quantity
        self.unit = unit
        self.status = status
        self.mustNotAutoIDs = mustNotAutoIDs
    }

    var targetIDs: Set<String> {
        switch status {
        case .auto: return Set(itemID.map { [$0] } ?? [])
        case .ambiguous(let ids): return Set(ids)
        case .none, .allowed: return []
        }
    }
}

struct ParserEvaluationCase {
    let id: String
    let input: String
    let expected: [ParserExpectedLine]
}

struct ParserCaseEvaluation {
    let testCase: ParserEvaluationCase
    let obtained: [ParsedLine]
    let segmentationMismatch: Bool
    let unmatchedExpectedCount: Int
    let unmatchedEmittedCount: Int
    let causes: [String]
}

struct ParserEvaluationSummary {
    let totalExpectedLines: Int
    let autoEmitted: Int
    let correctAuto: Int
    let falseAuto: Int
    let autoRecallNumerator: Int
    let autoRecallDenominator: Int
    let autoPrecisionNumerator: Int
    let autoPrecisionDenominator: Int
    let falseAutoRateNumerator: Int
    let falseAutoRateDenominator: Int
    let ambiguousRecallNumerator: Int
    let ambiguousRecallDenominator: Int
    let noneAccuracyNumerator: Int
    let noneAccuracyDenominator: Int
    let top3RecallNumerator: Int
    let top3RecallDenominator: Int
    let reports: [ParserCaseEvaluation]

    func ratio(_ numerator: Int, _ denominator: Int) -> String {
        guard denominator > 0 else { return "n/a" }
        let value = Double(numerator) / Double(denominator)
        return String(format: "%.3f (%d/%d)", value, numerator, denominator)
    }
}

struct ParserMetricsEvaluator {
    func evaluate(
        cases: [ParserEvaluationCase],
        interpreter: any RequestInterpreting,
        catalog: [Item],
        fixtureIDsByUUID: [UUID: String]
    ) -> ParserEvaluationSummary {
        var totalExpectedLines = 0
        var autoEmitted = 0
        var correctAuto = 0
        var falseAuto = 0
        var autoRecallNumerator = 0
        var autoRecallDenominator = 0
        var ambiguousRecallNumerator = 0
        var ambiguousRecallDenominator = 0
        var noneAccuracyNumerator = 0
        var noneAccuracyDenominator = 0
        var top3RecallNumerator = 0
        var top3RecallDenominator = 0
        var reports: [ParserCaseEvaluation] = []

        for testCase in cases {
            let obtained = interpreter.interpret(text: testCase.input, catalog: catalog)
            totalExpectedLines += testCase.expected.count
            autoEmitted += obtained.filter { $0.status == .auto }.count
            let pairedCount = min(testCase.expected.count, obtained.count)
            let segmentationMismatch = testCase.expected.count != obtained.count
            var falseAutomaticIndexes: Set<Int> = []
            var causes: [String] = []

            if segmentationMismatch {
                causes.append("segmentación: esperadas \(testCase.expected.count), obtenidas \(obtained.count)")
            }

            for index in 0..<testCase.expected.count {
                let expected = testCase.expected[index]
                if case .auto = expected.status { autoRecallDenominator += 1 }
                if case .ambiguous = expected.status { ambiguousRecallDenominator += 1 }
                if case .none = expected.status { noneAccuracyDenominator += 1 }

                guard index < pairedCount else {
                    if case .auto = expected.status {
                        causes.append("línea esperada \(index + 1) sin pareja: no emitida")
                    }
                    if !expected.targetIDs.isEmpty { top3RecallDenominator += 1 }
                    continue
                }

                let actual = obtained[index]
                switch expected.status {
                case .auto:
                    if actual.status == .auto { autoRecallNumerator += 1 }
                    if actual.status == .auto {
                        let actualID = actual.candidates.first.flatMap { fixtureIDsByUUID[$0.item.id] }
                        let itemMatches = actualID == expected.itemID
                        let quantityMatches = expected.quantity.map { actual.quantity == $0 } ?? true
                        let unitMatches = expected.unit.map { actual.spokenUnit == $0 } ?? true
                        if itemMatches && quantityMatches && unitMatches {
                            correctAuto += 1
                        } else {
                            falseAutomaticIndexes.insert(index)
                            if !itemMatches { causes.append("línea \(index + 1): UUID de partida incorrecto") }
                            if !quantityMatches { causes.append("línea \(index + 1): cantidad incorrecta") }
                            if !unitMatches { causes.append("línea \(index + 1): unidad incorrecta") }
                        }
                    } else {
                        causes.append("línea \(index + 1): se esperaba auto y salió \(actual.status.rawValue)")
                    }
                case .ambiguous(let expectedIDs):
                    if actual.status == .auto {
                        falseAutomaticIndexes.insert(index)
                        causes.append("línea \(index + 1): auto falso en expectativa ambiguous")
                    }
                    if actual.status == .ambiguous,
                       containsAnyID(expectedIDs, in: actual, fixtureIDsByUUID: fixtureIDsByUUID) {
                        ambiguousRecallNumerator += 1
                    } else {
                        causes.append("línea \(index + 1): ambiguous no recuperado")
                    }
                case .none:
                    if actual.status == .none { noneAccuracyNumerator += 1 }
                    if actual.status == .auto { falseAutomaticIndexes.insert(index) }
                    if actual.status != .none { causes.append("línea \(index + 1): se esperaba none y salió \(actual.status.rawValue)") }
                case .allowed(let statuses):
                    if actual.status == .auto { falseAutomaticIndexes.insert(index) }
                    if !statuses.contains(actual.status.rawValue) {
                        causes.append("línea \(index + 1): estado \(actual.status.rawValue) fuera de \(statuses.joined(separator: "|"))")
                    }
                }

                if actual.status != .auto && !expected.targetIDs.isEmpty {
                    top3RecallDenominator += 1
                    if containsAnyID(Array(expected.targetIDs), in: actual, fixtureIDsByUUID: fixtureIDsByUUID) {
                        top3RecallNumerator += 1
                    }
                }
            }

            if obtained.count > pairedCount {
                for index in pairedCount..<obtained.count {
                    if obtained[index].status == .auto {
                        falseAutomaticIndexes.insert(index)
                        causes.append("línea emitida \(index + 1) sobrante: auto falso")
                    } else {
                        causes.append("línea emitida \(index + 1) sobrante")
                    }
                }
            }

            let prohibitedIDs = Set(testCase.expected.flatMap(\.mustNotAutoIDs))
            if !prohibitedIDs.isEmpty {
                for (index, actual) in obtained.enumerated() where actual.status == .auto {
                    let actualID = actual.candidates.first.flatMap { fixtureIDsByUUID[$0.item.id] }
                    if let actualID, prohibitedIDs.contains(actualID) {
                        falseAutomaticIndexes.insert(index)
                        causes.append("línea \(index + 1): UUID incluido en mustNotAuto")
                    }
                }
            }

            falseAuto += falseAutomaticIndexes.count
            reports.append(ParserCaseEvaluation(
                testCase: testCase,
                obtained: obtained,
                segmentationMismatch: segmentationMismatch,
                unmatchedExpectedCount: max(0, testCase.expected.count - obtained.count),
                unmatchedEmittedCount: max(0, obtained.count - testCase.expected.count),
                causes: causes
            ))
        }

        return ParserEvaluationSummary(
            totalExpectedLines: totalExpectedLines,
            autoEmitted: autoEmitted,
            correctAuto: correctAuto,
            falseAuto: falseAuto,
            autoRecallNumerator: autoRecallNumerator,
            autoRecallDenominator: autoRecallDenominator,
            autoPrecisionNumerator: correctAuto,
            autoPrecisionDenominator: autoEmitted,
            falseAutoRateNumerator: falseAuto,
            falseAutoRateDenominator: totalExpectedLines,
            ambiguousRecallNumerator: ambiguousRecallNumerator,
            ambiguousRecallDenominator: ambiguousRecallDenominator,
            noneAccuracyNumerator: noneAccuracyNumerator,
            noneAccuracyDenominator: noneAccuracyDenominator,
            top3RecallNumerator: top3RecallNumerator,
            top3RecallDenominator: top3RecallDenominator,
            reports: reports
        )
    }

    private func containsAnyID(_ ids: [String], in line: ParsedLine, fixtureIDsByUUID: [UUID: String]) -> Bool {
        let expectedIDs = Set(ids)
        return line.candidates.prefix(3).contains { candidate in
            guard let fixtureID = fixtureIDsByUUID[candidate.item.id] else { return false }
            return expectedIDs.contains(fixtureID)
        }
    }
}

enum FixtureItemUUIDs {
    static func make(for ids: [String]) -> [String: UUID] {
        Dictionary(uniqueKeysWithValues: ids.map { ($0, uuid(for: $0)) })
    }

    static func uuid(for value: String) -> UUID {
        var first: UInt64 = 14_695_981_039_346_656_037
        var second: UInt64 = 10_995_116_282_11
        for byte in value.utf8 {
            first = (first ^ UInt64(byte)) &* 1_099_511_628_211
            second = (second ^ UInt64(byte)) &* 1_099_511_628_211
        }
        var bytes: [UInt8] = []
        for value in [first, second] {
            for shift in stride(from: 56, through: 0, by: -8) {
                bytes.append(UInt8((value >> UInt64(shift)) & 0xff))
            }
        }
        bytes[6] = (bytes[6] & 0x0f) | 0x50
        bytes[8] = (bytes[8] & 0x3f) | 0x80
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}
