import Foundation

/// Interpreta el texto de un precio. Acepta `25`, `25,5`, `25.50`, `1.234,50`,
/// `25 €`, `25€/ud`. Ver docs/DECISIONS.md, D-008.
public enum PriceParser {
    public enum Outcome: Equatable, Sendable {
        /// Precio interpretado. `hasCurrencySymbol` indica si el texto traía
        /// símbolo de moneda (para el aviso suave en texto pegado).
        case value(Decimal, hasCurrencySymbol: Bool)
        /// Precio ambiguo (un único punto con 3 decimales, p. ej. `1.234`).
        /// Se interpreta como miles y se pide confirmación en la revisión.
        case ambiguous(Decimal, raw: String)
        /// No se pudo interpretar como número.
        case invalid(raw: String)
    }

    public static func hasCurrencySymbol(_ raw: String) -> Bool {
        let folded = raw.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: Locale(identifier: "es_ES")
        ).lowercased()
        return folded.contains("€") || folded.contains("eur")
    }

    public static func parse(_ raw: String) -> Outcome {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let symbol = hasCurrencySymbol(trimmed)
        // Un signo menos no es un precio de tarifa válido.
        if trimmed.contains("-") {
            return .invalid(raw: raw)
        }
        let numeric = String(trimmed.filter { $0.isASCII && $0.isNumber || $0 == "." || $0 == "," })
        guard numeric.contains(where: { $0.isASCII && $0.isNumber }) else {
            return .invalid(raw: raw)
        }

        let dots = numeric.filter { $0 == "." }.count
        let commas = numeric.filter { $0 == "," }.count

        if dots > 0 && commas > 0 {
            // El último separador es el decimal; el otro son miles.
            let lastDot = numeric.lastIndex(of: ".")!
            let lastComma = numeric.lastIndex(of: ",")!
            var cleaned = numeric
            if lastDot > lastComma {
                cleaned = cleaned.replacingOccurrences(of: ",", with: "")
            } else {
                cleaned = cleaned.replacingOccurrences(of: ".", with: "")
                cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
            }
            guard let value = Decimal(string: cleaned) else { return .invalid(raw: raw) }
            return .value(value, hasCurrencySymbol: symbol)
        }

        if commas > 0 {
            // En español la coma es decimal. Varias comas: miles.
            let cleaned = commas == 1
                ? numeric.replacingOccurrences(of: ",", with: ".")
                : numeric.replacingOccurrences(of: ",", with: "")
            guard let value = Decimal(string: cleaned) else { return .invalid(raw: raw) }
            return .value(value, hasCurrencySymbol: symbol)
        }

        if dots > 1 {
            let cleaned = numeric.replacingOccurrences(of: ".", with: "")
            guard let value = Decimal(string: cleaned) else { return .invalid(raw: raw) }
            return .value(value, hasCurrencySymbol: symbol)
        }

        if dots == 1 {
            let parts = numeric.split(separator: ".", omittingEmptySubsequences: false)
            let integerPart = parts.first.map(String.init) ?? ""
            let decimals = parts.last.map(String.init) ?? ""
            // `1.234` puede ser 1234 (miles) o 1,234: ambiguo.
            if decimals.count == 3 && integerPart.count <= 3 {
                let cleaned = numeric.replacingOccurrences(of: ".", with: "")
                let value = Decimal(string: cleaned) ?? Decimal(0)
                return .ambiguous(value, raw: raw)
            }
            guard let value = Decimal(string: numeric) else { return .invalid(raw: raw) }
            return .value(value, hasCurrencySymbol: symbol)
        }

        guard let value = Decimal(string: numeric) else { return .invalid(raw: raw) }
        return .value(value, hasCurrencySymbol: symbol)
    }
}
