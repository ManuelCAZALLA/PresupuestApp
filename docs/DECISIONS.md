# Decisiones (ADR)

Formato: cada decisión lleva fecha, estado y motivo. Una decisión nueva se añade al final; no se reescribe el pasado.

---

## D-001 — Nombre provisional del proyecto
- **Fecha**: 2026-10-10
- **Estado**: aceptada
- **Decisión**: el proyecto se llama `PresupuestApp` (carpeta, esquema y target). Nombre de producto visible pendiente de confirmar.
- **Motivo**: es descriptivo y agrupa el objetivo (presupuestos para oficios). El nombre comercial se decidirá antes de publicar.
- **Consecuencia**: el bundle identifier es `com.manuelcazalla.PresupuestApp`; no se cambia sin acuerdo explícito.

## D-002 — Estructura Clean Architecture + MVVM
- **Fecha**: 2026-10-10
- **Estado**: aceptada
- **Decisión**: `Packages/QuoteCore` (dominio, solo Foundation) + `App/{Composition,Data,Presentation,Resources}`, con la regla `Presentation → QuoteCore ← Data`.
- **Motivo**: aislar el dominio de los frameworks permite que el motor se pruebe con `swift test` y que el compilador impida saltarse capas.
- **Consecuencia**: `QuoteCore` no importa SwiftUI, SwiftData, UIKit, PDFKit ni Speech. El `reviewer` bloquea cualquier import que lo rompa.

## D-003 — Tests de QuoteCore con Swift Testing
- **Fecha**: 2026-10-10
- **Estado**: aceptada
- **Decisión**: los tests de `Packages/QuoteCore` usan **Swift Testing** (`import Testing`, `@Test`, `#expect`), incluidos en el toolchain (Swift 6.4). El modo lenguaje es Swift 6 tanto en el paquete (`swift-tools-version: 6.0`) como en el target de la app (`SWIFT_VERSION = 6.0`).
- **Motivo**: es el marco moderno de Apple y viene con el toolchain; evita dependencias externas.
- **Consecuencia**: el test de humo de M0 y, desde M1, los vectores de `DOMAIN.md` se escriben con Swift Testing.

## D-004 — Proyecto Xcode con grupos sincronizados
- **Fecha**: 2026-10-10
- **Estado**: aceptada
- **Decisión**: el target de la app usa un *file system synchronized group* sobre `App/`, de modo que los archivos nuevos aparecen en el target sin editar el `.xcodeproj` a mano.
- **Motivo**: evita conflictos al añadir archivos y mantiene el proyecto legible.
- **Consecuencia**: los archivos de la app viven en `App/`; no se añaden a mano al proyecto.

## D-005 — Sin dependencias externas en M0
- **Fecha**: 2026-10-10
- **Estado**: aceptada
- **Decisión**: M0 no añade ninguna dependencia de terceros; solo el paquete local `Packages/QuoteCore`.
- **Motivo**: `AGENTS.md` prohíbe dependencias al empezar; la primera admitida (lector `.xlsx`) llega en M4.
- **Consecuencia**: si aparece una dependencia nueva, requiere aprobación y una decisión aquí.

## D-006 — Configuración del paquete QuoteCore
- **Fecha**: 2026-10-10
- **Estado**: aceptada
- **Decisión**: `Packages/QuoteCore` usa `swift-tools-version: 6.0`, plataformas mínimas iOS 17 y macOS 14, un target `QuoteCore` (solo Foundation) y un `testTarget` `QuoteCoreTests` con Swift Testing. Sin dependencias externas.
- **Motivo**: iOS 17 es el mínimo exigido por SwiftData y macOS 14 permite compilar y probar el dominio con `swift test` en el Mac; fijar tools-version 6.0 garantiza el modo lenguaje Swift 6 sin sorpresas entre agentes.
- **Consecuencia**: el dominio se verifica con `swift test --package-path Packages/QuoteCore`; cualquier dependencia o cambio de plataforma requiere una decisión nueva.

