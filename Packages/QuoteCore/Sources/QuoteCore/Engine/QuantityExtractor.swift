import Foundation

public final class QuantityExtractor {
    private let normalizer = Normalizer()
    private let numberWords = NumberWords()
    
    public init() {}
    
    public struct Result {
        public let quantity: Decimal
        public let quantityWasAssumed: Bool
        public let spokenUnit: MeasureUnit?
        public let remainingText: String
    }
    
    private func stripLeadingArticles(_ tokens: inout [String]) {
        while !tokens.isEmpty {
            let t = tokens[0]
            // Don't strip 'un'/'una' as they are number words meaning 1 in many cases
            // Only strip definite articles that aren't quantities
            if t == "el" || t == "la" || t == "los" || t == "las" || t == "del" || t == "al" {
                tokens.removeFirst()
                continue
            }
            break
        }
    }
    
    private func isStrictNumber(_ s: String) -> Bool {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return false }
        // allow digits, optional sign, dot, comma already normalized to dot
        let allowed = CharacterSet(charactersIn: "0123456789.-")
        if trimmed.unicodeScalars.contains(where: { !allowed.contains($0) }) { return false }
        if trimmed.filter({ $0 == "." }).count > 1 { return false }
        if trimmed.filter({ $0 == "-" }).count > 1 { return false }
        if trimmed.hasPrefix("-") && trimmed.count == 1 { return false }
        return true
    }
    
    public func extract(from segment: String) -> Result {
        var tokens = normalizer.normalize(segment).split(separator: " ").map(String.init)
        stripLeadingArticles(&tokens)
        var qty: Decimal? = nil
        var qtyWasAssumed = false
        var spokenUnit: MeasureUnit? = nil
        
        if tokens.count >= 3 && tokens[0] == "un" && tokens[1] == "par" && tokens[2] == "de" {
            qty = Decimal(2); tokens.removeFirst(3)
        } else if tokens.count >= 3 && tokens[0] == "media" && tokens[1] == "docena" && tokens[2] == "de" {
            qty = Decimal(6); tokens.removeFirst(3)
        } else if tokens.count >= 2 && tokens[0] == "una" && tokens[1] == "docena" {
            qty = Decimal(12); tokens.removeFirst(2); if !tokens.isEmpty && tokens[0] == "de" { tokens.removeFirst() }
        } else if !tokens.isEmpty && tokens[0] == "docena" {
            qty = Decimal(12); tokens.removeFirst(); if !tokens.isEmpty && tokens[0] == "de" { tokens.removeFirst() }
        }
        
        if qty == nil && tokens.count >= 4 && tokens[1] == "coma" {
            if let base = numberWords.toNumber(tokens[0]), let frac = numberWords.toNumber(tokens[2]) {
                qty = base + frac / Decimal(10); tokens.removeFirst(4)
            }
        } else if qty == nil && tokens.count >= 3 && tokens[1] == "y" && tokens[2] == "medio" {
            if let base = numberWords.toNumber(tokens[0]) {
                qty = base + Decimal(string: "0.5")!; tokens.removeFirst(3)
            }
        }
        
        if qty == nil && !tokens.isEmpty {
            let first = tokens[0]
            if isStrictNumber(first), let d = Decimal(string: first), d > 0 {
                qty = d; tokens.removeFirst()
            } else if let w = numberWords.toNumber(first), w > 0 {
                qty = w; tokens.removeFirst()
            }
        } else if qty != nil && !tokens.isEmpty && (tokens[0] == "centimetros" || tokens[0] == "centimetro") {
            tokens.removeFirst()
            if !tokens.isEmpty && tokens[0] == "de" { tokens.removeFirst() }
        }
        
        if !tokens.isEmpty {
            if tokens[0] == "m3" {
                spokenUnit = .cubicMeter; tokens.removeFirst()
                if !tokens.isEmpty && tokens[0] == "de" { tokens.removeFirst() }
            } else if tokens.count >= 2 && tokens[0] == "metros" && (tokens[1] == "cubicos" || tokens[1] == "cubico") {
                spokenUnit = .cubicMeter; tokens.removeFirst(2)
                if !tokens.isEmpty && tokens[0] == "de" { tokens.removeFirst() }
            } else if tokens.count >= 2 && tokens[0] == "metros" && (tokens[1] == "cuadrados" || tokens[1] == "cuadrado") {
                spokenUnit = .squareMeter; tokens.removeFirst(2)
                if !tokens.isEmpty && tokens[0] == "de" { tokens.removeFirst() }
            } else if tokens[0] == "metros" || tokens[0] == "metro" {
                spokenUnit = .meter; tokens.removeFirst()
                if !tokens.isEmpty && tokens[0] == "de" { tokens.removeFirst() }
            } else if tokens[0] == "centimetros" || tokens[0] == "centimetro" {
                // ignore unit for matching
                tokens.removeFirst()
                if !tokens.isEmpty && tokens[0] == "de" { tokens.removeFirst() }
            } else if tokens[0] == "horas" || tokens[0] == "hora" {
                spokenUnit = .hour; tokens.removeFirst()
                if !tokens.isEmpty && tokens[0] == "de" { tokens.removeFirst() }
            }
        }
        
        if qty == nil {
            var newTokens: [String] = []
            for t in tokens {
                if qty == nil {
                    // Avoid taking spec numbers as quantities
                    if t == "50" || t == "60" || t == "80" || t == "90" || t == "100" || t == "120" || t == "20" || t == "25" {
                        newTokens.append(t)
                        continue
                    }
                    if isStrictNumber(t), let d = Decimal(string: t), d > 0 { qty = d; qtyWasAssumed = false; continue }
                    if let w = numberWords.toNumber(t), w > 0 { qty = w; qtyWasAssumed = false; continue }
                }
                newTokens.append(t)
            }
            tokens = newTokens
        }
        if spokenUnit == nil {
            for (i, t) in tokens.enumerated() {
                if t == "horas" || t == "hora" { spokenUnit = .hour; tokens.remove(at: i); break }
                if t == "m3" { spokenUnit = .cubicMeter; tokens.remove(at: i); break }
                if t == "m2" { spokenUnit = .squareMeter; tokens.remove(at: i); break }
                if t == "metros" && i+1 < tokens.count {
                    if tokens[i+1] == "cuadrados" || tokens[i+1] == "cuadrado" { spokenUnit = .squareMeter; tokens.remove(at: i+1); tokens.remove(at: i); break }
                    if tokens[i+1] == "cubicos" || tokens[i+1] == "cubico" { spokenUnit = .cubicMeter; tokens.remove(at: i+1); tokens.remove(at: i); break }
                }
            }
        }
        if qty == nil && !tokens.isEmpty {
            if isStrictNumber(tokens[0]), let d = Decimal(string: tokens[0]), d > 0 { qty = d; qtyWasAssumed = false; tokens.removeFirst() }
            else if let w = numberWords.toNumber(tokens[0]), w > 0 { qty = w; qtyWasAssumed = false; tokens.removeFirst() }
        }
        
        if qty == nil {
            qty = Decimal(1); qtyWasAssumed = true
        }
        return Result(quantity: qty!, quantityWasAssumed: qtyWasAssumed, spokenUnit: spokenUnit, remainingText: tokens.joined(separator: " "))
    }
}
