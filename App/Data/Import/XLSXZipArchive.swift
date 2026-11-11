import Compression
import Foundation
import QuoteCore

/// Extrae entradas de un `.xlsx` (ZIP) sin añadir dependencias: CoreXLSX
/// no abre algunos libros reales (tablas Excel, `xmlns:r` en cada hoja).
enum XLSXZipArchive {
    static func entries(from data: Data) throws -> [String: Data] {
        guard let directory = centralDirectory(in: data) else {
            throw DomainError.importFailed("No se pudo abrir el archivo .xlsx")
        }
        var files: [String: Data] = [:]
        files.reserveCapacity(directory.count)
        for entry in directory {
            files[entry.name] = try contents(of: entry, in: data)
        }
        return files
    }

    // MARK: - Directorio central

    private struct Entry {
        let name: String
        let method: UInt16
        let compressedSize: Int
        let uncompressedSize: Int
        let localHeaderOffset: Int
    }

    private static func centralDirectory(in data: Data) -> [Entry]? {
        guard let eocd = endOfCentralDirectory(in: data) else { return nil }
        let count = Int(readUInt16(data, eocd + 10))
        var offset = Int(readUInt32(data, eocd + 16))
        var entries: [Entry] = []
        entries.reserveCapacity(count)
        for _ in 0..<count {
            guard offset + 46 <= data.count, readUInt32(data, offset) == 0x0201_4B50 else {
                return nil
            }
            let method = readUInt16(data, offset + 10)
            let compressed = Int(readUInt32(data, offset + 20))
            let uncompressed = Int(readUInt32(data, offset + 24))
            let nameLength = Int(readUInt16(data, offset + 28))
            let extraLength = Int(readUInt16(data, offset + 30))
            let commentLength = Int(readUInt16(data, offset + 32))
            let localOffset = Int(readUInt32(data, offset + 42))
            let nameStart = offset + 46
            guard nameStart + nameLength <= data.count else { return nil }
            let nameData = data.subdata(in: nameStart..<(nameStart + nameLength))
            let name = String(data: nameData, encoding: .utf8)
                ?? String(data: nameData, encoding: .isoLatin1)
                ?? ""
            entries.append(
                Entry(
                    name: name,
                    method: method,
                    compressedSize: compressed,
                    uncompressedSize: uncompressed,
                    localHeaderOffset: localOffset
                )
            )
            offset = nameStart + nameLength + extraLength + commentLength
        }
        return entries
    }

    private static func endOfCentralDirectory(in data: Data) -> Int? {
        let signature: [UInt8] = [0x50, 0x4B, 0x05, 0x06]
        let minimum = 22
        guard data.count >= minimum else { return nil }
        let start = max(0, data.count - 65_557)
        var index = data.count - minimum
        while index >= start {
            if data[index] == signature[0],
               data[index + 1] == signature[1],
               data[index + 2] == signature[2],
               data[index + 3] == signature[3] {
                return index
            }
            index -= 1
        }
        return nil
    }

    private static func contents(of entry: Entry, in data: Data) throws -> Data {
        let header = entry.localHeaderOffset
        guard header + 30 <= data.count, readUInt32(data, header) == 0x0403_4B50 else {
            throw DomainError.importFailed("No se pudo leer el contenido del .xlsx")
        }
        let nameLength = Int(readUInt16(data, header + 26))
        let extraLength = Int(readUInt16(data, header + 28))
        let dataStart = header + 30 + nameLength + extraLength
        let dataEnd = dataStart + entry.compressedSize
        guard dataEnd <= data.count else {
            throw DomainError.importFailed("No se pudo leer el contenido del .xlsx")
        }
        let payload = data.subdata(in: dataStart..<dataEnd)
        switch entry.method {
        case 0:
            return payload
        case 8:
            return try inflate(payload, uncompressedSize: entry.uncompressedSize)
        default:
            throw DomainError.importFailed("No se pudo leer el contenido del .xlsx")
        }
    }

    private static func inflate(_ input: Data, uncompressedSize: Int) throws -> Data {
        guard uncompressedSize > 0 else { return Data() }
        var output = Data(count: uncompressedSize)
        let decoded = output.withUnsafeMutableBytes { outRaw -> Int in
            input.withUnsafeBytes { inRaw -> Int in
                guard let outBase = outRaw.bindMemory(to: UInt8.self).baseAddress,
                      let inBase = inRaw.bindMemory(to: UInt8.self).baseAddress else {
                    return 0
                }
                return compression_decode_buffer(
                    outBase,
                    uncompressedSize,
                    inBase,
                    input.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }
        guard decoded > 0 else {
            throw DomainError.importFailed("No se pudo leer el contenido del .xlsx")
        }
        if decoded < output.count {
            output.count = decoded
        }
        return output
    }

    private static func readUInt16(_ data: Data, _ offset: Int) -> UInt16 {
        UInt16(data[offset]) | UInt16(data[offset + 1]) << 8
    }

    private static func readUInt32(_ data: Data, _ offset: Int) -> UInt32 {
        UInt32(data[offset])
            | UInt32(data[offset + 1]) << 8
            | UInt32(data[offset + 2]) << 16
            | UInt32(data[offset + 3]) << 24
    }
}
