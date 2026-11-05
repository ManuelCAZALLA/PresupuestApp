import Foundation
import Testing
@testable import QuoteCore

@Suite("Evaluación del parser")
struct ParserEvaluationTests {
    @Test func evaluateAllFixtures() throws {
        _ = try evaluateAllFixtures(report: true)
    }

    func evaluateAllFixtures(report: Bool) throws -> [(String, ParserEvaluationSummary)] {
        let fixtureDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
        let caseFiles = try FileManager.default.contentsOfDirectory(
            at: fixtureDirectory,
            includingPropertiesForKeys: nil
        )
        .filter { $0.lastPathComponent.hasPrefix("parser_cases_") && $0.pathExtension == "json" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

        var summaries: [(String, ParserEvaluationSummary)] = []
        for casesURL in caseFiles {
            let caseFile = try JSONDecoder().decode(ParserCaseFile.self, from: Data(contentsOf: casesURL))
            let catalogURL = fixtureDirectory.appendingPathComponent(caseFile.catalog)
            let catalogFile = try JSONDecoder().decode(ParserCatalogFile.self, from: Data(contentsOf: catalogURL))
            let idsByValue = FixtureItemUUIDs.make(for: catalogFile.items.map(\.id))
            let uuidsByID = Dictionary(uniqueKeysWithValues: idsByValue.map { ($0.value, $0.key) })
            let aliasesByID = synonymAliases(catalog: catalogFile)

            let catalog = try catalogFile.items.map { fixtureItem -> Item in
                guard let uuid = idsByValue[fixtureItem.id] else {
                    throw ParserEvaluationError.missingFixtureID(fixtureItem.id)
                }
                let aliases = fixtureItem.aliases + (aliasesByID[fixtureItem.id] ?? [])
                let priceText = fixtureItem.price.stringValue.replacingOccurrences(of: ",", with: ".")
                return Item(
                    id: uuid,
                    name: fixtureItem.name,
                    aliases: aliases,
                    unit: parseUnit(fixtureItem.unit),
                    unitPrice: Decimal(string: priceText) ?? 0,
                    kind: parseKind(fixtureItem.kind),
                    category: fixtureItem.category
                )
            }

            let cases = caseFile.cases.map { fixtureCase in
                ParserEvaluationCase(
                    id: fixtureCase.id,
                    input: fixtureCase.input,
                    expected: fixtureCase.expect.map { expected in
                        ParserExpectedLine(
                            itemID: expected.item,
                            quantity: expected.qty.map { Decimal(string: String($0)) ?? 0 },
                            unit: expected.unit.map(parseUnit),
                            status: expectedStatus(expected),
                            mustNotAutoIDs: expected.mustNotAuto ?? []
                        )
                    }
                )
            }

            let summary = ParserMetricsEvaluator().evaluate(
                cases: cases,
                interpreter: RequestInterpreter(),
                catalog: catalog,
                fixtureIDsByUUID: uuidsByID
            )
            summaries.append((casesURL.deletingPathExtension().lastPathComponent, summary))
            if report { printReport(fixture: casesURL.lastPathComponent, summary: summary, uuidsByID: uuidsByID) }
        }
        return summaries
    }

    private func synonymAliases(catalog: ParserCatalogFile) -> [String: [String]] {
        var aliasesByID: [String: [String]] = [:]
        for group in catalog.synonyms ?? [] {
            guard let first = group.first else { continue }
            let normalizedFirst = normalizeCatalogText(first)
            guard let target = catalog.items.first(where: { item in
                ([item.name] + item.aliases).contains { normalizeCatalogText($0) == normalizedFirst }
            }) else { continue }
            for synonym in group.dropFirst() where !aliasesByID[target.id, default: []].contains(synonym) {
                aliasesByID[target.id, default: []].append(synonym)
            }
        }
        return aliasesByID
    }

    private func expectedStatus(_ expected: ParserExpectedJSON) -> ParserExpectedStatus {
        switch expected.status {
        case "auto": return .auto
        case "ambiguous": return .ambiguous(expected.candidatesInclude ?? [])
        case "none": return .none
        default: return .allowed(expected.statusIn ?? [])
        }
    }

    private func printReport(fixture: String, summary: ParserEvaluationSummary, uuidsByID: [UUID: String]) {
        print("[PARSER][\(fixture)] totalExpectedLines=\(summary.totalExpectedLines) autoEmitted=\(summary.autoEmitted) correctAuto=\(summary.correctAuto) falseAuto=\(summary.falseAuto) autoPrecision=\(summary.ratio(summary.autoPrecisionNumerator, summary.autoPrecisionDenominator)) autoRecall=\(summary.ratio(summary.autoRecallNumerator, summary.autoRecallDenominator)) falseAutoRate=\(summary.ratio(summary.falseAutoRateNumerator, summary.falseAutoRateDenominator)) ambiguousRecall=\(summary.ratio(summary.ambiguousRecallNumerator, summary.ambiguousRecallDenominator)) noneAccuracy=\(summary.ratio(summary.noneAccuracyNumerator, summary.noneAccuracyDenominator)) top3Recall=\(summary.ratio(summary.top3RecallNumerator, summary.top3RecallDenominator))")
        for report in summary.reports where !report.causes.isEmpty {
            let expected = report.testCase.expected.map { expectedLine in
                "item=\(expectedLine.itemID ?? "-") qty=\(expectedLine.quantity.map { NSDecimalNumber(decimal: $0).stringValue } ?? "-") unit=\(expectedLine.unit?.rawValue ?? "-") status=\(statusDescription(expectedLine.status))"
            }.joined(separator: "; ")
            let obtained = report.obtained.map { parsedLine in
                let itemID = parsedLine.candidates.first.flatMap { uuidsByID[$0.item.id] } ?? "-"
                let top3 = parsedLine.candidates.prefix(3).map { candidate in
                    "\(uuidsByID[candidate.item.id] ?? "-")@\(String(format: "%.6f", candidate.score))"
                }.joined(separator: "|")
                return "item=\(itemID) qty=\(NSDecimalNumber(decimal: parsedLine.quantity).stringValue) unit=\(parsedLine.spokenUnit?.rawValue ?? "-") status=\(parsedLine.status.rawValue) top3=[\(top3)]"
            }.joined(separator: "; ")
            print("[PARSER_CASE][\(fixture)][\(report.testCase.id)] input=\(report.testCase.input.debugDescription) expected=[\(expected)] obtained=[\(obtained)] causes=[\(report.causes.joined(separator: "; "))]")
        }
    }

    private func statusDescription(_ status: ParserExpectedStatus) -> String {
        switch status {
        case .auto: return "auto"
        case .ambiguous(let ids): return "ambiguous(\(ids.joined(separator: "|")))"
        case .none: return "none"
        case .allowed(let statuses): return "allowed(\(statuses.joined(separator: "|")))"
        }
    }

    private func normalizeCatalogText(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es_ES"))
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseUnit(_ value: String) -> MeasureUnit {
        switch value {
        case "m": return .meter
        case "m2": return .squareMeter
        case "m3": return .cubicMeter
        case "h": return .hour
        case "pa", "global": return .lumpSum
        default: return .unit
        }
    }

    private func parseKind(_ value: String) -> ItemKind {
        switch value {
        case "material": return .material
        case "labor": return .labor
        case "travel": return .travel
        default: return .other
        }
    }

}

private enum ParserEvaluationError: Error {
    case missingFixtureID(String)
}

private struct ParserCaseFile: Decodable {
    let catalog: String
    let cases: [ParserCaseJSON]
}

private struct ParserCaseJSON: Decodable {
    let id: String
    let input: String
    let expect: [ParserExpectedJSON]
}

private struct ParserExpectedJSON: Decodable {
    let item: String?
    let qty: Double?
    let status: String?
    let statusIn: [String]?
    let candidatesInclude: [String]?
    let mustNotAuto: [String]?
    let unit: String?
}

private struct ParserCatalogFile: Decodable {
    let synonyms: [[String]]?
    let items: [ParserCatalogItem]
}

private struct ParserCatalogItem: Decodable {
    let id: String
    let name: String
    let aliases: [String]
    let unit: String
    let price: ParserPriceValue
    let kind: String
    let category: String?
}

private enum ParserPriceValue: Decodable {
    case string(String)
    case number(Double)

    var stringValue: String {
        switch self {
        case .string(let value): return value
        case .number(let value): return String(value)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode(Double.self) { self = .number(value) }
        else { self = .string("0") }
    }
}
