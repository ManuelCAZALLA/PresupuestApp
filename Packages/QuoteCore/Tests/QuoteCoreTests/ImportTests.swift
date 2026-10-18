import Foundation
import Testing
@testable import QuoteCore

@Suite("Precio y unidad")
struct PriceAndUnitParsingTests {
    @Test("Precios válidos")
    func validPrices() {
        #expect(PriceParser.parse("25") == .value(25, hasCurrencySymbol: false))
        #expect(PriceParser.parse("25,5") == .value(d("25.5"), hasCurrencySymbol: false))
        #expect(PriceParser.parse("25.50") == .value(d("25.5"), hasCurrencySymbol: false))
        #expect(PriceParser.parse("1.234,50") == .value(d("1234.50"), hasCurrencySymbol: false))
        #expect(PriceParser.parse("25 €") == .value(25, hasCurrencySymbol: true))
        #expect(PriceParser.parse("25€/ud") == .value(25, hasCurrencySymbol: true))
        #expect(PriceParser.parse("133,10 €") == .value(d("133.10"), hasCurrencySymbol: true))
    }

    @Test("Precio ambiguo: un punto con tres decimales")
    func ambiguousPrice() {
        guard case .ambiguous(let value, let raw) = PriceParser.parse("1.234") else {
            Issue.record("Se esperaba ambiguo")
            return
        }
        #expect(value == 1234)
        #expect(raw == "1.234")
    }

    @Test("Precio inválido")
    func invalidPrice() {
        #expect(PriceParser.parse("consultar") == .invalid(raw: "consultar"))
        #expect(PriceParser.parse("") == .invalid(raw: ""))
        #expect(PriceParser.parse("-5") == .invalid(raw: "-5"))
    }

    @Test("Unidades reconocidas")
    func knownUnits() {
        #expect(UnitParser.parse("ud") == .known(.unit))
        #expect(UnitParser.parse("Ud.") == .known(.unit))
        #expect(UnitParser.parse("u") == .known(.unit))
        #expect(UnitParser.parse("ml") == .known(.meter))
        #expect(UnitParser.parse("m") == .known(.meter))
        #expect(UnitParser.parse("m2") == .known(.squareMeter))
        #expect(UnitParser.parse("m²") == .known(.squareMeter))
        #expect(UnitParser.parse("h") == .known(.hour))
        #expect(UnitParser.parse("hora") == .known(.hour))
        #expect(UnitParser.parse("global") == .known(.lumpSum))
    }

    @Test("Unidad ausente o desconocida")
    func unknownUnits() {
        #expect(UnitParser.parse(nil) == .absent)
        #expect(UnitParser.parse("   ") == .absent)
        #expect(UnitParser.parse("cajas") == .unknown("cajas"))
    }
}

@Suite("Mapeo de columnas")
struct ColumnMapperTests {
    @Test("Detecta la cabecera y sugiere columnas")
    func detectAndSuggest() {
        let rows: [[String]] = [
            ["TARIFA 2026 (PRUEBA)"],
            ["Precios con IVA incluido"],
            [],
            ["Descripción", "Unidad", "PVP (IVA incl.)", "Observaciones"],
            ["Urinario", "Ud.", "121"],
            ["SIN CATEGORÍA"],
            ["Sifón de lavabo", "Ud.", ""]
        ]

        #expect(ColumnMapper.detectHeaderRow(in: rows) == 3)
        let suggestion = ColumnMapper.suggestHeader(in: rows)
        #expect(suggestion.headerRow == 3)
        #expect(suggestion.name == 0)
        #expect(suggestion.unit == 1)
        #expect(suggestion.price == 2)
        #expect(suggestion.category == nil)
        #expect(ColumnMapper.suggestedVATIncluded(in: rows))
    }

    @Test("Cabeceras en inglés")
    func englishHeaders() {
        let rows: [[String]] = [
            ["name", "unit", "price"],
            ["Urinario", "ud", "100.00"]
        ]
        let suggestion = ColumnMapper.suggestHeader(in: rows)
        #expect(suggestion.name == 0)
        #expect(suggestion.unit == 1)
        #expect(suggestion.price == 2)
        #expect(!ColumnMapper.suggestedVATIncluded(in: rows))
    }

    @Test("Sin IVA: el precio se guarda tal cual")
    func plainPrices() {
        let rows: [[String]] = [
            ["Concepto", "Ud", "Precio"],
            ["Urinario", "ud", "100"]
        ]
        let result = ColumnMapper.map(
            rows,
            headerRow: 0,
            mapping: ColumnMapping(name: 0, price: 2, unit: 1),
            options: ImportOptions(vatIncluded: false, vatRate: 21)
        )
        #expect(result.rows.count == 1)
        #expect(result.rows.first?.netPrice == 100)
        #expect(result.warnings.isEmpty)
    }

