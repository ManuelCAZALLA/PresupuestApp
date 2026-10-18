import Foundation
import QuoteCore
import SwiftData
import Testing
@testable import PresupuestApp

/// `tarifa_con_iva.xlsx` con su `expected_imports_iva.json` es el oráculo de la
/// columna IVA opcional por fila (M4b, D-012). Los archivos de M4 no se tocan.
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

@Suite("Importación: columna IVA por fila")
struct ImportVATColumnTests {
    @Test("tarifa_con_iva.xlsx: cabecera con IVA, 7 partidas y tipos por fila")
    func spreadsheetWithVATColumn() throws {
        let sheets = try XLSXReader.read(url: sample("tarifa_con_iva.xlsx"))
        #expect(sheets.map(\.name) == ["Tarifa"])
        let rows = sheets[0].rows

        #expect(ColumnMapper.detectHeaderRow(in: rows) == 3)
        #expect(ColumnMapper.suggestedVATIncluded(in: rows))

        let suggestion = ColumnMapper.suggestHeader(in: rows)
        #expect(suggestion.name == 0)
        #expect(suggestion.unit == 1)
        #expect(suggestion.price == 2)
        #expect(suggestion.vatRate == 3)
        #expect(suggestion.category == nil)

        let result = ColumnMapper.map(
            rows,
            headerRow: suggestion.headerRow,
            mapping: ColumnMapping(
                name: try #require(suggestion.name),
                price: try #require(suggestion.price),
                unit: try #require(suggestion.unit),
                vatRate: try #require(suggestion.vatRate)
            ),
            options: ImportOptions(vatIncluded: true, vatRate: 21)
        )

        #expect(result.rows.map(\.name) == [
            "Urinario", "Inodoro", "Plato de ducha 90 cm", "Tubo multicapa 20 mm",
            "Mano de obra", "Desplazamiento", "Sifón de lavabo"
        ])
        #expect(result.rows.map(\.unit) == [.unit, .unit, .unit, .meter, .hour, .unit, .unit])
        #expect(result.rows.map(\.netPrice) == [
            decimal("100.0000"), decimal("100.0000"), decimal("120.0000"),
            decimal("2.5000"), decimal("30.0000"), decimal("20.0000"), 0
        ])
        // 21%, 10, 0,21 y 10 se guardan como porcentaje; la fila vacía hereda.
        #expect(result.rows.map(\.vatRate) == [
            decimal("21"), decimal("10"), decimal("21"), decimal("10"),
            decimal("21"), nil, decimal("21")
        ])
        #expect(result.warnings == [.sinPrecio(name: "Sifón de lavabo")])
    }

    @Test("Los tipos por fila llegan al catálogo al confirmar")
    @MainActor
    func itemsKeepRowVAT() throws {
        let container = try ModelContainer(
            for: ItemRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let repository = SwiftDataItemRepository(container: container)
        let useCase = ImportTariff(items: repository)

        let sheets = try XLSXReader.read(url: sample("tarifa_con_iva.xlsx"))
        let suggestion = ColumnMapper.suggestHeader(in: sheets[0].rows)
        let result = ColumnMapper.map(
            sheets[0].rows,
            headerRow: suggestion.headerRow,
            mapping: ColumnMapping(
                name: try #require(suggestion.name),
                price: try #require(suggestion.price),
                unit: try #require(suggestion.unit),
                vatRate: try #require(suggestion.vatRate)
            ),
            options: ImportOptions(vatIncluded: true, vatRate: 21)
        )

        let summary = try useCase.execute(rows: result.rows)
        #expect(summary.created == 7)
        #expect(try repository.item(named: "Urinario")?.vatRate == decimal("21"))
        #expect(try repository.item(named: "Tubo multicapa 20 mm")?.vatRate == decimal("10"))
        // Sin valor en la fila la partida no fija tipo propio: hereda el del presupuesto.
        #expect(try repository.item(named: "Desplazamiento")?.vatRate == nil)
    }
}

@Suite("Importación: vista modelo con columna IVA")
@MainActor
struct ImportVATColumnViewModelTests {
    @Test("La pantalla de revisión recoge la columna IVA de la sugerencia")
    func viewModelUsesVATColumn() throws {
        let container = try ModelContainer(
            for: ItemRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let repository = SwiftDataItemRepository(container: container)
        let viewModel = ImportTariffViewModel(
            source: LocalTariffSource(),
            template: FileTariffTemplateProvider(),
            importTariff: ImportTariff(items: repository)
        )

        viewModel.loadFile(at: sample("tarifa_con_iva.xlsx"))
        #expect(viewModel.state == .ready)
        #expect(viewModel.vatIncluded)
        viewModel.continueToReview()

        #expect(viewModel.rows.count == 7)
        #expect(viewModel.rows.first?.vatRate == decimal("21"))
        #expect(viewModel.rows.last?.vatRate == decimal("21"))
        #expect(viewModel.warningCount == 1)

        viewModel.confirm()
        #expect(viewModel.summary?.created == 7)
        #expect(try repository.item(named: "Tubo multicapa 20 mm")?.vatRate == decimal("10"))
        #expect(try repository.item(named: "Desplazamiento")?.vatRate == nil)
    }
}
