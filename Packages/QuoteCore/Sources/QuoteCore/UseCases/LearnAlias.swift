import Foundation

/// Aprende un alias para una partida. Reglas: único por partida,
/// máximo 20 por partida, nunca duplica el nombre ni otro alias existente.
public final class LearnAlias {
    private let items: ItemRepository
    
    public init(items: ItemRepository) {
        self.items = items
    }
    
    public func execute(phrase: String, for itemID: UUID) throws {
        let normalized = normalize(phrase)
        guard let item = try items.all().first(where: { $0.id == itemID }) else { return }
        if normalize(item.name) == normalized { return }
        if item.aliases.contains(where: { normalize($0) == normalized }) { return }
        if item.aliases.count >= 20 { return }
        var updated = item
        updated.aliases.append(phrase.trimmingCharacters(in: .whitespacesAndNewlines))
        try items.save(updated)
    }
    
    private func normalize(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es_ES"))
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9 ]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
