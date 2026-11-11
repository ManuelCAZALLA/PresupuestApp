import Foundation
import QuoteCore

/// Lector OpenXML propio: descomprime el ZIP y parsea valores de celda
/// (`inlineStr`, shared strings y números) con `XMLParser`. Complementa
/// CoreXLSX, que falla en libros con tabla Excel o namespaces en cada hoja.
/// Ver docs/DECISIONS.md, D-009.
enum XLSXOpenXMLReader {
    private static let maxRows = 20_000
    private static let maxColumns = 200

    static func read(data: Data) throws -> [RawTable] {
        let files = try XLSXZipArchive.entries(from: data)
        let workbookData = try file(files, names: ["xl/workbook.xml", "/xl/workbook.xml"])
        let relsData = try file(
            files,
            names: ["xl/_rels/workbook.xml.rels", "/xl/_rels/workbook.xml.rels"]
        )
        let sheets = WorkbookParser.parse(workbookData)
        let rels = RelationshipsParser.parse(relsData)
        let sharedStrings = sharedStrings(from: files)

        var tables: [RawTable] = []
        for sheet in sheets {
            guard let target = rels[sheet.relationshipID] else { continue }
            let path = worksheetPath(from: target)
            guard let sheetData = files[path] ?? files[path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))] else {
                continue
            }
            let rows = WorksheetParser.parse(
                sheetData,
                sharedStrings: sharedStrings,
                maxRows: maxRows,
                maxColumns: maxColumns
            )
            tables.append(RawTable(name: sheet.name, rows: rows))
        }
        guard !tables.isEmpty else {
            throw DomainError.importFailed("El archivo .xlsx no tiene hojas")
        }
        return tables
    }

    private static func file(_ files: [String: Data], names: [String]) throws -> Data {
        for name in names {
            if let data = files[name] { return data }
        }
        throw DomainError.importFailed("No se pudo leer el contenido del .xlsx")
    }

    private static func sharedStrings(from files: [String: Data]) -> [String] {
        guard let data = files["xl/sharedStrings.xml"] ?? files["/xl/sharedStrings.xml"] else {
            return []
        }
        return SharedStringsParser.parse(data)
    }

    private static func worksheetPath(from target: String) -> String {
        if target.hasPrefix("/") {
            return String(target.dropFirst())
        }
        if target.hasPrefix("xl/") {
            return target
        }
        return "xl/" + target
    }
}

// MARK: - Workbook

private struct WorkbookSheet {
    let name: String
    let relationshipID: String
}

private final class WorkbookParser: NSObject, XMLParserDelegate {
    private var sheets: [WorkbookSheet] = []

    static func parse(_ data: Data) -> [WorkbookSheet] {
        let parser = WorkbookParser()
        let xml = XMLParser(data: data)
        xml.delegate = parser
        xml.shouldProcessNamespaces = true
        xml.parse()
        return parser.sheets
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        guard elementName == "sheet" || qName?.hasSuffix("sheet") == true else { return }
        let name = attributeDict["name"] ?? "Hoja"
        let relationship = attributeDict["id"]
            ?? attributeDict["r:id"]
            ?? attributeDict["r:Id"]
            ?? ""
        sheets.append(WorkbookSheet(name: name, relationshipID: relationship))
    }
}

// MARK: - Relationships

private final class RelationshipsParser: NSObject, XMLParserDelegate {
    private var items: [String: String] = [:]

    static func parse(_ data: Data) -> [String: String] {
        let parser = RelationshipsParser()
        let xml = XMLParser(data: data)
        xml.delegate = parser
        xml.shouldProcessNamespaces = true
        xml.parse()
        return parser.items
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        let local = elementName
        guard local == "Relationship" || local == "relationship" else { return }
        let id = attributeDict["Id"] ?? attributeDict["id"] ?? ""
        let target = attributeDict["Target"] ?? attributeDict["target"] ?? ""
        if !id.isEmpty {
            items[id] = target
        }
    }
}

