import Foundation
import SwiftData

/// Esquema actual (v2): las partidas ganan `vatRate` (M4b, D-011).
/// Ver docs/ARCHITECTURE.md y la skill swiftdata-repositories.
enum PresupuestAppSchema: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)
    static let models: [any PersistentModel.Type] = [
        ItemRecord.self,
        KitRecord.self,
        KitEntryRecord.self,
        QuoteRecord.self,
        QuoteLineRecord.self,
        BusinessProfileRecord.self
    ]
}

/// Esquema v1: las partidas todavía sin IVA propio. Solo existe para migrar en
/// ligero los datos de las versiones previas; no se usa en el código nuevo.
enum PresupuestAppSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static let models: [any PersistentModel.Type] = [
        ItemRecord.self,
        KitRecord.self,
        KitEntryRecord.self,
        QuoteRecord.self,
        QuoteLineRecord.self,
        BusinessProfileRecord.self
    ]

    /// La partida tal como se guardaba en v1. El nombre de entidad es el mismo
    /// (`ItemRecord`) para que la migración altere la tabla en el sitio.
    @Model
    final class ItemRecord {
        @Attribute(.unique) var id: UUID
        var name: String
        var aliases: [String]
        var unitRaw: String
        var unitPrice: Decimal
        var kindRaw: String
        var category: String?
        var tradeRaw: String

        init(
            id: UUID,
            name: String,
            aliases: [String],
            unitRaw: String,
            unitPrice: Decimal,
            kindRaw: String,
            category: String?,
            tradeRaw: String
        ) {
            self.id = id
            self.name = name
            self.aliases = aliases
            self.unitRaw = unitRaw
            self.unitPrice = unitPrice
            self.kindRaw = kindRaw
            self.category = category
            self.tradeRaw = tradeRaw
        }
    }
}

enum PresupuestAppMigrationPlan: SchemaMigrationPlan {
    static let schemas: [any VersionedSchema.Type] = [
        PresupuestAppSchemaV1.self,
        PresupuestAppSchema.self
    ]
    static let stages: [MigrationStage] = [
        // Añade `ItemRecord.vatRate` (opcional): migración en ligero.
        .lightweight(fromVersion: PresupuestAppSchemaV1.self, toVersion: PresupuestAppSchema.self)
    ]
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
