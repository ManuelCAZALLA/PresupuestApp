import Foundation
import SwiftData
import QuoteCore

/// Repositorio del perfil de empresa sobre SwiftData (configuración única).
public struct SwiftDataProfileRepository: ProfileRepository {
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func load() throws -> BusinessProfile? {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<BusinessProfileRecord>())
        return records.first?.toDomain()
    }

    public func save(_ profile: BusinessProfile) throws {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<BusinessProfileRecord>())
        if let existing = records.first {
            existing.apply(domain: profile)
        } else {
            context.insert(BusinessProfileRecord(domain: profile))
        }
        try context.save()
    }
}
