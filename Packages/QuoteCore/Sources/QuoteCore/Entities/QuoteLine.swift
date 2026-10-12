import Foundation

/// Línea de un presupuesto. Guarda COPIA del nombre, unidad y precio del momento:
/// cambiar el catálogo no altera presupuestos ya hechos (ver docs/DOMAIN.md).
public struct QuoteLine: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var itemID: UUID?
    public var name: String
    public var unit: MeasureUnit
    public var quantity: Decimal
    public var unitPrice: Decimal
    public var vatRate: Decimal
    public var origin: Origin

    public enum Origin: String, Codable, Sendable {
        case parser
        case manual
        case kit
    }

    public init(
        id: UUID = UUID(),
        itemID: UUID? = nil,
        name: String,
        unit: MeasureUnit,
        quantity: Decimal,
        unitPrice: Decimal,
        vatRate: Decimal,
        origin: Origin
    ) {
        self.id = id
        self.itemID = itemID
        self.name = name
        self.unit = unit
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.vatRate = vatRate
        self.origin = origin
    }
}
