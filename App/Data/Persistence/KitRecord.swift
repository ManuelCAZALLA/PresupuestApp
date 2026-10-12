import Foundation
import SwiftData
import QuoteCore

/// Registro de kit y sus entradas (partida + cantidad).
@Model
final class KitRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    @Relationship(deleteRule: .cascade) var entries: [KitEntryRecord]

    init(id: UUID, name: String, entries: [KitEntryRecord]) {
        self.id = id
        self.name = name
        self.entries = entries
    }

    func toDomain() -> Kit {
        Kit(
            id: id,
            name: name,
            entries: entries.map { KitEntry(itemID: $0.itemID, quantity: $0.quantity) }
        )
    }
}

extension KitRecord {
    convenience init(domain: Kit) {
        self.init(
            id: domain.id,
            name: domain.name,
            entries: domain.entries.map { KitEntryRecord(domain: $0) }
        )
    }
}

@Model
final class KitEntryRecord {
    @Attribute(.unique) var id: UUID
    var itemID: UUID
    var quantity: Decimal
    @Relationship var kit: KitRecord?

    init(id: UUID, itemID: UUID, quantity: Decimal, kit: KitRecord? = nil) {
        self.id = id
        self.itemID = itemID
        self.quantity = quantity
        self.kit = kit
    }

    func toDomain() -> KitEntry {
        KitEntry(itemID: itemID, quantity: quantity)
    }
}

extension KitEntryRecord {
    convenience init(domain: KitEntry) {
        self.init(
            id: UUID(),
            itemID: domain.itemID,
            quantity: domain.quantity
        )
    }
}
