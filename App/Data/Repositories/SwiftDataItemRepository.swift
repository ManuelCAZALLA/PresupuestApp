import Foundation
import SwiftData
import QuoteCore

/// Repositorio de partidas sobre SwiftData. Devuelve entidades de
/// dominio, jamás `@Model` (ver docs/ARCHITECTURE.md).
public struct SwiftDataItemRepository: ItemRepository {
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func all() throws -> [Item] {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<ItemRecord>())
        return records.map { $0.toDomain() }
    }

    public func item(id: UUID) throws -> Item? {
        let context = ModelContext(container)
        guard let record = try fetchRecord(id: id, in: context) else { return nil }
        return record.toDomain()
    }

    public func save(_ item: Item) throws {
        let context = ModelContext(container)
        if let existing = try fetchRecord(id: item.id, in: context) {
            existing.apply(domain: item)
        } else {
            context.insert(ItemRecord(domain: item))
        }
        try context.save()
    }

    public func delete(id: UUID) throws {
        let context = ModelContext(container)
        guard let record = try fetchRecord(id: id, in: context) else { return }
        context.delete(record)
        try context.save()
    }

    private func fetchRecord(id: UUID, in context: ModelContext) throws -> ItemRecord? {
        let descriptor = FetchDescriptor<ItemRecord>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }
}
