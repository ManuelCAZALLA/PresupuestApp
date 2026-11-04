import Foundation

public final class Scorer {
    private let normalizer = Normalizer()
    
    public init() {}
    
    public func score(segment: String, item: Item) -> Double {
        let segNorm = normalizer.normalize(segment)
        let itemName = normalizer.normalize(item.name)
        var score = 0.0
        
        if segNorm.contains("hormigon") && itemName.contains("hormigon") { score += 2.0 }
        if segNorm.contains("hormig") && itemName.contains("hormig") { score += 2.0 }
        if segNorm.contains("mortero") && itemName.contains("mortero") { score += 2.0 }
        if segNorm.contains("enfoscado") && itemName.contains("enfoscado") { score += 2.0 }
        if segNorm.contains("alicatado") && itemName.contains("alicatado") { score += 2.0 }
        if segNorm.contains("solado") && itemName.contains("solado") { score += 2.0 }
        if segNorm.contains("punto") && itemName.contains("punto") { score += 2.0 }
        if segNorm.contains("enchufe") && itemName.contains("enchufe") { score += 2.0 }
        if segNorm.contains("cuadro") && itemName.contains("cuadro") { score += 2.0 }
        if segNorm.contains("ladrillo") && itemName.contains("ladrillo") { score += 2.0 }
        if segNorm.contains("urinario") && itemName.contains("urinario") { score += 1.0 }
        if segNorm.contains("inodoro") && itemName.contains("inodoro") { score += 1.0 }
        if segNorm.contains("wc") && itemName.contains("inodoro") { score += 1.0 }
        if segNorm.contains("plato") && segNorm.contains("ducha") {
            if segNorm.contains("90") && itemName.contains("90") { score += 1.0 }
            else if segNorm.contains("120") && itemName.contains("120") { score += 1.0 }
            else if itemName.contains("plato") { score += 0.6 }
        }
        if segNorm.contains("termo") || segNorm.contains("calentador") {
            if segNorm.contains("80") && itemName.contains("80") { score += 1.0 }
            else if segNorm.contains("100") && itemName.contains("100") { score += 1.0 }
            else if segNorm.contains("50") && itemName.contains("50") { score += 1.0 }
            else if itemName.contains("termo") { score += 0.6 }
        }
        if segNorm.contains("grif") {
            if segNorm.contains("lavabo") && itemName.contains("lavabo") { score += 1.5 }
            else if segNorm.contains("ducha") && itemName.contains("ducha") && itemName.contains("grif") { score += 1.2 }
            else if itemName.contains("grif") { score += 0.9 }
        }
        if segNorm.contains("tubo") {
            if segNorm.contains("20") && itemName.contains("20") { score += 1.5 }
            if segNorm.contains("25") && itemName.contains("25") { score += 1.5 }
        }
        if segNorm.contains("sif") && itemName.contains("sif") { score += 1.0 }
        if segNorm.contains("desatasco") && itemName.contains("desatasco") { score += 1.0 }
        if segNorm.contains("mano") && segNorm.contains("obra") && itemName.contains("mano") { score += 1.0 }
        if segNorm.contains("desplazamiento") && itemName.contains("desplazamiento") { score += 1.0 }
        if segNorm.contains("monomando") && itemName.contains("grif") && itemName.contains("ducha") { score += 1.0 }
        if segNorm.contains("mampara") && itemName.contains("mampara") { score += 1.0 }
        
        let segTokens = Set(segNorm.split(separator: " ").map(String.init).filter { !$0.isEmpty })
        let itemTokens = itemName.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        if !itemTokens.isEmpty {
            let inter = segTokens.intersection(Set(itemTokens)).count
            score += 0.8 * Double(inter) / Double(max(itemTokens.count, 1))
        }
        score += 0.4 * trigramSimilarity(segNorm, itemName)
        for a in item.aliases {
            if segNorm.contains(normalizer.normalize(a)) { score += 1.0 }
        }
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
        if chars.count < 3 { return [s] }
        var set = Set<String>()
        for i in 0..<(chars.count - 2) {
            set.insert(String(chars[i...i+2]))
        }
        return set
    }
}
