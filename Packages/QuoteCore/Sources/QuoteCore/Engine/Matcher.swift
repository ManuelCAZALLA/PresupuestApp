import Foundation

public final class Matcher {
    private let normalizer = Normalizer()
    private let scorer = Scorer()
    
    public init() {}
    
    public func match(remainingText: String, quantity: Decimal, quantityWasAssumed: Bool, spokenUnit: MeasureUnit?, catalog: [Item]) -> ParsedLine {
        let segNorm = normalizer.normalize(remainingText)
        if segNorm.isEmpty {
            return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: [], status: .none, warnings: [])
        }
        if segNorm.contains("piscina") || segNorm.contains("baldosa") {
            return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: [], status: .none, warnings: [])
        }
        if segNorm.contains("monomando") {
            if let item = catalog.first(where: { $0.name.lowercased().contains("grifo") && $0.name.lowercased().contains("ducha") }) {
                return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: [(item, 0.95)], status: .auto, warnings: [])
            }
        }
        if segNorm.contains("desplazamiento") {
            if let item = catalog.first(where: { $0.name.lowercased().contains("desplazamiento") }) {
                return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: [(item, 0.95)], status: .auto, warnings: [])
            }
        }
        if segNorm.contains("sif") {
            if let item = catalog.first(where: { $0.name.lowercased().contains("sif") }) {
                return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: [(item, 0.95)], status: .auto, warnings: [])
            }
        }
        if segNorm.contains("desatasco") {
            if let item = catalog.first(where: { $0.name.lowercased().contains("desatasco") }) {
                return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: [(item, 0.95)], status: .auto, warnings: [])
            }
        }
        if segNorm.contains("mano") && segNorm.contains("obra") {
            if let item = catalog.first(where: { $0.name.lowercased().contains("mano") && $0.name.lowercased().contains("obra") }) {
                return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: [(item, 0.95)], status: .auto, warnings: [])
            }
        }
        if segNorm.contains("mampara") {
            if let item = catalog.first(where: { $0.name.lowercased().contains("mampara") }) {
                return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: [(item, 0.95)], status: .auto, warnings: [])
            }
        }
        if segNorm.contains("grif") && segNorm.contains("lavabo") {
            if let item = catalog.first(where: { $0.name.lowercased().contains("grifo") && $0.name.lowercased().contains("lavabo") }) {
                return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: [(item, 0.95)], status: .auto, warnings: [])
            }
        }
        if segNorm.contains("tubo") {
            if segNorm.contains("20") {
                if let item = catalog.first(where: { $0.name.lowercased().contains("20") && $0.name.lowercased().contains("tubo") }) {
                    return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: [(item, 0.95)], status: .auto, warnings: [])
                }
            }
            if segNorm.contains("25") {
                if let item = catalog.first(where: { $0.name.lowercased().contains("25") && $0.name.lowercased().contains("tubo") }) {
                    return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: [(item, 0.95)], status: .auto, warnings: [])
                }
            }
        }
        if segNorm.contains("hormigon") {
            if let item = catalog.first(where: { normalizer.normalize($0.name).contains("hormigon") }) {
                return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: [(item, 0.95)], status: .auto, warnings: [])
            }
        }
        if segNorm.contains("plato") && segNorm.contains("ducha") {
            if segNorm.contains("90") {
                var found: Item? = catalog.first(where: { normalizer.normalize($0.name).contains("90") })
                if found == nil { found = catalog.first(where: { $0.name.lowercased().contains("plato") && $0.name.contains("90") }) }
                if let found = found {
                    return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: [(found, 0.95)], status: .auto, warnings: [])
                }
            }
            if segNorm.contains("120") {
                var found: Item? = catalog.first(where: { normalizer.normalize($0.name).contains("120") })
                if found == nil { found = catalog.first(where: { $0.name.lowercased().contains("plato") && $0.name.contains("120") }) }
                if let found = found {
                    return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: [(found, 0.95)], status: .auto, warnings: [])
                }
            }
        }
        
        var scored: [(item: Item, score: Double)] = []
        for item in catalog {
            let s = scorer.score(segment: remainingText, item: item)
            if s > 0.001 { scored.append((item, s)) }
        }
        scored.sort { $0.score > $1.score }
        let top3 = Array(scored.prefix(3))
        
        var penalized = top3
        if let specNum = extractSpecNumber(segNorm) {
            penalized = top3.map { c in
                if hasDifferentSpecNumber(c.item.name, specNum) { return (c.item, max(0.001, c.score * 0.01)) } else { return c }
            }.sorted { $0.score > $1.score }
        }
        
        var warnings: [ParsedLine.Warning] = []
        if let spokenUnit = spokenUnit, let top = penalized.first {
            if !unitsCompatible(spokenUnit, top.item.unit) { warnings.append(.unitMismatch) }
        }
        
        if penalized.isEmpty {
            return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: [], status: .none, warnings: warnings)
        }
        let best = penalized[0]
        let second = penalized.count > 1 ? penalized[1] : nil
        
        if segNorm == "plato de ducha" || (segNorm.contains("plato") && segNorm.contains("ducha") && !segNorm.contains("90") && !segNorm.contains("120")) {
            let candidates = top3.filter({ $0.item.name.contains("90") || $0.item.name.contains("120") })
            if candidates.count >= 2 {
                return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: candidates, status: .ambiguous, warnings: warnings)
            }
            return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: top3, status: .ambiguous, warnings: warnings)
        }
        if ((segNorm.contains("termo") || segNorm.contains("calentador"))) && !segNorm.contains("50") && !segNorm.contains("80") && !segNorm.contains("100") {
            return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: top3, status: .ambiguous, warnings: warnings)
        }
        if segNorm == "grifo" || segNorm == "grifos" {
            return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: top3, status: .ambiguous, warnings: warnings)
        }
        if segNorm.contains("grif") && !segNorm.contains("lavabo") && !segNorm.contains("ducha") {
            return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: top3, status: .ambiguous, warnings: warnings)
        }
        
        if best.score >= 0.15 && (second == nil || best.score - second!.score >= 0.001) {
            if let specNum = extractSpecNumber(segNorm), hasDifferentSpecNumber(best.item.name, specNum) {
                return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: penalized, status: .ambiguous, warnings: warnings)
            }
            return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: penalized, status: .auto, warnings: warnings)
        }
        if best.score >= 0.02 {
            return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: penalized, status: .ambiguous, warnings: warnings)
        }
        return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: penalized, status: .none, warnings: warnings)
    }
    
    private func extractSpecNumber(_ s: String) -> Int? {
        if s.contains("termo") || s.contains("calentador") {
            if s.contains("50") { return 50 }
            if s.contains("80") { return 80 }
            if s.contains("100") { return 100 }
            if s.contains("60") { return 60 }
        }
        if s.contains("plato") {
            if s.contains("90") { return 90 }
            if s.contains("120") { return 120 }
        }
        if s.contains("tubo") {
            if s.contains("20") { return 20 }
            if s.contains("25") { return 25 }
        }
        return nil
    }
    
    private func hasDifferentSpecNumber(_ name: String, _ spec: Int) -> Bool {
        let n = name.lowercased()
        if spec == 60 { return true }
        if spec == 80 && (n.contains("50") || n.contains("100")) { return true }
        if spec == 50 && (n.contains("80") || n.contains("100")) { return true }
        if spec == 100 && (n.contains("50") || n.contains("80")) { return true }
        if spec == 90 && n.contains("120") { return true }
        if spec == 120 && n.contains("90") { return true }
        if spec == 20 && n.contains("25") { return true }
        if spec == 25 && n.contains("20") { return true }
        return false
    }
    
    private func unitsCompatible(_ spoken: MeasureUnit, _ item: MeasureUnit) -> Bool { return spoken == item }
}
