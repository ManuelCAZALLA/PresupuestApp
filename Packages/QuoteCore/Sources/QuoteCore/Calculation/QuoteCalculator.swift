import Foundation

/// Cálculo de un presupuesto (ver docs/DOMAIN.md, "Cálculo de un presupuesto").
///
/// Orden: `lineTotal` → `subtotal` → descuento → reparto del descuento por
/// tipo de IVA → IVA por grupo → `total`. El reparto ordena los grupos por
/// tipo de IVA ascendente: cada grupo recibe `round2(descuento × base / subtotal)`
/// y el último (el de mayor tipo) absorbe el resto para que la suma sea exacta.
public final class QuoteCalculator {
    public init() {}

    /// `lineTotal = round2(quantity × unitPrice)`.
    public func lineTotal(_ line: QuoteLine) -> Decimal {
        RoundingPolicy.round2(line.quantity * line.unitPrice)
    }

    public func calculate(lines: [QuoteLine], discount: Discount) -> QuoteTotals {
        let lineTotals = lines.map(lineTotal)
        let subtotal = lineTotals.reduce(Decimal(0), +)
        let discountAmount = discountAmount(for: discount, subtotal: subtotal)

        // Agrupar los totales de línea por tipo de IVA.
        var basesByRate: [Decimal: Decimal] = [:]
        for (line, total) in zip(lines, lineTotals) {
            basesByRate[line.vatRate, default: Decimal(0)] += total
        }
        let rates = basesByRate.keys.sorted()

        // Repartir el descuento en orden ascendente de tipo de IVA.
        var sharesByRate: [Decimal: Decimal] = [:]
        var remaining = discountAmount
        for (index, rate) in rates.enumerated() {
            let grossBase = basesByRate[rate] ?? Decimal(0)
            if index == rates.count - 1 {
                sharesByRate[rate] = remaining
            } else if subtotal > 0 {
                let share = RoundingPolicy.round2(discountAmount * grossBase / subtotal)
                sharesByRate[rate] = share
                remaining -= share
            } else {
                sharesByRate[rate] = Decimal(0)
            }
        }

        var breakdown: [VATGroup] = []
        for rate in rates {
            let grossBase = basesByRate[rate] ?? Decimal(0)
            let share = sharesByRate[rate] ?? Decimal(0)
            let base = grossBase - share
            let vat = RoundingPolicy.round2(base * rate / Decimal(100))
            breakdown.append(VATGroup(rate: rate, base: base, vat: vat))
        }
        let total = breakdown.reduce(Decimal(0)) { $0 + $1.base + $1.vat }

        return QuoteTotals(
            subtotal: subtotal,
            discount: discountAmount,
            vatBreakdown: breakdown,
            total: total
        )
    }

    private func discountAmount(for discount: Discount, subtotal: Decimal) -> Decimal {
        switch discount {
        case .none:
            return Decimal(0)
        case .percent(let p):
            return RoundingPolicy.round2(subtotal * p / Decimal(100))
        case .amount(let a):
            return min(a, subtotal)
        }
    }
}