## D-007 — Sin packs de partidas en el MVP
- **Fecha**: 2026-10-18
- **Estado**: aceptada
- **Decisión**: la app NO incorpora partidas precargadas. El usuario carga su propia tarifa (Excel/CSV, lista pegada o alta manual) y el catálogo arranca vacío. Se elimina la siembra de datos en el arranque y en el onboarding. `BundleTradePackLoader`/`LoadTradePack` se conservan pero quedan sin usar en el MVP. Los sinónimos por oficio se mantienen como un JSON de vocabulario que alimenta el motor de interpretación, no como partidas.
- **Motivo**: los precios y las partidas son del usuario (principio del producto). Un pack precargado introduce partidas sin precio, se duplica al reabrir la app y da una falsa sensación de catálogo listo. La importación de la tarifa real (M4) cubre el caso de uso desde el primer minuto.
- **Consecuencia**: M3 no incluye packs; M4 se ejecuta justo después de M3 y antes de M5. Los packs por oficio pasan a mejora opcional futura. El repositorio de partidas hace upsert por nombre normalizado (`Item.nameKey`) para que importar no duplique.

## D-008 — Lectura y mapeo de la tarifa importada (M4)
- **Fecha**: 2026-10-18
- **Estado**: aceptada
- **Decisión**: el flujo de importación (S8) separa **lectura** (Data) y **mapeo/interpretación** (dominio).
  - **Lectura** (`App/Data/Import`): `CSVReader`, `XLSXReader`, `PastedTextParser` devuelven una tabla cruda `RawTable { name, rows: [[String]] }`. CSV: probar UTF-8 y, si falla, Windows-1252; separador `,` o `;` detectado por frecuencia en la primera línea; comillas respetadas (una coma entre comillas no separa columnas). XLSX: valores, no fórmulas; se listan las hojas y la persona elige.
  - **Mapeo** (`Packages/QuoteCore/Sources/QuoteCore/Import/`): `ColumnMapper` detecta la fila de cabecera (la primera con al menos 2 celdas de cabecera reconocibles) y sugiere columnas; aplica un `ColumnMapping` ya revisado por el usuario y produce `ImportResult { rows, warnings }`.
  - **Casos de uso**: `ImportTariff` aplica las filas revisadas al catálogo. Modos `updateExisting` (por defecto) y `addOnlyNew`, emparejando por `Item.nameKey`.
  - **Cabeceras reconocibles** (subcadena, sin tildes ni mayúsculas): español `concepto`, `descripción`/`descripciones`, `nombre`, `artículo`, `unidad`, `ud`, `medida`, `precio`, `pvp`, `importe`, `coste`, `tarifa`, `categoría`, `familia`, `grupo`, `sección`; inglés `name`, `description`, `unit`, `price`, `category`. Se añaden los sinónimos ingleses porque un archivo de ejemplo real (`Tests/ImportSamples/tarifa_coma_utf8.csv`) trae cabeceras `name,unit,price`.
  - **Filas que se saltan sin aviso**: las anteriores a la cabecera, las vacías, y las de texto sin precio **ni** unidad (títulos de categoría, notas). Una fila con unidad pero sin precio sí es partida, con aviso `sinPrecio` y precio 0.
  - **Precio**: se aceptan `25`, `25,5`, `25.50`, `1.234,50`, `25 €`, `25€/ud`. Un único punto con exactamente 3 decimales (`1.234`) es ambiguo: se interpreta como miles (1234) con aviso `precioAmbiguo` y confirmación en la revisión. Un valor no numérico es `precioInvalido`. Un precio en texto libre **sin** símbolo de moneda se acepta con aviso suave `precioSinMoneda`. En columnas estructuradas (CSV/XLSX) la ausencia de símbolo es normal y no avisa.
  - **Unidad**: `ud`, `u`, `unidad`, `ud.` → `.unit`; `m`, `ml`, `metro` → `.meter`; `m2`, `m²` → `.squareMeter`; `h`, `hora` → `.hour`; `global`, `pa` → `.lumpSum`. Sin unidad → `.unit` sin aviso; unidad presente y desconocida → `.unit` con aviso `unidadDesconocida`.
  - **IVA incluido**: `netPrice = round4(precio / (1 + tipo))` con `RoundingPolicy.netPrice`. La columna del precio guarda el precio neto.
