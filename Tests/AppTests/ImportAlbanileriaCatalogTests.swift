import Foundation
import QuoteCore
import SwiftData
import Testing
@testable import PresupuestApp

/// Catálogo de albañilería con tabla Excel, celdas `inlineStr` y tres hojas.
/// Reproduce un `.xlsx` real que CoreXLSX 0.14.2 no abría.
private let samplesDirectory = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .appendingPathComponent("ImportSamples", isDirectory: true)

private func sample(_ name: String) -> URL {
    samplesDirectory.appendingPathComponent(name)
}

private func decimal(_ string: String) -> Decimal {
    Decimal(string: string)!
}

@Suite("Importación: catálogo de albañilería con tabla Excel")
struct ImportAlbanileriaCatalogTests {
    @Test("Lee 49 partidas, columnas Concepto/Unidad/Precio/IVA y la hoja Tarifas")
    func spreadsheetWithExcelTable() throws {
        let sheets = try XLSXReader.read(url: sample("tarifa_albanileria_tabla.xlsx"))
        #expect(sheets.map(\.name) == ["Tarifas", "Empresa ejemplo", "Notas"] as [String?])

        let rows = try #require(sheets.first { $0.name == "Tarifas" }).rows
        #expect(ColumnMapper.detectHeaderRow(in: rows) == 3)

        let suggestion = ColumnMapper.suggestHeader(in: rows)
        #expect(suggestion.name == 2)
        #expect(suggestion.category == 1)
        #expect(suggestion.unit == 3)
        #expect(suggestion.price == 4)
        #expect(suggestion.vatRate == 5)

        let result = ColumnMapper.map(
            rows,
            headerRow: suggestion.headerRow,
            mapping: ColumnMapping(
                name: suggestion.name ?? 2,
                price: suggestion.price,
                unit: suggestion.unit,
                category: suggestion.category,
                vatRate: suggestion.vatRate
            ),
            options: ImportOptions(vatIncluded: false, vatRate: 21)
        )

        #expect(result.rows.count == 49)
        #expect(result.rows.first?.name == "Oficial de primera albañil")
        #expect(result.rows.first?.unit == .hour)
        #expect(result.rows.first?.netPrice == decimal("24.5"))
        #expect(result.rows.first?.vatRate == decimal("21"))
        #expect(result.rows.first?.category == "Albañilería")
        #expect(result.rows.last?.name == "Saco de escombro y retirada")
        #expect(result.rows.last?.netPrice == decimal("16"))
    }
}

@Suite("Importación: vista modelo con catálogo de albañilería")
@MainActor
struct ImportAlbanileriaCatalogViewModelTests {
    @Test("El archivo llega a la revisión con las partidas detectadas")
    func viewModelReadsExcelTable() throws {
        let container = try ModelContainer(
            for: ItemRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let viewModel = ImportTariffViewModel(
            source: LocalTariffSource(),
            template: FileTariffTemplateProvider(),
            importTariff: ImportTariff(items: SwiftDataItemRepository(container: container))
        )

        viewModel.loadFile(at: sample("tarifa_albanileria_tabla.xlsx"))
        #expect(viewModel.state == .ready)
        #expect(viewModel.step == .mapping)
        #expect(viewModel.tables.map(\.name) == ["Tarifas", "Empresa ejemplo", "Notas"] as [String?])

        viewModel.continueToReview()
        #expect(viewModel.rows.count == 49)
        #expect(viewModel.rows.first?.name == "Oficial de primera albañil")
    }

    @Test("Abrir con un .xlsm entra en el mapeo, no en la lista pegada")
    func openExternalMacroEnabledWorkbook() throws {
        let data = try Data(contentsOf: sample("tarifa_albanileria_tabla.xlsx"))
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString)-tarifa.xlsm")
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let container = try ModelContainer(
            for: ItemRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let viewModel = ImportTariffViewModel(
            source: LocalTariffSource(),
            template: FileTariffTemplateProvider(),
            importTariff: ImportTariff(items: SwiftDataItemRepository(container: container))
        )

        viewModel.openExternalFile(at: url)
        #expect(viewModel.state == .ready)
        #expect(viewModel.step == .mapping)
        #expect(viewModel.tables.first?.name == "Tarifas")
    }
}
