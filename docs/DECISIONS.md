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

## D-011 — IVA por partida (M4b)
- **Fecha**: 2026-10-18
- **Estado**: aceptada
- **Decisión**: `Item` gana un campo opcional `vatRate: Decimal?`. El IVA de una línea de presupuesto es el de la partida si la tiene; si es `nil`, el `Quote.defaultVATRate` (procedente del `BusinessProfile.defaultVATRate`). El tipo se copia a la línea al añadirla: al igual que nombre, unidad y precio, es un snapshot inmutable de la línea.
- **Motivo**: en oficios reales conviven tipos distintos en la misma tarifa (mano de obra al 21 %, libros o determinados servicios a otro tipo, exentos). Exigir que el usuario corrija el IVA línea a línea en cada presupuesto sería lento y propenso a errores; heredarlo del presupuesto por defecto mantiene el caso común en un toque.
- **Consecuencia**: `ItemRecord` necesita el campo y una migración de esquema ligera (v1 → v2). `QuoteCalculator` no cambia: ya agrupa por `line.vatRate`. Los casos de uso de líneas (`AddLine`, `UpdateLineQuantity`, `RemoveLine`) son los que resuelven `item.vatRate ?? quote.defaultVATRate`; las vistas no deciden IVA.

## D-012 — Columna `IVA` opcional en la importación (M4b)
- **Fecha**: 2026-10-18
- **Estado**: aceptada
- **Decisión**: `ColumnMapping` y `ColumnSuggestion` ganan una columna opcional `vatRate` además del interruptor global "los precios incluyen IVA". Formato aceptado en la celda: `21`, `21%`, `0,21`, `10` → 21, 21, 21 y 10 (porcentaje normalizado a `Decimal`). La columna manda sobre el interruptor para decidir el tipo con el que se convierte el precio de esa fila; fila vacía o ilegible → tipo del interruptor y, en el segundo caso, aviso de revisión.
- **Motivo**: una tarifa real trae filas con tipos distintos (y a veces precios ya con IVA solo en algunas). El interruptor global es suficiente para el caso simple, pero no puede ser la única vía sin forzar al usuario a partir el archivo.
- **Consecuencia**: el parser de IVA vive en `QuoteCore/Import` (probado con `swift test`); `Tests/ImportSamples` recibe un archivo nuevo con columna `IVA` y su resultado esperado, sin tocar los existentes.

## D-013 — Navegación M4b: pestañas tras el onboarding (M4b)
- **Fecha**: 2026-10-18
- **Estado**: aceptada
- **Decisión**: la app usa un `TabView` con tres pestañas —**Presupuestos**, **Precios** y **Ajustes**— en lugar de la `HomeView` de botones. Cada pestaña lleva su propio `NavigationStack`. Si no hay perfil de negocio guardado, se abre `Onboarding` (S1) a pantalla completa y las pestañas aparecen al completarlo; S8 (`ImportTariff`) se presenta como hoja desde Precios y también por "Abrir con".
- **Motivo**: PRODUCT.md exige que el recorrido onboarding → tarifa → presupuesto → PDF se haga en menos de 3 minutos con una mano. Una pantalla intermedia de botones añade un paso inútil y esconde el estado real de la app (catálogo vacío, presupuestos pendientes).
- **Consecuencia**: `HomeView` se retira; `AppRoute` pasa a ser el camino empujado dentro de cada pestaña. La marca de agua del plan gratuito se implementa ya en `QuotePDFRenderer` con el `EntitlementProvider` actual (stub), y M7 solo conecta el plan real.