- **Motivo**: mantener el dominio (mapeo, avisos, IA del emparejamiento) probado con `swift test` y separado de la E/S de archivos; y no inventar precios ni decisiones de formato.
- **Consecuencia**: `App/Data/Import` no decide mapeo ni avisos; `QuoteCore/Import` no lee archivos. `ImportResult` nunca lanza excepción por datos mal formados: devuelve filas y avisos.

## D-009 — Lector `.xlsx`: CoreXLSX
- **Fecha**: 2026-10-18
- **Estado**: aceptada
- **Decisión**: se añade una única dependencia externa, **CoreXLSX** (`https://github.com/CoreOffice/CoreXLSX.git`, última versión publicada **0.14.2**, del 13/03/2023), usada solo por `App/Data/Import/XLSXReader`. Se integra como *package* remoto del proyecto Xcode (no en `Packages/QuoteCore`).
- **Motivo**: `AGENTS.md` y `docs/ARCHITECTURE.md` admiten un lector `.xlsx` en M4. CoreXLSX es solo lectura, sin dependencias pesadas (arrastra `XMLCoder` y `ZIPFoundation`), y declara iOS 9+ / macOS 10.11+, por lo que cubre iOS 17 y el Swift del proyecto (6.4). Su última versión es de 2023, con mantenimiento lento pero activo (compatible con Swift 6.x en Swift Package Index); no se encontró alternativa claramente mejor para leer valores de `.xlsx` sin escribir un descompresor propio.
- **Consecuencia**: `QuoteCore` sigue siendo solo Foundation. Cualquier otra dependencia requiere una decisión nueva.

## D-010 — Puerto de importación y target de tests `AppTests` (M4)
- **Fecha**: 2026-10-18
- **Estado**: aceptada
- **Decisión**:
  - La lectura de la tarifa se expone con dos puertos en `Packages/QuoteCore/Sources/QuoteCore/Ports/TariffFileLoading.swift`: `TariffImportSource` (`tables(from:)`, `plainText(from:)`, `parsePastedText(_:options:)`) y `TariffTemplateProviding` (`temporaryTemplateURL()`). Data los implementa con `LocalTariffSource` y `FileTariffTemplateProvider`; el ViewModel de S8 solo ve `RawTable`/`ImportResult`.
  - La app añade un target de tests unitarios `AppTests` al `PresupuestApp.xcodeproj` (producto `AppTests.xctest`, host la app, `SWIFT_VERSION = 6.0`), con CoreXLSX como *package* remoto compartido por app y tests. Los archivos de ejemplo y `expected_imports.json` (oráculo) siguen en `Tests/ImportSamples`, sin editar.
  - Los tipos `UTType` que acepta el selector de archivos se declaran en Data (`ImportFileTypes.allowed`), de modo que Presentation no importa `UniformTypeIdentifiers`.
  - `MeasureUnit` pasa a ser `CaseIterable` para poblar el selector de unidad.
- **Motivo**: la verificación de los lectores (CSV/CP1252/XLSX) y del oráculo necesita ejecutarse contra el código real de `App/Data`, que no es un paquete Swift; un target de tests del proyecto es la forma estándar de hacerlo con `xcodebuild test`. Los puertos evitan que Presentation dependa de Data.
- **Consecuencia**: los tests de Data/lectores se ejecutan con `xcodebuild test` (esquema `PresupuestApp`); los del dominio, con `swift test --package-path Packages/QuoteCore`. `Tests/AppTests/.gitkeep` se elimina porque el grupo sincronizado ya contiene fuentes.
