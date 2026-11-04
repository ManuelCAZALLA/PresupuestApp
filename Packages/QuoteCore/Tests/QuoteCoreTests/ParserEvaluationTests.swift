import Foundation
import Testing
@testable import QuoteCore

@Suite("Evaluación del parser")
struct ParserEvaluationTests {
    @Test func evaluateFontaneria() throws {
        try evaluate(fixture: "parser_cases_fontaneria")
    }

    private func evaluate(fixture name: String) throws {
        let casesURL = fixtureURL("\(name).json")
        let data = try Data(contentsOf: casesURL)
        let root = try JSONDecoder().decode(ParserCasesFile.self, from: data)
        let catalogURL = fixtureURL(root.catalog)
        let catalogData = try Data(contentsOf: catalogURL)
        let catalog = try JSONDecoder().decode(CatalogFile.self, from: catalogData)

        var items: [Item] = []
        for item in catalog.items {
            let priceStr = item.price.stringValue
            items.append(Item(
                id: UUID(),
                name: item.name,
                aliases: item.aliases,
                unit: parseUnit(item.unit),
                unitPrice: Decimal(string: priceStr.replacingOccurrences(of: ",", with: ".")) ?? Decimal(0),
                kind: parseKind(item.kind),
                category: item.category
            ))
        }

        var aliasMap: [UUID: [String]] = [:]
        for group in catalog.synonyms ?? [] {
            guard let first = group.first else { continue }
            guard let target = items.first(where: { matchesNameOrAliasItem($0, text: first) }) else { continue }
            var extras = aliasMap[target.id] ?? []
            for word in group.dropFirst() {
                if !extras.contains(word) { extras.append(word) }
            }
            aliasMap[target.id] = extras
        }
        items = items.map { item in
            var copy = item
            copy.aliases = item.aliases + (aliasMap[item.id] ?? [])
            return copy
        }

        let interpreter = RequestInterpreter()
        var totalAuto = 0, correctAuto = 0, falseAuto = 0
        var ambiguousExpected = 0, ambiguousRecallHits = 0
        var noneExpected = 0, noneAccuracyHits = 0
        var failed: [(String, String)] = []

        for testCase in root.cases {
            let results = interpreter.interpret(text: testCase.input, catalog: items)
            for (idx, expectation) in testCase.expect.enumerated() {
                if expectation.status == "none" {
                    noneExpected += 1
                    if results.allSatisfy({ $0.status == .none }) || results.isEmpty {
                        noneAccuracyHits += 1
                    } else {
                        failed.append(("\(name).\(testCase.id)", "esperaba none"))
                    }
                    continue
                }
                if let mustNotAuto = expectation.mustNotAuto, !mustNotAuto.isEmpty {
                    if let autoHit = results.first(where: { $0.status == .auto }), let top = autoHit.candidates.first {
                        var bad = false
                        for m in mustNotAuto {
                            if matchesNameOrAliasItem(top.item, text: m) || nameMatches(top.item.name, m) { bad = true; break }
                        }
                        if bad { falseAuto += 1; totalAuto += 1; failed.append(("\(name).\(testCase.id)", "false auto")) }
                    }
                    continue
                }
                if expectation.status == "ambiguous" {
                    ambiguousExpected += 1
                    if let amb = results.first(where: { $0.status == .ambiguous }) {
                        if matchesAny(amb, expectation.candidatesInclude ?? []) { ambiguousRecallHits += 1 }
                        else { failed.append(("\(name).\(testCase.id)", "ambiguous")) }
                    } else {
                        failed.append(("\(name).\(testCase.id)", "esperaba ambiguous"))
                    }
                    continue
                }
                if expectation.status == "auto" {
                    totalAuto += 1
                    var autoRes: ParsedLine? = nil
                    if results.count == testCase.expect.count && idx < results.count && results[idx].status == .auto {
                        autoRes = results[idx]
                    }
                    if autoRes == nil {
                        autoRes = results.first(where: { $0.status == .auto })
                    }
                    guard let ar = autoRes, ar.status == .auto, let top = ar.candidates.first else {
                        failed.append(("\(name).\(testCase.id)", "esperaba auto"))
                        continue
                    }
                    if let exp = expectation.item {
                        if nameMatches(top.item.name, exp) || matchesNameOrAliasItem(top.item, text: exp) { correctAuto += 1 }
                        else { failed.append(("\(name).\(testCase.id)", "auto incorrecto")); falseAuto += 1 }
                    } else { correctAuto += 1 }
                    if let qty = expectation.qty {
                        if abs(NSDecimalNumber(decimal: ar.quantity).doubleValue - qty) > 0.001 {
                            failed.append(("\(name).\(testCase.id)", "qty"))
                        }
                    }
                    continue
                }
                if let statusIn = expectation.statusIn {
                    if !results.contains(where: { statusIn.contains($0.status.rawValue) }) {
                        failed.append(("\(name).\(testCase.id)", "statusIn"))
                    }
                    continue
                }
            }
        }

        let autoPrecision = totalAuto == 0 ? 1.0 : Double(correctAuto) / Double(totalAuto)
        let falseAutoRate = root.cases.isEmpty ? 0.0 : Double(falseAuto) / Double(root.cases.count)
        let ambiguousRecall = ambiguousExpected == 0 ? 1.0 : Double(ambiguousRecallHits) / Double(ambiguousExpected)
        let noneAccuracy = noneExpected == 0 ? 1.0 : Double(noneAccuracyHits) / Double(noneExpected)

        print("[PARSER][\(name)] autoPrecision=\(String(format: "%.3f", autoPrecision)) correctAuto=\(correctAuto)/\(totalAuto) falseAutoRate=\(String(format: "%.3f", falseAutoRate)) falseAuto=\(falseAuto) ambiguousRecall=\(String(format: "%.3f", ambiguousRecall)) \(ambiguousRecallHits)/\(ambiguousExpected) noneAccuracy=\(String(format: "%.3f", noneAccuracy)) \(noneAccuracyHits)/\(noneExpected)")
        for f in failed.prefix(40) { print("[PARSER][FAIL] \(f.0): \(f.1)") }

        #expect(autoPrecision >= 0.98)
        #expect(falseAutoRate <= 0.02)
        #expect(ambiguousRecall >= 0.90)
        #expect(noneAccuracy >= 1.0)
    }

