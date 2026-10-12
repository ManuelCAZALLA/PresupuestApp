import Foundation

/// Puerto de carga de packs de oficio (JSON, SIN precios: el usuario los pone).
public protocol TradePackLoading {
    func load(trade: Trade) throws -> TradePackData
}

/// Contenido crudo de un pack: entradas sin precio.
public struct TradePackData: Equatable, Sendable {
    public let trade: Trade
    public let entries: [TradePackEntry]

    public init(trade: Trade, entries: [TradePackEntry]) {
        self.trade = trade
        self.entries = entries
    }
}

/// Entrada de un pack: nombre, unidad, tipo, categoría y sinónimos.
public struct TradePackEntry: Equatable, Sendable {
    public let name: String
    public let unit: MeasureUnit
    public let kind: ItemKind
    public let category: String?
    public let aliases: [String]

    public init(
        name: String,
        unit: MeasureUnit,
        kind: ItemKind,
        category: String? = nil,
        aliases: [String] = []
    ) {
        self.name = name
        self.unit = unit
        self.kind = kind
        self.category = category
        self.aliases = aliases
    }
}
