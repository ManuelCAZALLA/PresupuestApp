import Foundation
import QuoteCore
import SwiftData
import Testing
@testable import PresupuestApp

/// Los archivos de `Tests/ImportSamples` y su resultado esperado
/// (`expected_imports.json`) son el oráculo de la importación. No se tocan.
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

@Suite("Importación: archivos de ejemplo")
struct ImportSampleTests {
    @Test("tarifa_simple.xlsx: 8 partidas sin IVA y sin avisos")
    func simpleSpreadsheet() throws {
        let sheets = try XLSXReader.read(url: sample("tarifa_simple.xlsx"))
        #expect(sheets.count == 1)
        #expect(sheets[0].name == "Tarifa")
        let rows = sheets[0].rows

        let suggestion = ColumnMapper.suggestHeader(in: rows)
        #expect(suggestion.headerRow == 0)
        #expect(suggestion.name == 0)
        #expect(suggestion.unit == 1)
        #expect(suggestion.price == 2)
        #expect(!ColumnMapper.suggestedVATIncluded(in: rows))

        let result = ColumnMapper.map(
            rows,
            headerRow: suggestion.headerRow,
            mapping: ColumnMapping(name: 0, price: 2, unit: 1),
            options: ImportOptions(vatIncluded: false, vatRate: 21)
        )

        #expect(result.rows.count == 8)
        #expect(result.warnings.isEmpty)
        #expect(
            result.rows.map(\.name) == [
                "Urinario", "Inodoro", "Plato de ducha 90 cm", "Termo eléctrico 80 litros",
                "Grifo de lavabo", "Tubo multicapa 20 mm", "Mano de obra", "Desplazamiento"
            ]
        )
        #expect(result.rows[0].netPrice == Decimal(100))
        #expect(result.rows[5].unit == .meter)
        #expect(result.rows[5].netPrice == decimal("2.5"))
        #expect(result.rows[6].unit == .hour)
    }

    @Test("tarifa_desordenada.xlsx: cabecera en la fila 4, IVA incluido, 8 partidas")
    func messySpreadsheet() throws {
        let sheets = try XLSXReader.read(url: sample("tarifa_desordenada.xlsx"))
        #expect(sheets.map(\.name) == ["Tarifa 2026", "Notas"])
        let rows = try #require(sheets.first { $0.name == "Tarifa 2026" }).rows

        // El oráculo usa filas 1-based: la cabecera está en la 4.
        #expect(ColumnMapper.detectHeaderRow(in: rows) == 3)
        #expect(ColumnMapper.suggestedVATIncluded(in: rows))

        let suggestion = ColumnMapper.suggestHeader(in: rows)
        let result = ColumnMapper.map(
            rows,
            headerRow: suggestion.headerRow,
            mapping: ColumnMapping(
                name: try #require(suggestion.name),
                price: try #require(suggestion.price),
                unit: try #require(suggestion.unit)
            ),
            options: ImportOptions(vatIncluded: true, vatRate: 21)
        )

        #expect(result.rows.map(\.name) == [
            "Urinario", "Inodoro", "Plato de ducha 90 cm", "Mampara de ducha",
            "Tubo multicapa 20 mm", "Tubo multicapa 25 mm", "Mano de obra", "Sifón de lavabo"
        ])
        #expect(result.rows.map(\.unit) == [.unit, .unit, .unit, .unit, .meter, .meter, .hour, .unit])
        #expect(result.rows[0].netPrice == decimal("100.0000"))
        #expect(result.rows[1].netPrice == decimal("110.0000"))
        #expect(result.rows[2].netPrice == decimal("120.0000"))
        #expect(result.rows[3].netPrice == decimal("200.0000"))
        #expect(result.rows[4].netPrice == decimal("2.5041"))
        #expect(result.rows[5].netPrice == decimal("3.5041"))
        #expect(result.rows[6].netPrice == decimal("30.0000"))
        #expect(result.rows[7].netPrice == 0)
        #expect(result.warnings == [.sinPrecio(name: "Sifón de lavabo")])
    }

    @Test("tarifa_es_puntoycoma_cp1252.csv: Windows-1252, punto y coma, coma decimal")
    func cp1252Spreadsheet() throws {
        let data = try Data(contentsOf: sample("tarifa_es_puntoycoma_cp1252.csv"))
        let read = try CSVReader.read(data: data, name: "tarifa_es_puntoycoma_cp1252.csv")

        #expect(read.encoding == .windows1252)
        #expect(read.separator == ";")
        #expect(read.decimalSeparator == ",")

        let result = ColumnMapper.map(
            read.table.rows,
            headerRow: ColumnMapper.detectHeaderRow(in: read.table.rows),
            mapping: ColumnMapping(name: 0, price: 2, unit: 1),
            options: ImportOptions(vatIncluded: false, vatRate: 21)
        )

        #expect(result.rows.count == 7)
        #expect(result.warnings.isEmpty)
        #expect(result.rows[2].name == "Termo eléctrico 80 litros")
        #expect(result.rows[3].unit == .meter)
        #expect(result.rows[3].netPrice == decimal("2.5"))
        #expect(result.rows[4].unit == .hour)
    }

    @Test("tarifa_coma_utf8.csv: la coma entre comillas no separa columnas")
    func utf8Spreadsheet() throws {
        let data = try Data(contentsOf: sample("tarifa_coma_utf8.csv"))
        let read = try CSVReader.read(data: data, name: "tarifa_coma_utf8.csv")

        #expect(read.encoding == .utf8)
        #expect(read.separator == ",")
        #expect(read.decimalSeparator == ".")

        let result = ColumnMapper.map(
            read.table.rows,
            headerRow: ColumnMapper.detectHeaderRow(in: read.table.rows),
            mapping: ColumnMapping(name: 0, price: 2, unit: 1),
            options: ImportOptions(vatIncluded: false, vatRate: 21)
        )

        #expect(result.rows.count == 5)
        #expect(result.warnings.isEmpty)
        #expect(result.rows[2].name == "Termo eléctrico, 80 litros")
        #expect(result.rows[3].netPrice == decimal("2.5"))
    }

    @Test("lista_whatsapp.txt: 7 partidas, saludos y notas fuera")
    func whatsappList() throws {
        let text = try String(contentsOf: sample("lista_whatsapp.txt"), encoding: .utf8)
        let result = PastedTextParser.parse(text)

        #expect(result.rows.map(\.name) == [
            "Urinario", "Inodoro", "Termo 80 litros", "Plato de ducha 90 cm",
            "tubo 20mm", "mano de obra", "Desplazamiento"
        ])
        #expect(result.rows[0].netPrice == Decimal(100))
        #expect(result.rows[3].netPrice == Decimal(120))
        #expect(result.rows[4].unit == .meter)
        #expect(result.rows[5].unit == .hour)
        #expect(result.warnings.contains(.precioSinMoneda(name: "Desplazamiento")))
    }

    @Test("Importar dos veces el mismo archivo no duplica partidas")
    @MainActor
    func importingTwiceDoesNotDuplicate() throws {
        let container = try ModelContainer(
            for: ItemRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let repository = SwiftDataItemRepository(container: container)
        let useCase = ImportTariff(items: repository)

        let sheets = try XLSXReader.read(url: sample("tarifa_simple.xlsx"))
        let rows = sheets[0].rows
        let result = ColumnMapper.map(
            rows,
            headerRow: 0,
            mapping: ColumnMapping(name: 0, price: 2, unit: 1),
            options: ImportOptions()
        )

        let first = try useCase.execute(rows: result.rows)
        #expect(first.created == 8)
        #expect(try repository.all().count == 8)

        let second = try useCase.execute(rows: result.rows)
        #expect(second.created == 0)
        #expect(second.updated == 8)
        #expect(try repository.all().count == 8)
    }
}

