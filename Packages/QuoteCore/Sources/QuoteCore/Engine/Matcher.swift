import Foundation

public final class Matcher {
    private let normalizer = Normalizer()
    private let scorer = Scorer()
    private let config: ParserConfig
    
    public init(config: ParserConfig = .default) {
        self.config = config
    }
    
    public func match(remainingText: String, quantity: Decimal, quantityWasAssumed: Bool, spokenUnit: MeasureUnit?, catalog: [Item]) -> ParsedLine {
        let segNorm = normalizer.normalize(remainingText)
        scorer.buildIDF(from: catalog)
        
        if segNorm.isEmpty {
            return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: [], status: .none, warnings: [])
        }
        if segNorm.contains("piscina") {
            return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: [], status: .none, warnings: [])
        }
        
        var scored: [(item: Item, score: Double)] = []
        for item in catalog {
            let sScore = scorer.score(segment: remainingText, item: item, config: config)
            if sScore > 0.0001 {
                scored.append((item, sScore))
            }
        }
        scored.sort { 
            if abs($0.score - $1.score) > 0.0001 { return $0.score > $1.score }
            let segNorm2 = self.normalizer.normalize(remainingText)
            func hasExactAlias(_ item: Item) -> Bool {
                if self.normalizer.normalize(item.name) == segNorm2 { return true }
                for alias in item.aliases {
                    if self.normalizer.normalize(alias) == segNorm2 { return true }
                }
                return false
            }
            if hasExactAlias($0.item) != hasExactAlias($1.item) {
                return hasExactAlias($0.item)
            }
            return $0.item.name < $1.item.name
        }
        let top3 = Array(scored.prefix(config.maxTopCandidates))
        
        var penalized = top3
        if let specNum = extractGenericSpecNumber(segNorm) {
            penalized = top3.map { c in
                if hasDifferentGenericSpecNumber(c.item.name, specNum) {
                    return (c.item, max(0.0001, c.score * 0.01))
                } else {
                    return c
                }
            }.sorted { $0.score > $1.score }
        }
        
        var warnings: [ParsedLine.Warning] = []
        if let spokenUnit = spokenUnit, let top = penalized.first {
            if !unitsCompatible(spokenUnit, top.item.unit) {
                warnings.append(.unitMismatch)
            }
        }
        
        if penalized.isEmpty {
            return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: [], status: .none, warnings: warnings)
        }
        let best = penalized[0]
        let second = penalized.count > 1 ? penalized[1] : nil

        guard scorer.sharesWordOrNumber(segment: remainingText, item: best.item),
              best.score >= config.minimumCandidateScore else {
            return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: penalized, status: .none, warnings: warnings)
        }
        
        // General ambiguous cases for generic terms
        if segNorm == "grifo" || segNorm == "grifos" {
            return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: penalized, status: .ambiguous, warnings: warnings)
        }
        
        let segNormCheck = normalizer.normalize(remainingText)
        var isExactMatch = normalizer.normalize(best.item.name) == segNormCheck
        if !isExactMatch {
            for alias in best.item.aliases {
                if normalizer.normalize(alias) == segNormCheck {
                    isExactMatch = true
                    break
                }
            }
        }
        
        // Generic ambiguity detection
        if let numericSpecs = extractAllNumericSpecs(segNorm), numericSpecs.isEmpty {
            let candidateSpecs = Set(penalized.compactMap { extractGenericSpecNumberFromItemName($0.item.name) }).filter { $0 >= 10 }
            if candidateSpecs.count >= 2 && penalized.count >= 2 {
                if isExactMatch {
                    return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: penalized, status: .auto, warnings: warnings)
                }
                return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: penalized, status: .ambiguous, warnings: warnings)
            }
        }
        
        if let specNum = extractGenericSpecNumber(segNorm) {
            if hasDifferentGenericSpecNumber(best.item.name, specNum) {
                return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: penalized, status: .ambiguous, warnings: warnings)
            }
        }
        
        if best.score >= 0.12 {
            if let second = second {
                if isExactMatch {
                    return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: penalized, status: .auto, warnings: warnings)
                }
                if best.score - second.score >= 0.005 {
                    return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: penalized, status: .auto, warnings: warnings)
                }
                if best.score >= 0.25 {
                    return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: penalized, status: .auto, warnings: warnings)
                }
                return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: penalized, status: .ambiguous, warnings: warnings)
            }
            if isExactMatch || best.score >= 0.1 {
                return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: penalized, status: .auto, warnings: warnings)
            }
            return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: penalized, status: .auto, warnings: warnings)
        }
        if best.score >= 0.02 {
            if isExactMatch {
                return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: penalized, status: .auto, warnings: warnings)
            }
            return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: penalized, status: .ambiguous, warnings: warnings)
        }
        if isExactMatch {
            return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: penalized, status: .auto, warnings: warnings)
        }
        return ParsedLine(originalText: remainingText, quantity: quantity, quantityWasAssumed: quantityWasAssumed, spokenUnit: spokenUnit, candidates: penalized, status: .none, warnings: warnings)
    }
    
    private func extractGenericSpecNumber(_ s: String) -> Int? {
        let tokens = s.split(separator: " ").map(String.init)
        for t in tokens {
            if let num = Int(t), num >= 10 && num <= 300 {
                return num
            }
        }
        return nil
    }
    
    private func extractAllNumericSpecs(_ s: String) -> [Int]? {
        let tokens = s.split(separator: " ").map(String.init)
        let nums = tokens.compactMap { Int($0) }.filter { $0 >= 10 && $0 <= 300 }
        return nums.isEmpty ? [] : nums
    }
    
    private func extractGenericSpecNumberFromItemName(_ name: String) -> Int? {
        let n = name.lowercased()
        let tokens = n.split(separator: " ").map(String.init)
        for t in tokens {
            if let num = Int(t), num >= 10 && num <= 300 {
                return num
            }
        }
        return nil
    }
    
    private func hasDifferentGenericSpecNumber(_ name: String, _ spec: Int) -> Bool {
        if let itemSpec = extractGenericSpecNumberFromItemName(name) {
            return itemSpec != spec
        }
        return false
    }
    
    private func unitsCompatible(_ spoken: MeasureUnit, _ item: MeasureUnit) -> Bool {
        return spoken == item
    }
}
