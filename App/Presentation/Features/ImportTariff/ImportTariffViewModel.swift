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

    /// Lee Excel/CSV en el mapeador y enruta PDF con texto seleccionable a revisión.
    func loadFile(at url: URL) {
        if url.pathExtension.lowercased() == "pdf" {
            loadPlainTextFile(at: url)
            return
        }
        state = .loading
        do {
            let loaded = try source.tables(from: url)
            guard !loaded.isEmpty else {
                state = .failed(String(localized: "importTariff.error.emptyFile"))
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
            if url.pathExtension.lowercased() == "pdf", rows.isEmpty {
                state = .failed(String(localized: "importTariff.error.pdfNoRows"))
            }
        } catch {
            if url.pathExtension.lowercased() == "pdf" {
                state = .failed(String(localized: "importTariff.error.pdfNoText"))
            } else {
                state = .failed(AppErrorMapper.message(for: error))
            }
        }
    }

    /// Punto de entrada de "Abrir con": una hoja de cálculo va al mapeo de
    /// columnas; un archivo de texto se interpreta como lista pegada.
    func openExternalFile(at url: URL) {
        switch url.pathExtension.lowercased() {
        case "xlsx", "xlsm", "xls", "csv":
            loadFile(at: url)
        case "pdf":
            loadPlainTextFile(at: url)
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
        rows[index].warnings = rows[index].warnings.map { Self.renaming($0, to: name) }
        refreshDuplicateWarnings()
    }

    func updateUnit(_ unit: MeasureUnit, for id: UUID) {
        guard let index = rows.firstIndex(where: { $0.id == id }) else { return }
        rows[index].unit = unit
        rows[index].warnings.removeAll { $0.type == "unidadDesconocida" }
    }

    /// Edita el precio neto que muestra la revisión. La conversión desde
    /// precio con IVA ya se hizo al interpretar el archivo.
    func updatePrice(_ text: String, for id: UUID) {
        guard let index = rows.firstIndex(where: { $0.id == id }) else { return }
        let name = rows[index].name
        var warnings = rows[index].warnings.filter {
            !["sinPrecio", "precioInvalido", "precioAmbiguo", "precioSinMoneda"].contains($0.type)
        }
        switch PriceParser.parse(text) {
        case .value(let price, _):
            rows[index].netPrice = price
        case .ambiguous(let price, let raw):
            rows[index].netPrice = price
            warnings.append(.precioAmbiguo(name: name, raw: raw))
        case .invalid(let raw):
            rows[index].netPrice = 0
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                warnings.append(.sinPrecio(name: name))
            } else {
                warnings.append(.precioInvalido(name: name, raw: raw))
            }
        }
        rows[index].warnings = warnings
    }

    func updateVATRate(_ text: String, for id: UUID) {
        guard let index = rows.firstIndex(where: { $0.id == id }) else { return }
        let raw = text.trimmingCharacters(in: .whitespacesAndNewlines)
        rows[index].warnings.removeAll { $0.type == "vatInvalido" }
        if raw.isEmpty {
            rows[index].vatRate = nil
        } else if let rate = VATParser.parse(raw) {
            rows[index].vatRate = rate
        } else {
            rows[index].vatRate = nil
            rows[index].warnings.append(.vatInvalido(name: rows[index].name, raw: raw))
        }
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

    private func refreshDuplicateWarnings() {
        for index in rows.indices {
            rows[index].warnings.removeAll { $0.type == "duplicado" }
        }
        var seen: Set<String> = []
        for index in rows.indices {
            let key = Item.nameKey(rows[index].name)
            guard !key.isEmpty else { continue }
            if !seen.insert(key).inserted {
                rows[index].warnings.append(.duplicado(name: rows[index].name))
            }
        }
    }

    private static func renaming(_ warning: ImportWarning, to name: String) -> ImportWarning {
        switch warning {
        case .sinPrecio: return .sinPrecio(name: name)
        case .precioInvalido(_, let raw): return .precioInvalido(name: name, raw: raw)
        case .unidadDesconocida(_, let raw): return .unidadDesconocida(name: name, raw: raw)
        case .duplicado: return .duplicado(name: name)
        case .precioAmbiguo(_, let raw): return .precioAmbiguo(name: name, raw: raw)
        case .precioSinMoneda: return .precioSinMoneda(name: name)
        case .vatInvalido(_, let raw): return .vatInvalido(name: name, raw: raw)
        }
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