@Suite("Importación: formato de archivos")
struct ImportFormatTests {
    @Test("El CSV detecta el separador por la cabecera")
    func separatorDetection() {
        #expect(CSVReader.detectSeparator(in: "Nombre;Unidad;Precio\n") == ";")
        #expect(CSVReader.detectSeparator(in: "name,unit,price\n") == ",")
    }

    @Test("El CSV respeta las comillas dobles")
    func quotedFields() {
        let rows = CSVReader.parse(
            text: "name,price\n\"Termo, 80 litros\",220\n",
            separator: ","
        )
        #expect(rows == [["name", "price"], ["Termo, 80 litros", "220"]])
    }

    @Test("La plantilla lleva BOM, separador y cabecera en español")
    func template() {
        let data = FileTariffTemplateProvider.data()
        #expect(data.prefix(3) == Data([0xEF, 0xBB, 0xBF]))
        let text = String(data: data.dropFirst(3), encoding: .utf8)
        #expect(text == "Nombre;Unidad;Precio\n")
    }
}

@Suite("Importación: vista modelo")
@MainActor
struct ImportTariffViewModelTests {
    private func makeViewModel() throws -> (ImportTariffViewModel, SwiftDataItemRepository) {
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
        return (viewModel, repository)
    }

    @Test("De archivo a catálogo: revisar antes de guardar y confirmar después")
    func endToEndFromFile() throws {
        let (viewModel, repository) = try makeViewModel()

        viewModel.loadFile(at: sample("tarifa_simple.xlsx"))
        #expect(viewModel.state == .ready)
        #expect(viewModel.step == .mapping)
        #expect(viewModel.rows.isEmpty)

        viewModel.continueToReview()
        #expect(viewModel.step == .review)
        #expect(viewModel.rows.count == 8)
        // Todavía no se ha guardado nada.
        #expect(try repository.all().isEmpty)

        viewModel.confirm()
        #expect(viewModel.summary?.created == 8)
        #expect(try repository.all().count == 8)
    }

    @Test("Con IVA incluido, la revisión enseña el precio neto")
    func reviewConvertsVAT() throws {
        let (viewModel, _) = try makeViewModel()

        viewModel.loadFile(at: sample("tarifa_desordenada.xlsx"))
        #expect(viewModel.vatIncluded)
        viewModel.continueToReview()

        #expect(viewModel.rows.first?.name == "Urinario")
        #expect(viewModel.rows.first?.netPrice == decimal("100"))
        #expect(viewModel.warningCount == 1)
    }

    @Test("Quitar una fila antes de confirmar la deja fuera")
    func discardRow() throws {
        let (viewModel, repository) = try makeViewModel()

        viewModel.pastedText = "Urinario 100 €\nInodoro 110 €"
        viewModel.loadPastedText()
        #expect(viewModel.step == .review)
        #expect(viewModel.rows.count == 2)

        viewModel.removeRow(try #require(viewModel.rows.first).id)
        #expect(viewModel.rows.count == 1)

        viewModel.confirm()
        #expect(viewModel.summary?.created == 1)
        #expect(try repository.all().map(\.name) == ["Inodoro"])
    }
}
