import Foundation
import QuoteCore
import SwiftData
import Testing
@testable import PresupuestApp

/// La app ya se ha usado con el esquema v1 (M4) en dispositivos reales: abrir
/// ese almacén con el esquema v2 no puede perder partidas. Ver D-011 y la skill
/// swiftdata-repositories.
@Suite("Migración de esquema v1 a v2")
@MainActor
struct SchemaMigrationTests {
    @Test("Un almacén v1 se abre con el esquema actual sin perder partidas")
    func migratesV1StoreToV2() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("migracion-\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: url) }

        try makeV1Store(at: url)

        let container = try PersistenceSetup.makeModelContainer(at: url)
        let repository = SwiftDataItemRepository(container: container)
        let item = try #require(try repository.item(named: "Urinario"))

        #expect(item.unitPrice == Decimal(100))
        #expect(item.unit == .unit)
        // Las partidas importadas antes de M4b no tienen tipo propio: heredan.
        #expect(item.vatRate == nil)
    }

    /// Crea un almacén tal como lo dejaba la app en v1 (sin `vatRate`).
    private func makeV1Store(at url: URL) throws {
        let schema = Schema(versionedSchema: PresupuestAppSchemaV1.self)
        let container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, url: url)]
        )
        let context = ModelContext(container)
        context.insert(
            PresupuestAppSchemaV1.ItemRecord(
                id: UUID(),
                name: "Urinario",
                aliases: [],
                unitRaw: MeasureUnit.unit.rawValue,
                unitPrice: Decimal(100),
                kindRaw: ItemKind.other.rawValue,
                category: nil,
                tradeRaw: "other"
            )
        )
        try context.save()
    }
}