    private func matchesAny(_ r: ParsedLine, _ candidates: [String]) -> Bool {
        let names = r.candidates.map { $0.item.name.lowercased() }
        for c in candidates {
            if c == "termo-50l" && names.contains(where: { $0.contains("50") }) { return true }
            if c == "termo-80l" && names.contains(where: { $0.contains("80") }) { return true }
            if c == "termo-100l" && names.contains(where: { $0.contains("100") }) { return true }
            if c == "plato-ducha-90" && names.contains(where: { $0.contains("90") }) { return true }
            if c == "plato-ducha-120" && names.contains(where: { $0.contains("120") }) { return true }
            if c == "grifo-lavabo" && names.contains(where: { $0.contains("lavabo") }) { return true }
            if c == "grifo-ducha" && names.contains(where: { $0.contains("grifo") && $0.contains("ducha") }) { return true }
        }
        return false
    }

    private func nameMatches(_ itemName: String, _ expected: String) -> Bool {
        let n = itemName.lowercased(); let e = expected.lowercased()
        if e == "urinario" { return n.contains("urinario") }
        if e == "inodoro" { return n.contains("inodoro") }
        if e == "plato-ducha-90" { return n.contains("90") }
        if e == "plato-ducha-120" { return n.contains("120") }
        if e == "termo-80l" { return n.contains("80") }
        if e == "termo-100l" { return n.contains("100") }
        if e == "termo-50l" { return n.contains("50") }
        if e == "grifo-lavabo" { return n.contains("lavabo") }
        if e == "grifo-ducha" { return n.contains("grifo") && n.contains("ducha") }
        if e == "sifon" { return n.contains("sif") }
        if e == "desatasco" { return n.contains("desatasco") }
        if e == "tubo-pex-20" { return n.contains("20") }
        if e == "tubo-pex-25" { return n.contains("25") }
        if e == "mano-obra-hora" { return n.contains("mano") && n.contains("obra") }
        if e == "desplazamiento" { return n.contains("desplazamiento") }
        if e == "mampara-ducha" { return n.contains("mampara") }
        if e == "hormigon" { return n.contains("hormigon") }
        if e == "mortero" { return n.contains("mortero") }
        if e == "enfoscado" { return n.contains("enfoscado") }
        if e == "alicatado" { return n.contains("alicatado") }
        if e == "solado" { return n.contains("solado") }
        if e == "punto-luz" { return n.contains("punto") }
        if e == "enchufe" { return n.contains("enchufe") || n.contains("toma") }
        if e == "cuadro" { return n.contains("cuadro") }
        if e == "ladrillo" { return n.contains("ladrillo") }
        return n.contains(e) || e.contains(n)
    }

    private func matchesNameOrAliasItem(_ item: Item, text: String) -> Bool {
        let t = norm(text)
        if norm(item.name) == t { return true }
        return item.aliases.contains { norm($0) == t }
    }

    private func norm(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es_ES"))
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9 ]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseUnit(_ s: String) -> MeasureUnit {
        switch s { case "m": return .meter; case "m2": return .squareMeter; case "m3": return .cubicMeter; case "h": return .hour; case "pa","global": return .lumpSum; default: return .unit }
    }
    private func parseKind(_ s: String) -> ItemKind {
        switch s { case "material": return .material; case "labor": return .labor; case "travel": return .travel; default: return .other }
    }
    private func fixtureURL(_ name: String) -> URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures").appendingPathComponent(name)
    }
}

private struct ParserCasesFile: Decodable { let catalog: String; let cases: [ParserTestCase] }
private struct ParserTestCase: Decodable { let id: String; let input: String; let expect: [ParserExpectation] }
private struct ParserExpectation: Decodable { let item: String?; let qty: Double?; let status: String?; let statusIn: [String]?; let candidatesInclude: [String]?; let mustNotAuto: [String]?; let assumedQuantity: Bool?; let unit: String? }
private struct CatalogFile: Decodable { let trade: String?; let synonyms: [[String]]?; let items: [CatalogItem] }
private struct CatalogItem: Decodable { let id: String; let name: String; let aliases: [String]; let unit: String; let price: PriceValue; let kind: String; let category: String? }
private enum PriceValue: Decodable {
    case string(String); case number(Double)
    var stringValue: String { switch self { case .string(let s): return s; case .number(let n): return String(format: "%.2f", n) } }
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self) { self = .string(s); return }
        if let n = try? c.decode(Double.self) { self = .number(n); return }
        self = .string("0")
    }
}
