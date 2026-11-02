import Foundation

public final class Scorer {
    private let normalizer = Normalizer()
    
    public init() {}
    
    public func score(segment: String, item: Item) -> Double {
        let segNorm = normalizer.normalize(segment)
        let itemName = normalizer.normalize(item.name)
        var score = 0.0
        
        // Use general matching based on token overlap and aliases
        let segTokens = Set(segNorm.split(separator: " ").map(String.init).filter { !$0.isEmpty && $0.count > 2 })
        let itemTokens = itemName.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        if !itemTokens.isEmpty {
            let inter = segTokens.intersection(Set(itemTokens)).count
            score += 0.45 * Double(inter) / Double(max(itemTokens.count, 1))
        }
        score += 0.35 * trigramSimilarity(segNorm, itemName)
        
        for a in item.aliases {
            let na = normalizer.normalize(a)
            if !na.isEmpty && segNorm.contains(na) {
                score += 0.20
                break
            }
        }
        // also boost if direct containment
        if segNorm.contains(itemName) && itemName.count > 3 {
            score += 0.1
        }
        return min(max(score, 0.0), 1.0)
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
        if chars.count < 3 { return [s] }
        var set = Set<String>()
        for i in 0..<(chars.count - 2) {
            set.insert(String(chars[i...i+2]))
        }
        return set
    }
}
