import Foundation
import Observation
import QuoteCore

/// Vista modelo de S8 (ImportTariff): origen, mapeo de columnas, revisión y
/// confirmación. No guarda nada hasta que el usuario confirma. No conoce
/// SwiftData ni los formatos de archivo: solo puertos y casos de uso.
/// Ver docs/PRODUCT.md (S8) y docs/DECISIONS.md, D-008.
@MainActor
@Observable
final class ImportTariffViewModel {
    enum Step: Equatable {
        case origin
        case mapping
        case review
    }

    enum ViewState: Equatable {
        case idle
        case loading
        case ready
        case failed(String)
    }

    private(set) var state: ViewState = .idle
    private(set) var step: Step = .origin

    /// Texto pegado por el usuario (una partida por línea).
    var pastedText = ""

    /// Tablas leídas del archivo (una por hoja, o una para CSV).
    private(set) var tables: [RawTable] = []
    var selectedTableIndex = 0

    /// Cabecera detectada y columnas sugeridas.
    private(set) var suggestion = ColumnSuggestion()
    var mapping = ColumnMapping(name: 0)

    /// Interruptor "los precios incluyen IVA" y tipo.
    var vatIncluded = false
    var vatRate = Decimal(21)

    /// Filas interpretadas, listas para revisar.
    private(set) var rows: [ImportedRow] = []

    /// Cómo aplicar las filas al catálogo.
    var mode: ImportMode = .updateExisting

    /// Resumen tras confirmar la importación.
    private(set) var summary: ImportTariff.Summary?

    /// Mensaje de error de `DomainError` traducido, si la confirmación falla.
    private(set) var errorMessage: String?

    private let source: TariffImportSource
    private let template: TariffTemplateProviding
    private let importTariff: ImportTariff

    init(
        source: TariffImportSource,
        template: TariffTemplateProviding,
        importTariff: ImportTariff
    ) {
        self.source = source
        self.template = template
        self.importTariff = importTariff
    }

    // MARK: - Datos derivados

    var vatRateOptions: [Decimal] { [Decimal(21), Decimal(10), Decimal(4), Decimal(0)] }

    var currentTable: RawTable? {
        tables.indices.contains(selectedTableIndex) ? tables[selectedTableIndex] : nil
    }

    var columnCount: Int {
        currentTable?.rows.map(\.count).max() ?? 0
    }

    var columnOptions: [Int] {
        Array(0..<max(columnCount, 1))
    }

    /// Filas de muestra (cabecera y 3 siguientes) para elegir columnas.
    var previewRows: [[String]] {
        guard let table = currentTable, !table.rows.isEmpty else { return [] }
        let start = suggestion.headerRow ?? 0
        let end = min(table.rows.count, start + 4)
        return Array(table.rows[start..<end])
    }

    var warningCount: Int {
        rows.reduce(0) { $0 + $1.warnings.count }
    }

    var canContinue: Bool {
        columnCount > 0 && mapping.name < columnCount
    }

    /// Título de una columna: el texto de su cabecera o, si no hay, su letra.
    func columnTitle(_ index: Int) -> String {
        let header = headerValues.indices.contains(index) ? headerValues[index] : ""
        return header.isEmpty ? Self.letter(for: index) : header
    }

    private var headerValues: [String] {
        guard let table = currentTable,
              let headerRow = suggestion.headerRow,
              table.rows.indices.contains(headerRow) else { return [] }
        return table.rows[headerRow]
    }

    // MARK: - Origen

    /// Lee un archivo `.xlsx` o `.csv` elegido por el usuario.
    func loadFile(at url: URL) {
        state = .loading
        do {
            let loaded = try source.tables(from: url)
            guard !loaded.isEmpty else {
                state = .failed("importTariff.error.emptyFile")
                return
            }
            tables = loaded
            selectedTableIndex = 0
            applySuggestion(for: loaded[0])
            step = .mapping
            state = .ready
        } catch {
            state = .failed(AppErrorMapper.message(for: error))
        }
    }

    /// Lee un archivo de texto recibido desde "Abrir con".
    func loadPlainTextFile(at url: URL) {
        state = .loading
        do {
            pastedText = try source.plainText(from: url)
            loadPastedText()
        } catch {
            state = .failed(AppErrorMapper.message(for: error))
        }
    }

