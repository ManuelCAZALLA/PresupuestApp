import Foundation
import QuoteCore
import Testing
import UniformTypeIdentifiers
@testable import PresupuestApp

/// Formatos que llegan desde Archivos o desde otras apps. El lector decide por
/// el contenido (firma ZIP/OLE), no solo por la extensión.
@Suite("Importación: formatos de archivo")
struct ImportFileFormatTests {
    private let samplesDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("ImportSamples", isDirectory: true)

    private func sample(_ name: String) -> URL {
        samplesDirectory.appendingPathComponent(name)
    }

    private func temporaryFile(named name: String, data: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString)-\(name)")
        try data.write(to: url)
        return url
    }

    @Test("El selector acepta xlsx, xlsm, xls y csv")
    func allowedFileTypes() {
        let identifiers = Set(ImportFileTypes.allowed.map(\.identifier))
        #expect(identifiers.contains("org.openxmlformats.spreadsheetml.sheet"))
        #expect(identifiers.contains("org.openxmlformats.spreadsheetml.sheet.macroenabled"))
        #expect(identifiers.contains("com.microsoft.excel.xls"))
        #expect(identifiers.contains("public.comma-separated-values-text"))
    }

    @Test("Un libro OpenXML con extensión .xlsm se lee igual que .xlsx")
    func readsMacroEnabledWorkbook() throws {
        let data = try Data(contentsOf: sample("tarifa_albanileria_tabla.xlsx"))
        let url = try temporaryFile(named: "tarifa.xlsm", data: data)
        defer { try? FileManager.default.removeItem(at: url) }

        let tables = try LocalTariffSource().tables(from: url)
        #expect(tables.map(\.name) == ["Tarifas", "Empresa ejemplo", "Notas"] as [String?])
    }

    @Test("Un libro OpenXML con extensión .xls se detecta por su firma ZIP")
    func readsOpenXMLWithLegacyExtension() throws {
        let data = try Data(contentsOf: sample("tarifa_albanileria_tabla.xlsx"))
        let url = try temporaryFile(named: "tarifa.xls", data: data)
        defer { try? FileManager.default.removeItem(at: url) }

        let tables = try LocalTariffSource().tables(from: url)
        #expect(tables.first?.rows.count == 53)
    }

    @Test("El .xls binario antiguo se rechaza con un error de importación")
    func rejectsLegacyBinaryWorkbook() throws {
        var data = Data([0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1])
        data.append(contentsOf: repeatElement(0, count: 512))
        let url = try temporaryFile(named: "tarifa.xls", data: data)
        defer { try? FileManager.default.removeItem(at: url) }

        do {
            _ = try LocalTariffSource().tables(from: url)
            Issue.record("Se esperaba un error para el .xls binario")
        } catch let error as DomainError {
            #expect(error == .importFailed("legacy xls"))
        } catch {
            Issue.record("Error inesperado: \(error)")
        }
    }

    @Test("Un archivo de texto con extensión .xlsx se lee como tabla")
    func readsDelimitedTextWithSpreadsheetExtension() throws {
        let text = "nombre,unidad,precio\nTrabajo,ud,10\nOtro,m2,20\n"
        let data = try #require(text.data(using: .utf8))
        let url = try temporaryFile(named: "tarifa.xlsx", data: data)
        defer { try? FileManager.default.removeItem(at: url) }

        let tables = try LocalTariffSource().tables(from: url)
        let rows = try #require(tables.first?.rows)
        #expect(rows.count == 3)
        #expect(rows[1] == ["Trabajo", "ud", "10"])
    }

    @Test("Una tabla HTML guardada como Excel se rechaza con un error de importación")
    func rejectsHTMLSpreadsheet() throws {
        let html = "<html><body><table><tr><td>Nombre</td></tr></table></body></html>"
        let data = try #require(html.data(using: .utf8))
        let url = try temporaryFile(named: "tarifa.xlsx", data: data)
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(throws: DomainError.self) {
            try LocalTariffSource().tables(from: url)
        }
    }
}
