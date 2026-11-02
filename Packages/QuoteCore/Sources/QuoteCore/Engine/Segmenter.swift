import Foundation

public final class Segmenter {
    public init() {}
    
    public func segments(from text: String) -> [String] {
        var s = text
        s = s.replacingOccurrences(of: "+", with: ",")
        s = s.replacingOccurrences(of: ";", with: ",")
        s = s.replacingOccurrences(of: "\n", with: ",")
        s = s.replacingOccurrences(of: "más el", with: ", el")
        s = s.replacingOccurrences(of: "mas el", with: ", el")
        s = s.replacingOccurrences(of: "más", with: ",")
        s = s.replacingOccurrences(of: "mas", with: ",")
        let parts = s.split(separator: ",", omittingEmptySubsequences: true)
        var result: [String] = []
        for part in parts {
            let p = String(part)
            // split on " y " but need to be careful about cases like "plato de ducha y mampara"
            if p.contains(" y ") {
                let subparts = p.split(separator: " y ", omittingEmptySubsequences: true)
                for sp in subparts {
                    result.append(String(sp).trimmingCharacters(in: .whitespacesAndNewlines))
                }
            } else {
                result.append(p.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        if result.isEmpty {
            return [text]
        }
        return result
    }
}
