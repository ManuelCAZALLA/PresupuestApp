import Foundation

/// Desglose por tipo de IVA: base y cuota, ya redondeadas.
public struct VATGroup: Equatable, Sendable {
    public let rate: Decimal
    public let base: Decimal
    public let vat: Decimal

    public init(rate: Decimal, base: Decimal, vat: Decimal) {
        self.rate = rate
        self.base = base
        self.vat = vat
    }
}

/// Resultado del cálculo de un presupuesto.
public struct QuoteTotals: Equatable, Sendable {
    public let subtotal: Decimal
    public let discount: Decimal
    public let vatBreakdown: [VATGroup]
    public let total: Decimal

    public init(
        subtotal: Decimal,
        discount: Decimal,
        vatBreakdown: [VATGroup],
        total: Decimal
    ) {
        self.subtotal = subtotal
        self.discount = discount
        self.vatBreakdown = vatBreakdown
        self.total = total
    }
}