// MARK: - Shared strings

private final class SharedStringsParser: NSObject, XMLParserDelegate {
    private var items: [String] = []
    private var current = ""
    private var collecting = false

    static func parse(_ data: Data) -> [String] {
        let parser = SharedStringsParser()
        let xml = XMLParser(data: data)
        xml.delegate = parser
        xml.shouldProcessNamespaces = true
        xml.parse()
        return parser.items
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        if elementName == "si" {
            current = ""
        } else if elementName == "t" {
            collecting = true
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if collecting { current += string }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if elementName == "t" {
            collecting = false
        } else if elementName == "si" {
            items.append(current)
            current = ""
        }
    }
}

// MARK: - Worksheet

private final class WorksheetParser: NSObject, XMLParserDelegate {
    private let sharedStrings: [String]
    private let maxRows: Int
    private let maxColumns: Int

    private var rowCount = 0
    private var columnCount = 0
    private var cells: [Int: [Int: String]] = [:]

    private var cellRow = 0
    private var cellColumn = 0
    private var cellType = ""
    private var cellText = ""
    private var collecting = false
    private var insideInline = false

    static func parse(
        _ data: Data,
        sharedStrings: [String],
        maxRows: Int,
        maxColumns: Int
    ) -> [[String]] {
        let parser = WorksheetParser(
            sharedStrings: sharedStrings,
            maxRows: maxRows,
            maxColumns: maxColumns
        )
        let xml = XMLParser(data: data)
        xml.delegate = parser
        xml.shouldProcessNamespaces = true
        xml.parse()
        return parser.grid()
    }

    private init(sharedStrings: [String], maxRows: Int, maxColumns: Int) {
        self.sharedStrings = sharedStrings
        self.maxRows = maxRows
        self.maxColumns = maxColumns
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        switch elementName {
        case "c":
            let reference = attributeDict["r"] ?? ""
            let parsed = Self.cellAddress(reference)
            cellRow = parsed.row
            cellColumn = parsed.column
            cellType = attributeDict["t"] ?? ""
            cellText = ""
            insideInline = false
        case "is":
            insideInline = true
        case "v":
            collecting = true
        case "t":
            collecting = true
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if collecting { cellText += string }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        switch elementName {
        case "v", "t":
            collecting = false
        case "is":
            insideInline = false
        case "c":
            storeCurrentCell()
        default:
            break
        }
    }

    private func storeCurrentCell() {
        guard cellRow > 0, cellColumn >= 0 else { return }
        let rowIndex = cellRow - 1
        guard rowIndex < maxRows, cellColumn < maxColumns else { return }
        let value: String
        if cellType == "s", let index = Int(cellText.trimmingCharacters(in: .whitespaces)),
           sharedStrings.indices.contains(index) {
            value = sharedStrings[index]
        } else {
            value = cellText
        }
        var row = cells[rowIndex] ?? [:]
        row[cellColumn] = value
        cells[rowIndex] = row
        rowCount = max(rowCount, cellRow)
        columnCount = max(columnCount, cellColumn + 1)
    }

    private func grid() -> [[String]] {
        let rows = min(rowCount, maxRows)
        let columns = min(columnCount, maxColumns)
        guard rows > 0, columns > 0 else { return [] }
        var grid = Array(repeating: [String](repeating: "", count: columns), count: rows)
        for (row, values) in cells {
            guard row < rows else { continue }
            for (column, value) in values where column < columns {
                grid[row][column] = value
            }
        }
        return grid
    }

    /// `A1` → (row: 1, column: 0).
    static func cellAddress(_ reference: String) -> (row: Int, column: Int) {
        var column = 0
        var row = 0
        for scalar in reference.unicodeScalars {
            if scalar.value >= 65, scalar.value <= 90 {
                column = column * 26 + Int(scalar.value) - 64
            } else if scalar.value >= 48, scalar.value <= 57 {
                row = row * 10 + Int(scalar.value) - 48
            }
        }
        return (row, column - 1)
    }
}
