import Foundation
import SwiftData

/// Esquema versionado desde la primera versión publicada
/// (ver docs/ARCHITECTURE.md y la skill swiftdata-repositories).
enum PresupuestAppSchema: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static let models: [any PersistentModel.Type] = [
        ItemRecord.self,
        KitRecord.self,
        KitEntryRecord.self,
        QuoteRecord.self,
        QuoteLineRecord.self,
        BusinessProfileRecord.self
    ]
}

enum PresupuestAppMigrationPlan: SchemaMigrationPlan {
    static let schemas: [any VersionedSchema.Type] = [PresupuestAppSchema.self]
    static let stages: [MigrationStage] = []
}

enum PersistenceSetup {
    /// Contenedor persistente de la app (SQL en disco).
    static func makeModelContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ItemRecord.self,
            KitRecord.self,
            KitEntryRecord.self,
            QuoteRecord.self,
            QuoteLineRecord.self,
            BusinessProfileRecord.self,
            migrationPlan: PresupuestAppMigrationPlan.self
        )
    }

    /// Contenedor en memoria, solo para pruebas.
    static func makeInMemoryModelContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ItemRecord.self,
            KitRecord.self,
            KitEntryRecord.self,
            QuoteRecord.self,
            QuoteLineRecord.self,
            BusinessProfileRecord.self,
            migrationPlan: PresupuestAppMigrationPlan.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}
