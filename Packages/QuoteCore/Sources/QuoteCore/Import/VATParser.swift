import Foundation

/// Interpreta el tipo de IVA de una celda de importación. Acepta `21`, `21%`,
/// `0,21` y `10`; se guarda siempre como porcentaje (0,21 → 21). Ver
/// docs/DECISIONS.md, D-012.
public enum VATParser {
    /// El tipo en por ciento, o `nil` si la celda está vacía o es ilegible.
    public static func parse(_ raw: String) -> Decimal? {
        var text = raw.replacingOccurrences(of: "%", with: "")
        text = text.trimmingCharacters(in: .whitespaces)
        text = text.replacingOccurrences(of: ",", with: ".")
        guard !text.isEmpty, let value = Decimal(string: text), value >= 0 else { return nil }

        // Un valor entre 0 y 1 exclusivo está escrito como fracción: 0,21 → 21.
        let percent = value > 0 && value < 1 ? value * 100 : value
        guard percent <= 100 else { return nil }
        return RoundingPolicy.round2(percent)
    }
}
