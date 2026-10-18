import Foundation
import SwiftData
import QuoteCore

/// Registro de partida. `unitPrice` es `Decimal`: nunca `Double`.
/// `vatRate` es el tipo de IVA propio de la partida (M4b, D-011); `nil` = usar
/// el del presupuesto. El esquema v2 migra en ligero los datos de v1.
@Model
final class ItemRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var aliases: [String]
    var unitRaw: String
    var unitPrice: Decimal
    var vatRate: Decimal?
    var kindRaw: String
    var category: String?
    var tradeRaw: String

    init(
        id: UUID,
        name: String,
        aliases: [String],
        unitRaw: String,
        unitPrice: Decimal,
        vatRate: Decimal? = nil,
        kindRaw: String,
        category: String?,
        tradeRaw: String
    ) {
        self.id = id
        self.name = name
        self.aliases = aliases
        self.unitRaw = unitRaw
        self.unitPrice = unitPrice
        self.vatRate = vatRate
        self.kindRaw = kindRaw
        self.category = category
        self.tradeRaw = tradeRaw
    }

    func toDomain() -> Item {
        Item(
            id: id,
            name: name,
            aliases: aliases,
            unit: MeasureUnit(rawValue: unitRaw) ?? .unit,
            unitPrice: unitPrice,
            vatRate: vatRate,
            kind: ItemKind(rawValue: kindRaw) ?? .other,
            category: category,
            trade: Trade(rawValue: tradeRaw) ?? .other
        )
    }

    func apply(domain: Item) {
        name = domain.name
        aliases = domain.aliases
        unitRaw = domain.unit.rawValue
        unitPrice = domain.unitPrice
        vatRate = domain.vatRate
        kindRaw = domain.kind.rawValue
        category = domain.category
        tradeRaw = domain.trade.rawValue
    }
}

extension ItemRecord {
    convenience init(domain: Item) {
        self.init(
            id: domain.id,
            name: domain.name,
            aliases: domain.aliases,
            unitRaw: domain.unit.rawValue,
            unitPrice: domain.unitPrice,
            vatRate: domain.vatRate,
            kindRaw: domain.kind.rawValue,
            category: domain.category,
            tradeRaw: domain.trade.rawValue
        )
    }
}
