import Foundation

public final class Normalizer {
    public init() {}
    public func normalize(_ text: String) -> String {
        var s = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es_ES"))
        s = s.lowercased()
        s = s.replacingOccurrences(of: "m²", with: "m2")
        s = s.replacingOccurrences(of: "m³", with: "m3")
        s = s.replacingOccurrences(of: ",", with: ".")
        s = s.replacingOccurrences(of: "[^a-z0-9\\. ]", with: " ", options: .regularExpression)
        s = s.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
