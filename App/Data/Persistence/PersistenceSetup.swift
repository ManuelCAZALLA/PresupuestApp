import Foundation
import SwiftData

/// Esquema actual (v3): app multisector (sin `trade`), datos profesionales
/// del presupuesto, textos por defecto del perfil y ajuste global de PDF.
/// Ver docs/ARCHITECTURE.md y la skill swiftdata-repositories.
enum PresupuestAppSchema: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)
    static let models: [any PersistentModel.Type] = [
        ItemRecord.self,
        KitRecord.self,
        KitEntryRecord.self,
        QuoteRecord.self,
        QuoteLineRecord.self,
        BusinessProfileRecord.self
    ]
}

/// Esquema v2: las partidas ganan `vatRate`. Solo existe para migrar en ligero.
enum PresupuestAppSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)
    static let models: [any PersistentModel.Type] = [
        ItemRecord.self,
        KitRecord.self,
        KitEntryRecord.self,
        QuoteRecord.self,
        QuoteLineRecord.self,
        BusinessProfileRecord.self
    ]

    @Model
    final class ItemRecord {
        @Attribute(.unique) var id: UUID
        var name: String
        var aliases: [String]
        var unitRaw: String
        var unitPrice: Decimal
        var vatRate: Decimal?
        var kindRaw: String
        var category: String?
        var tradeRaw: String

        init(
            id: UUID,
            name: String,
            aliases: [String],
            unitRaw: String,
            unitPrice: Decimal,
            vatRate: Decimal? = nil,
            kindRaw: String,
            category: String?,
            tradeRaw: String
        ) {
            self.id = id
            self.name = name
            self.aliases = aliases
            self.unitRaw = unitRaw
            self.unitPrice = unitPrice
            self.vatRate = vatRate
            self.kindRaw = kindRaw
            self.category = category
            self.tradeRaw = tradeRaw
        }
    }

    @Model
    final class BusinessProfileRecord {
        var name: String
        var taxID: String
        var phone: String
        var email: String
        var logo: Data?
        var defaultVATRate: Decimal
        var terms: String
        var validityDays: Int
        var numberPrefix: String

        init(
            name: String,
            taxID: String,
            phone: String,
            email: String,
            logo: Data?,
            defaultVATRate: Decimal,
            terms: String,
            validityDays: Int,
            numberPrefix: String
        ) {
            self.name = name
            self.taxID = taxID
            self.phone = phone
            self.email = email
            self.logo = logo
            self.defaultVATRate = defaultVATRate
            self.terms = terms
            self.validityDays = validityDays
            self.numberPrefix = numberPrefix
        }
    }

    @Model
    final class QuoteRecord {
        @Attribute(.unique) var id: UUID
        var number: String
        var date: Date
        var validityDays: Int
        var clientName: String
        var clientPhone: String
        var clientAddress: String
        var clientWorkAddress: String?
        var statusRaw: String
        var discountKindRaw: String
        var discountValue: Decimal
        var notes: String
        var defaultVATRate: Decimal
        @Relationship(deleteRule: .cascade) var lines: [QuoteLineRecord]

        init(
            id: UUID,
            number: String,
            date: Date,
            validityDays: Int,
            clientName: String,
            clientPhone: String,
            clientAddress: String,
            clientWorkAddress: String?,
            statusRaw: String,
            discountKindRaw: String,
            discountValue: Decimal,
            notes: String,
            defaultVATRate: Decimal,
            lines: [QuoteLineRecord]
        ) {
            self.id = id
            self.number = number
            self.date = date
            self.validityDays = validityDays
            self.clientName = clientName
            self.clientPhone = clientPhone
            self.clientAddress = clientAddress
            self.clientWorkAddress = clientWorkAddress
            self.statusRaw = statusRaw
            self.discountKindRaw = discountKindRaw
            self.discountValue = discountValue
            self.notes = notes
            self.defaultVATRate = defaultVATRate
            self.lines = lines
        }
    }
}

/// Esquema v1: las partidas todavía sin IVA propio. Solo existe para migrar en ligero.
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

    @Model
    final class BusinessProfileRecord {
        var name: String
        var taxID: String
        var phone: String
        var email: String
        var logo: Data?
        var defaultVATRate: Decimal
        var terms: String
        var validityDays: Int
        var numberPrefix: String

        init(
            name: String,
            taxID: String,
            phone: String,
            email: String,
            logo: Data?,
            defaultVATRate: Decimal,
            terms: String,
            validityDays: Int,
            numberPrefix: String
        ) {
            self.name = name
            self.taxID = taxID
            self.phone = phone
            self.email = email
            self.logo = logo
            self.defaultVATRate = defaultVATRate
            self.terms = terms
            self.validityDays = validityDays
            self.numberPrefix = numberPrefix
        }
    }

    @Model
    final class QuoteRecord {
        @Attribute(.unique) var id: UUID
        var number: String
        var date: Date
        var validityDays: Int
        var clientName: String
        var clientPhone: String
        var clientAddress: String
        var clientWorkAddress: String?
        var statusRaw: String
        var discountKindRaw: String
        var discountValue: Decimal
        var notes: String
        var defaultVATRate: Decimal
        @Relationship(deleteRule: .cascade) var lines: [QuoteLineRecord]

        init(
            id: UUID,
            number: String,
            date: Date,
            validityDays: Int,
            clientName: String,
            clientPhone: String,
            clientAddress: String,
            clientWorkAddress: String?,
            statusRaw: String,
            discountKindRaw: String,
            discountValue: Decimal,
            notes: String,
            defaultVATRate: Decimal,
            lines: [QuoteLineRecord]
        ) {
            self.id = id
            self.number = number
            self.date = date
            self.validityDays = validityDays
            self.clientName = clientName
            self.clientPhone = clientPhone
            self.clientAddress = clientAddress
            self.clientWorkAddress = clientWorkAddress
            self.statusRaw = statusRaw
            self.discountKindRaw = discountKindRaw
            self.discountValue = discountValue
            self.notes = notes
            self.defaultVATRate = defaultVATRate
            self.lines = lines
        }
    }
}

enum PresupuestAppMigrationPlan: SchemaMigrationPlan {
    static let schemas: [any VersionedSchema.Type] = [
        PresupuestAppSchemaV1.self,
        PresupuestAppSchemaV2.self,
        PresupuestAppSchema.self
    ]
    static let stages: [MigrationStage] = [
        .lightweight(fromVersion: PresupuestAppSchemaV1.self, toVersion: PresupuestAppSchemaV2.self),
        .lightweight(fromVersion: PresupuestAppSchemaV2.self, toVersion: PresupuestAppSchema.self)
    ]
}

enum PersistenceSetup {
    /// Contenedor persistente de la app (SQL en disco).
    static func makeModelContainer() throws -> ModelContainer {
        try makeModelContainer(configurations: ModelConfiguration())
    }

    /// Contenedor persistente en una ruta concreta.
    static func makeModelContainer(at url: URL) throws -> ModelContainer {
        try makeModelContainer(configurations: ModelConfiguration(url: url))
    }

    /// Contenedor en memoria, solo para pruebas.
    static func makeInMemoryModelContainer() throws -> ModelContainer {
        try makeModelContainer(configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    private static func makeModelContainer(configurations: ModelConfiguration) throws -> ModelContainer {
        try ModelContainer(
            for: ItemRecord.self,
            KitRecord.self,
            KitEntryRecord.self,
            QuoteRecord.self,
            QuoteLineRecord.self,
            BusinessProfileRecord.self,
            migrationPlan: PresupuestAppMigrationPlan.self,
            configurations: configurations
        )
    }
}
