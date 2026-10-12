import Foundation
import SwiftData
import QuoteCore

/// Repositorio de alias: los alias viven en la partida (`ItemRecord.aliases`).
public struct SwiftDataAliasRepository: AliasRepository {
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func aliases(forItem itemID: UUID) throws -> [String] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<ItemRecord>(predicate: #Predicate { $0.id == itemID })
        return try context.fetch(descriptor).first?.aliases ?? []
    }

    public func add(alias: String, toItem itemID: UUID) throws {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<ItemRecord>(predicate: #Predicate { $0.id == itemID })
        guard let record = try context.fetch(descriptor).first else { return }
        record.aliases.append(alias)
        try context.save()
    }
}
