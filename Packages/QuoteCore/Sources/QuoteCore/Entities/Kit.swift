import Foundation

/// Kit: paquete de partidas ("cambio de termo").
public struct Kit: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var entries: [KitEntry]

    public init(id: UUID = UUID(), name: String, entries: [KitEntry] = []) {
        self.id = id
        self.name = name
        self.entries = entries
    }
}

/// Entrada de un kit: partida y cantidad.
public struct KitEntry: Equatable, Sendable {
    public let itemID: UUID
    public var quantity: Decimal

    public init(itemID: UUID, quantity: Decimal) {
        self.itemID = itemID
        self.quantity = quantity
    }
}
