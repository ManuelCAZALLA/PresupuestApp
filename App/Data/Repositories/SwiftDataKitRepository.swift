import Foundation
import SwiftData
import QuoteCore

/// Repositorio de kits sobre SwiftData.
public struct SwiftDataKitRepository: KitRepository {
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func all() throws -> [Kit] {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<KitRecord>())
        return records.map { $0.toDomain() }
    }

    public func kit(id: UUID) throws -> Kit? {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<KitRecord>(predicate: #Predicate { $0.id == id })
        guard let record = try context.fetch(descriptor).first else { return nil }
        return record.toDomain()
    }

    public func save(_ kit: Kit) throws {
        let context = ModelContext(container)
        let id = kit.id
        let descriptor = FetchDescriptor<KitRecord>(predicate: #Predicate { $0.id == id })
        if let existing = try context.fetch(descriptor).first {
            existing.name = kit.name
            for entry in existing.entries {
                context.delete(entry)
            }
            for entry in kit.entries {
                let record = KitEntryRecord(domain: entry)
                record.kit = existing
                context.insert(record)
            }
        } else {
            context.insert(KitRecord(domain: kit))
        }
        try context.save()
    }

    public func delete(id: UUID) throws {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<KitRecord>(predicate: #Predicate { $0.id == id })
        guard let record = try context.fetch(descriptor).first else { return }
        context.delete(record)
        try context.save()
    }
}
