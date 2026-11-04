import Foundation

public final class Scorer {
    private let normalizer = Normalizer()
    
    public init() {}
    
    public func buildIDF(from catalog: [Item]) {
        // no-op for compatibility
    }
    
    public func score(segment: String, item: Item, config: ParserConfig = .default) -> Double {
        let segNorm = normalizer.normalize(segment)
        let itemName = normalizer.normalize(item.name)
        var score = 0.0
        
        // Exact alias/name matches
        for alias in item.aliases {
            let aliasNorm = normalizer.normalize(alias)
            if aliasNorm.isEmpty { continue }
            if segNorm == aliasNorm {
                score += 1.5
            } else if segNorm.contains(aliasNorm) || aliasNorm.contains(segNorm) {
                score += 1.0
            }
        }
        if segNorm == itemName {
            score += 1.0
        } else if segNorm.contains(itemName) || itemName.contains(segNorm) {
            score += 0.6
        }
        
        let segTokens = Set(segNorm.split(separator: " ").map(String.init).filter { !$0.isEmpty })
        let itemTokens = itemName.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        if !itemTokens.isEmpty {
            let inter = segTokens.intersection(Set(itemTokens)).count
            score += 0.8 * Double(inter) / Double(max(itemTokens.count, 1))
        }
        score += 0.4 * trigramSimilarity(segNorm, itemName)
        return min(score, 1.0)
    }
    
    private func trigramSimilarity(_ a: String, _ b: String) -> Double {
        let ta = trigrams(a)
        let tb = trigrams(b)
        if ta.isEmpty || tb.isEmpty { return 0 }
        let inter = ta.intersection(tb).count
        return Double(inter) / Double(max(ta.count, tb.count))
    }
    
    private func trigrams(_ s: String) -> Set<String> {
        let chars = Array(s.replacingOccurrences(of: " ", with: "_"))
        if chars.count < 3 { return Set([s]) }
        var set = Set<String>()
        for i in 0..<(chars.count - 2) {
            set.insert(String(chars[i...i+2]))
        }
        return set
    }
}
