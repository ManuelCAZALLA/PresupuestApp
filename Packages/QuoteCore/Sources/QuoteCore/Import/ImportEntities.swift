import Foundation

/// Tabla cruda (filas × columnas) leída de un archivo o del texto pegado,
/// antes de interpretarla. La produce la capa Data; el dominio la consume.
/// `name` es el nombre de la hoja o del archivo, solo informativo.
public struct RawTable: Equatable, Sendable {
    public let name: String?
    public let rows: [[String]]

    public init(name: String? = nil, rows: [[String]]) {
        self.name = name
        self.rows = rows
    }
}

/// Columnas elegidas por el usuario sobre una `RawTable`.
/// Los índices son 0-based (la columna A es 0).
public struct ColumnMapping: Equatable, Sendable {
    public var name: Int
    public var price: Int?
    public var unit: Int?
    public var category: Int?
    /// Columna opcional con el tipo de IVA de cada fila (ver D-012).
    public var vatRate: Int?

    public init(
        name: Int,
        price: Int? = nil,
        unit: Int? = nil,
        category: Int? = nil,
        vatRate: Int? = nil
    ) {
        self.name = name
        self.price = price
        self.unit = unit
        self.category = category
        self.vatRate = vatRate
    }
}

/// Sugerencia de mapeo a partir de una cabecera, para prellenar la pantalla.
/// `headerRow` es 0-based (la fila 1 del archivo es 0).
public struct ColumnSuggestion: Equatable, Sendable {
    public var headerRow: Int?
    public var name: Int?
    public var price: Int?
    public var unit: Int?
    public var category: Int?
    public var vatRate: Int?

    public init(
        headerRow: Int? = nil,
        name: Int? = nil,
        price: Int? = nil,
        unit: Int? = nil,
        category: Int? = nil,
        vatRate: Int? = nil
    ) {
        self.headerRow = headerRow
        self.name = name
        self.price = price
        self.unit = unit
        self.category = category
        self.vatRate = vatRate
    }
}

/// Aviso de una fila importada. Nunca interrumpe: la fila se importa igual y
/// la pantalla de revisión la enseña para que el usuario decida.
public enum ImportWarning: Equatable, Sendable {
    /// Partida sin precio en el archivo: se importa con precio 0.
    case sinPrecio(name: String)
    /// El precio no se pudo interpretar como número.
    case precioInvalido(name: String, raw: String)
    /// La unidad no se reconoció: se usa `ud`.
    case unidadDesconocida(name: String, raw: String)
    /// Ya aparecía otra fila con el mismo nombre normalizado en el archivo.
    case duplicado(name: String)
    /// El precio es ambiguo (p. ej. `1.234`): confirmar en la revisión.
    case precioAmbiguo(name: String, raw: String)
    /// Precio en texto libre sin símbolo de moneda: se acepta con aviso suave.
    case precioSinMoneda(name: String)
    /// La celda de la columna IVA no se pudo interpretar como tipo.
    case vatInvalido(name: String, raw: String)

    /// Nombre de la fila a la que se refiere el aviso.
    public var rowName: String {
        switch self {
        case .sinPrecio(let name): return name
        case .precioInvalido(let name, _): return name
        case .unidadDesconocida(let name, _): return name
        case .duplicado(let name): return name
        case .precioAmbiguo(let name, _): return name
        case .precioSinMoneda(let name): return name
        case .vatInvalido(let name, _): return name
        }
    }

    /// Identificador estable usado en pruebas y en la interfaz.
    public var type: String {
        switch self {
        case .sinPrecio: return "sinPrecio"
        case .precioInvalido: return "precioInvalido"
        case .unidadDesconocida: return "unidadDesconocida"
        case .duplicado: return "duplicado"
        case .precioAmbiguo: return "precioAmbiguo"
        case .precioSinMoneda: return "precioSinMoneda"
        case .vatInvalido: return "vatInvalido"
        }
    }
}

/// Una partida detectada, todavía sin guardar. Guarda el precio NETO (sin IVA)
/// ya convertido con `RoundingPolicy.netPrice` cuando el archivo traía el IVA.
public struct ImportedRow: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var unit: MeasureUnit
    public var netPrice: Decimal
    /// Tipo de IVA propio de la fila, en por ciento. `nil` cuando el archivo
    /// no traía columna IVA o la celda estaba vacía: la partida hereda el IVA
    /// por defecto (docs/DOMAIN.md, "IVA por partida").
    public var vatRate: Decimal?
    public var kind: ItemKind
    public var category: String?
    public var warnings: [ImportWarning]

    public init(
        id: UUID = UUID(),
        name: String,
        unit: MeasureUnit = .unit,
        netPrice: Decimal = Decimal(0),
        vatRate: Decimal? = nil,
        kind: ItemKind = .other,
        category: String? = nil,
        warnings: [ImportWarning] = []
    ) {
        self.id = id
        self.name = name
        self.unit = unit
        self.netPrice = netPrice
        self.vatRate = vatRate
        self.kind = kind
        self.category = category
        self.warnings = warnings
    }

    /// La partida de catálogo que representa esta fila.
    public func item(trade: Trade = .other) -> Item {
        Item(
            name: name,
            unit: unit,
            unitPrice: netPrice,
            vatRate: vatRate,
            kind: kind,
            category: category,
            trade: trade
        )
    }
}

/// Resultado de interpretar un archivo: las filas detectadas y los avisos
/// agregados (que son la unión de los avisos de cada fila).
public struct ImportResult: Equatable, Sendable {
    public let rows: [ImportedRow]

    public init(rows: [ImportedRow]) {
        self.rows = rows
    }

    public var warnings: [ImportWarning] {
        rows.flatMap(\.warnings)
    }
}

/// Cómo aplicar las filas al catálogo cuando el usuario confirma.
public enum ImportMode: Equatable, Sendable {
    /// Actualiza la partida existente del mismo nombre y crea las que falten.
    case updateExisting
    /// Solo crea partidas nuevas; si ya existe una del mismo nombre, la salta.
    case addOnlyNew
}
