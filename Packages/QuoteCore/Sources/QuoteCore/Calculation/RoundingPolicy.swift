import Foundation

/// Regla única de redondeo del dominio (ver docs/DOMAIN.md):
/// todo con `Decimal`; redondeo a 2 decimales con `.plain` (mitad hacia
/// arriba), SOLO en total de línea, descuento, base por tipo de IVA y cuota.
public enum RoundingPolicy {
    public static func round2(_ value: Decimal) -> Decimal {
        var value = value
        var result = Decimal()
        NSDecimalRound(&result, &value, 2, .plain)
        return result
    }

    /// Redondeo a 4 decimales: precio neto desde precio con IVA.
    public static func round4(_ value: Decimal) -> Decimal {
        var value = value
        var result = Decimal()
        NSDecimalRound(&result, &value, 4, .plain)
        return result
    }

    /// `netPrice = round4(priceWithVAT / (1 + rate))`.
    public static func netPrice(fromGross gross: Decimal, vatRate: Decimal) -> Decimal {
        round4(gross / (Decimal(1) + vatRate / Decimal(100)))
    }
}
