import Foundation

/// Formateo de moneda (es-ES, 2 decimales). Solo en Presentation:
/// el dominio nunca formatea (ver docs/DOMAIN.md).
enum CurrencyFormatter {
    private static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "es_ES")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private static let plain: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "es_ES")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    /// `121,00 €` para mostrar.
    static func string(from amount: Decimal) -> String {
        currency.string(from: amount as NSNumber) ?? "\(amount)"
    }

    /// `121,00` para editar (sin símbolo, coma decimal).
    static func plainString(from amount: Decimal) -> String {
        plain.string(from: amount as NSNumber) ?? "\(amount)"
    }
}