    @Test("Con IVA incluido: se convierte a neto con round4")
    func netPrices() {
        let rows: [[String]] = [
            ["Descripción", "Unidad", "PVP"],
            ["Urinario", "Ud.", "121"],
            ["Tubo", "ml", "3.03"],
            ["Sifón", "Ud.", ""]
        ]
        let result = ColumnMapper.map(
            rows,
            headerRow: 0,
            mapping: ColumnMapping(name: 0, price: 2, unit: 1),
            options: ImportOptions(vatIncluded: true, vatRate: 21)
        )
        #expect(result.rows.count == 3)
        #expect(result.rows[0].netPrice == d("100.0000"))
        #expect(result.rows[1].netPrice == d("2.5041"))
        #expect(result.rows[1].unit == .meter)
        // Fila con unidad y sin precio: se importa con aviso, no se salta.
        #expect(result.rows[2].netPrice == 0)
        #expect(result.rows[2].warnings == [.sinPrecio(name: "Sifón")])
    }

    @Test("Filas de categoría y vacías se saltan sin aviso")
    func skipsCategories() {
        let rows: [[String]] = [
            ["Concepto", "Ud", "Precio"],
            ["SANITARIOS"],
            ["Urinario", "ud", "100"],
            [],
            ["Nota final sin precio ni unidad"]
        ]
        let result = ColumnMapper.map(
            rows,
            headerRow: 0,
            mapping: ColumnMapping(name: 0, price: 2, unit: 1),
            options: ImportOptions()
        )
        #expect(result.rows.map(\.name) == ["Urinario"])
        #expect(result.warnings.isEmpty)
    }

    @Test("Nombre repetido en el archivo avisa duplicado")
    func duplicateNames() {
        let rows: [[String]] = [
            ["Concepto", "Ud", "Precio"],
            ["Urinario", "ud", "100"],
            ["Urinario", "ud", "105"]
        ]
        let result = ColumnMapper.map(
            rows,
            headerRow: 0,
            mapping: ColumnMapping(name: 0, price: 2, unit: 1),
            options: ImportOptions()
        )
        #expect(result.rows.count == 2)
        #expect(result.rows[1].warnings == [.duplicado(name: "Urinario")])
    }
}

@Suite("ImportTariff")
struct ImportTariffUseCaseTests {
    private func row(_ name: String, price: Decimal, unit: MeasureUnit = .unit) -> ImportedRow {
        ImportedRow(name: name, unit: unit, netPrice: price)
    }

    @Test("Crea partidas nuevas")
    func createsNew() throws {
        let items = FakeItemRepository()
        let summary = try ImportTariff(items: items).execute(
            rows: [row("Urinario", price: 100), row("Inodoro", price: 110)]
        )
        #expect(summary.created == 2)
        #expect(summary.updated == 0)
        #expect(try items.all().count == 2)
    }

    @Test("Actualiza existentes por nombre normalizado")
    func updatesExisting() throws {
        let items = FakeItemRepository()
        let useCase = ImportTariff(items: items)
        _ = try useCase.execute(rows: [row("Urinario", price: 100)])
        let summary = try useCase.execute(rows: [row("URINARIO", price: 120)])
        #expect(summary.created == 0)
        #expect(summary.updated == 1)
        #expect(try items.all().count == 1)
        #expect(try items.item(named: "urinario")?.unitPrice == 120)
    }

    @Test("Modo solo nuevas: salta las que ya existen")
    func addOnlyNew() throws {
        let items = FakeItemRepository()
        let useCase = ImportTariff(items: items)
        _ = try useCase.execute(rows: [row("Urinario", price: 100)])
        let summary = try useCase.execute(
            rows: [row("Urinario", price: 999), row("Inodoro", price: 110)],
            mode: .addOnlyNew
        )
        #expect(summary.created == 1)
        #expect(summary.skipped == 1)
        #expect(try items.item(named: "Urinario")?.unitPrice == 100)
    }

    @Test("Importar dos veces no duplica")
    func idempotent() throws {
        let items = FakeItemRepository()
        let useCase = ImportTariff(items: items)
        let batch = [row("Urinario", price: 100), row("Mano de obra", price: 30, unit: .hour)]
        _ = try useCase.execute(rows: batch)
        _ = try useCase.execute(rows: batch)
        #expect(try items.all().count == 2)
    }
}