    /// Punto de entrada de "Abrir con": una hoja de cálculo va al mapeo de
    /// columnas; un archivo de texto se interpreta como lista pegada.
    func openExternalFile(at url: URL) {
        switch url.pathExtension.lowercased() {
        case "xlsx", "csv":
            loadFile(at: url)
        default:
            loadPlainTextFile(at: url)
        }
    }

    func selectTable(_ index: Int) {
        guard tables.indices.contains(index) else { return }
        selectedTableIndex = index
        applySuggestion(for: tables[index])
    }

    /// Interpreta la lista pegada y pasa directamente a la revisión.
    func loadPastedText() {
        let text = pastedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        rows = source.parsePastedText(text, options: options).rows
        step = .review
        state = .ready
    }

    // MARK: - Mapeo

    func continueToReview() {
        guard let table = currentTable else { return }
        let result = ColumnMapper.map(
            table.rows,
            headerRow: suggestion.headerRow,
            mapping: mapping,
            options: options
        )
        rows = result.rows
        step = .review
    }

    func backToMapping() {
        guard !tables.isEmpty else {
            backToOrigin()
            return
        }
        step = .mapping
    }

    func backToOrigin() {
        step = .origin
        tables = []
        rows = []
        summary = nil
        errorMessage = nil
        state = .idle
    }

    /// Vuelve al estado inicial para reutilizar el mismo ViewModel en una hoja.
    func reset() {
        pastedText = ""
        selectedTableIndex = 0
        suggestion = ColumnSuggestion()
        mapping = ColumnMapping(name: 0)
        vatIncluded = false
        vatRate = Decimal(21)
        mode = .updateExisting
        backToOrigin()
    }

    // MARK: - Revisión

    func updateName(_ name: String, for id: UUID) {
        guard let index = rows.firstIndex(where: { $0.id == id }) else { return }
        rows[index].name = name
    }

    func updateUnit(_ unit: MeasureUnit, for id: UUID) {
        guard let index = rows.firstIndex(where: { $0.id == id }) else { return }
        rows[index].unit = unit
    }

    /// Cambia el precio. Si el archivo traía IVA, el valor escrito también lo
    /// trae y se convierte a neto.
    func updatePrice(_ text: String, for id: UUID) {
        guard let index = rows.firstIndex(where: { $0.id == id }) else { return }
        let name = rows[index].name
        var warnings = rows[index].warnings.filter {
            $0.type != "precioInvalido" && $0.type != "precioAmbiguo"
        }
        switch PriceParser.parse(text) {
        case .value(let gross, _):
            rows[index].netPrice = net(gross)
        case .ambiguous(let gross, let raw):
            rows[index].netPrice = net(gross)
            warnings.append(.precioAmbiguo(name: name, raw: raw))
        case .invalid(let raw):
            if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                warnings.append(.precioInvalido(name: name, raw: raw))
            }
        }
        rows[index].warnings = warnings
    }

    func removeRow(_ id: UUID) {
        rows.removeAll { $0.id == id }
    }

    // MARK: - Confirmación

    func confirm() {
        do {
            summary = try importTariff.execute(rows: rows, mode: mode)
            errorMessage = nil
        } catch {
            errorMessage = AppErrorMapper.message(for: error)
        }
    }

    /// Prepara una plantilla temporal para compartirla.
    func templateURL() throws -> URL {
        try template.temporaryTemplateURL()
    }

    // MARK: - Apoyo

    private var options: ImportOptions {
        ImportOptions(vatIncluded: vatIncluded, vatRate: vatRate)
    }

    private func net(_ gross: Decimal) -> Decimal {
        vatIncluded ? RoundingPolicy.netPrice(fromGross: gross, vatRate: vatRate) : gross
    }

    private func applySuggestion(for table: RawTable) {
        suggestion = ColumnMapper.suggestHeader(in: table.rows)
        let columns = table.rows.map(\.count).max() ?? 0
        mapping = ColumnMapping(
            name: min(suggestion.name ?? 0, max(columns - 1, 0)),
            price: suggestion.price,
            unit: suggestion.unit,
            category: suggestion.category,
            vatRate: suggestion.vatRate
        )
        vatIncluded = ColumnMapper.suggestedVATIncluded(in: table.rows)
    }

    private static func letter(for index: Int) -> String {
        guard index >= 0, index < 26, let scalar = UnicodeScalar(65 + index) else {
            return "\(index + 1)"
        }
        return String(Character(scalar))
    }
}