## D-014 — Esquema SwiftData v2 con migración en ligero (M4b)
- **Fecha**: 2026-10-18
- **Estado**: aceptada
- **Decisión**: el esquema actual pasa a ser `PresupuestAppSchema` (**v2.0.0**), que añade `ItemRecord.vatRate`, y se declara `PresupuestAppSchemaV1` (**v1.0.0**) describiendo el modelo anterior: la misma entidad `ItemRecord` (mismo nombre de entidad, para que la migración altere la tabla en el sitio) sin ese atributo. `PresupuestAppMigrationPlan` los une con una única etapa `.lightweight(fromVersion:toVersion:)` y es el plan con el que se crea el `ModelContainer`.
- **Motivo**: la app ya se ha ejecutado en dispositivos y simuladores con el esquema v1 (M4); añadir un atributo sin plan de migración puede impedir abrir el almacén existente o dejar los datos atrás. El cambio es un atributo **opcional**, así que la migración en ligero basta y no hace falta una etapa personalizada.
- **Consecuencia**: `PersistenceSetup.makeModelContainer(at:)` abre un almacén en una ruta concreta y lo usan las pruebas de migración (`Tests/AppTests/SchemaMigrationTests.swift`), que crean un almacén v1 real, lo reabren con el esquema actual y comprueban que las partidas siguen ahí con `vatRate` nulo. A partir de aquí el esquema se versiona antes de publicar: cualquier cambio añade una versión nueva y su etapa.

## D-015 — Errores de dominio explícitos para presupuesto, línea y partida (M4b)
- **Fecha**: 2026-10-18
- **Estado**: aceptada
- **Decisión**: `DomainError.lineNotFound` se parte en tres casos: `quoteNotFound`, `lineNotFound` e `itemNotFound`. Los casos de uso lanzan el que corresponde (presupuesto que no existe ≠ línea que no existe ≠ partida que no existe) y `AppErrorMapper` traduce cada uno a su clave de texto.
- **Motivo**: los casos de uso de líneas nuevos (M4b) y `LoadQuote` compartían un único error para situaciones distintas; el usuario habría visto "No se encontró esa línea en el presupuesto" cuando el problema era otro. Ante la duda, la app pregunta o dice la verdad; nunca elige en silencio.
- **Consecuencia**: los tests de `QuoteCore` fijan ahora el error concreto de cada caso (incluido `itemNotFound` al añadir una partida que ya no está en el catálogo); `AppErrorMapper` gana `error.quoteNotFound` y `error.itemNotFound` en `Localizable.xcstrings`.

## D-016 — Onboarding en cinco pasos con bandera de finalización (S1)
- **Fecha**: 2026-10-20
- **Estado**: aceptada
- **Decisión**: S1 pasa a ser un recorrido de cinco pasos: un carrusel de tres (con "Saltar" que lleva al paso 4 y un indicador de página), los datos del negocio con el IVA por defecto (21 % preseleccionado, 10 % y "Otro") y el catálogo vacío como último paso. El carrusel se reutiliza tal cual desde Ajustes con "Cómo funciona". El onboarding no vuelve a mostrarse: `AppSession` guarda la bandera `hasCompletedOnboarding` en el `UserDefaults` que le inyecta la raíz de composición, y también da por terminado el onboarding a quien ya tiene perfil de negocio.
- **Motivo**: con los packs retirados (D-007) el oficio no aportaba nada y era el único motivo de un formulario largo en la primera pantalla. El carrusel explica en veinte segundos para qué sirve la app y qué no hace (no inventa precios, no usa la red) antes de pedir un solo dato; terminar en el catálogo vacío convierte la explicación en la primera acción real. La bandera separa "ya lo ha visto" de "tiene perfil", que hasta ahora era lo mismo.
- **Consecuencia**: `OnboardingViewModel` tiene dos modos, `onboarding` y `walkthrough`, y el segundo nunca marca la bandera. El guardado sigue usando `SaveBusinessProfile`: el onboarding no toca el dominio ni el esquema de datos (el logo se guarda en el campo `logo` que ya existía). Las ilustraciones del carrusel son formas de SwiftUI (sin imágenes externas, sin librerías) y respetan "Reducir movimiento"; los textos viven en `Localizable.xcstrings`. Con "Otro" elegido y un tipo ilegible se avisa en ámbar y se guarda el 21 %: el aviso es visible, no una elección en silencio.