/// Columna opcional `IVA` por fila (docs/DOMAIN.md y DECISIONS.md, D-012).
@Suite("Columna IVA opcional")
struct ImportVATColumnTests {
    @Test("Formatos aceptados: 21, 21%, 0,21 y 10")
    func acceptedFormats() {
        #expect(VATParser.parse("21") == d("21"))
        #expect(VATParser.parse("21%") == d("21"))
        #expect(VATParser.parse("0,21") == d("21"))
        #expect(VATParser.parse("0.21") == d("21"))
        #expect(VATParser.parse("10") == d("10"))
        #expect(VATParser.parse("0") == d("0"))
        #expect(VATParser.parse(" 21 % ") == d("21"))
        #expect(VATParser.parse("21,5") == d("21.5"))
    }

    @Test("Valores ilegibles se quedan sin tipo")
    func invalidFormats() {
        #expect(VATParser.parse("") == nil)
        #expect(VATParser.parse("   ") == nil)
        #expect(VATParser.parse("veinte") == nil)
        #expect(VATParser.parse("150") == nil)
        #expect(VATParser.parse("-21") == nil)
    }

    @Test("La cabecera IVA se sugiere como columna")
    func headerSuggestion() {
        let rows: [[String]] = [
            ["Concepto", "Unidad", "Precio", "IVA"],
            ["Urinario", "ud", "121", "21%"]
        ]
        let suggestion = ColumnMapper.suggestHeader(in: rows)
        #expect(suggestion.vatRate == 3)

        // "IVA" en el texto previo ("precios con IVA incluido") no es cabecera.
        let withNote: [[String]] = [
            ["Precios con IVA incluido"],
            [],
            ["Concepto", "Unidad", "Precio", "IVA"]
        ]
        #expect(ColumnMapper.detectHeaderRow(in: withNote) == 2)
        #expect(ColumnMapper.suggestHeader(in: withNote).vatRate == 3)
    }

    @Test("Cada fila convierte su precio con su propio tipo")
    func perRowConversion() {
        let rows: [[String]] = [
            ["Concepto", "Unidad", "Precio", "IVA"],
            ["Urinario", "ud", "121", "21%"],
            ["Inodoro", "ud", "110", "10"],
            ["Tubo", "m", "3,03", "0,21"]
        ]
        let result = ColumnMapper.map(
            rows,
            headerRow: 0,
            mapping: ColumnMapping(name: 0, price: 2, unit: 1, vatRate: 3),
            options: ImportOptions(vatIncluded: true, vatRate: 21)
        )

        #expect(result.rows.map(\.netPrice) == [d("100.0000"), d("100.0000"), d("2.5041")])
        #expect(result.rows.map(\.vatRate) == [d("21"), d("10"), d("21")])
        #expect(result.warnings.isEmpty)
    }

    @Test("Fila sin IVA usa el tipo del interruptor; ilegible avisa")
    func fallbackAndWarning() {
        let rows: [[String]] = [
            ["Concepto", "Unidad", "Precio", "IVA"],
            ["Desplazamiento", "ud", "24,20", ""],
            ["Sifón", "ud", "30,30", "veinte"]
        ]
        let result = ColumnMapper.map(
            rows,
            headerRow: 0,
            mapping: ColumnMapping(name: 0, price: 2, unit: 1, vatRate: 3),
            options: ImportOptions(vatIncluded: true, vatRate: 21)
        )

        #expect(result.rows.map(\.netPrice) == [d("20.0000"), d("25.0413")])
        // Sin valor legible la partida se queda sin tipo propio: hereda el del presupuesto.
        #expect(result.rows.map(\.vatRate) == [nil, nil])
        #expect(result.warnings == [.vatInvalido(name: "Sifón", raw: "veinte")])
    }

    @Test("El IVA de la fila llega a la partida; sin columna queda heredado")
    func itemVATFromImport() throws {
        let items = FakeItemRepository()
        let useCase = ImportTariff(items: items)

        let withVAT = try useCase.execute(rows: [
            ImportedRow(name: "Mano de obra", unit: .hour, netPrice: d("30"), vatRate: d("10")),
            ImportedRow(name: "Urinario", netPrice: d("100"), vatRate: nil)
        ])
        #expect(withVAT.created == 2)
        #expect(try items.item(named: "Mano de obra")?.vatRate == d("10"))
        #expect(try items.item(named: "Urinario")?.vatRate == nil)

        // Reimportar sin IVA en la fila no borra el tipo que ya tenía la partida.
        _ = try useCase.execute(rows: [ImportedRow(name: "Mano de obra", netPrice: d("31"), vatRate: nil)])
        #expect(try items.item(named: "Mano de obra")?.vatRate == d("10"))
    }

    @Test("La partida importada sin columna de IVA no fija tipo propio")
    func importWithoutColumnKeepsInheritance() throws {
        let items = FakeItemRepository()
        _ = try ImportTariff(items: items).execute(rows: [
            ImportedRow(name: "Urinario", netPrice: d("100"))
        ])
        #expect(try items.item(named: "Urinario")?.vatRate == nil)
    }
}
