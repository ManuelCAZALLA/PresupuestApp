import Foundation

/// Descuento de un presupuesto: ninguno, porcentaje o importe fijo.
public enum Discount: Equatable, Sendable {
    case none
    case percent(Decimal)
    case amount(Decimal)
}
