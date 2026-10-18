import Foundation

/// Partida del catálogo del usuario. Los precios los pone siempre el usuario.
public struct Item: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var aliases: [String]
    public var unit: MeasureUnit
    public var unitPrice: Decimal
    public var kind: ItemKind
    public var category: String?
    public var trade: Trade

    public init(
        id: UUID = UUID(),
        name: String,
        aliases: [String] = [],
        unit: MeasureUnit = .unit,
        unitPrice: Decimal = Decimal(0),
        kind: ItemKind = .other,
        category: String? = nil,
        trade: Trade = .other
    ) {
        self.id = id
        self.name = name
        self.aliases = aliases
        self.unit = unit
        self.unitPrice = unitPrice
        self.kind = kind
        self.category = category
        self.trade = trade
    }
}

public extension Item {
    /// Clave de emparejamiento por nombre: minúsculas, sin tildes y con los
    /// espacios colapsados. Es la que usa el catálogo para no duplicar
    /// partidas al importar la tarifa del usuario (ver DECISIONS.md, D-007).
    static func nameKey(_ name: String) -> String {
        name
            .folding(
                options: [.diacriticInsensitive, .caseInsensitive],
                locale: Locale(identifier: "es_ES")
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()
    }

    /// Clave de emparejamiento de esta partida (ver `nameKey(_:)`).
    var nameKey: String { Item.nameKey(name) }
}
