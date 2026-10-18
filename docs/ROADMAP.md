# Hoja de ruta

Un hito = una rama. Al terminar un hito: tests en verde, `reviewer` aprueba, se marca como hecho aquí.
Estado: [ ] pendiente · [~] en curso · [x] hecho.

## [x] M0 — Arranque
**Dueños**: architect (esqueleto) + ui_engineer (composición).
- Proyecto Xcode creado, paquete local `Packages/QuoteCore` enlazado.
- Carpetas según `docs/ARCHITECTURE.md`, vacías pero compilando.
- `AppContainer` vacío, `AppRouter`, `Localizable.xcstrings` con la primera cadena.
- Comando de tests del paquete funcionando: `swift test --package-path Packages/QuoteCore`.
**Hecho cuando**: la app compila y arranca con una pantalla vacía; `swift test` pasa con un test de humo.

## [ ] M1 — Dominio y cálculo
**Dueños**: domain_engineer + qa_engineer.
- Entidades, `QuoteCalculator`, `RoundingPolicy`, `QuoteTotals`.
- Los 6 vectores de `DOMAIN.md` como tests.
- Casos de uso `CreateQuote`, `DuplicateQuote`, `ChangeQuoteStatus`, `CheckQuota` con repositorios falsos.
**Hecho cuando**: vectores en verde; cobertura de cálculo del 100 % de ramas.

## [ ] M2 — Motor de interpretación
**Dueños**: domain_engineer + qa_engineer.
- Normalizador, números en palabras, segmentador, extractor de cantidad, puntuador, decisor.
- `ParserEvaluationTests` con las fixtures de fontanería incluidas.
- Fixtures nuevas para albañilería y electricidad (con PRUEBA en los precios).
**Hecho cuando**: autoPrecision ≥ 98 %, falseAutoRate ≤ 2 %, ambiguousRecall ≥ 90 % en las fixtures.
Es el hito de mayor riesgo: no se pasa a M5 sin cumplirlo.

## [ ] M3 — Persistencia, catálogo y onboarding
**Dueños**: data_engineer + ui_engineer.
- Modelos SwiftData, mappers, repositorios, `AppContainer` real.
- Catálogo 100 % del usuario: sin packs ni siembra de datos al arrancar.
- Repositorio de partidas con upsert por nombre normalizado; catálogo vacío con importar / pegar / añadir a mano.
- Features `Onboarding` (S1), `Catalog` (S7), `Settings` (S10).
**Hecho cuando**: se puede elegir oficio, añadir partidas a mano, poner precios y cerrar/abrir la app sin perder nada, sin datos precargados.
**Paralelismo**: puede ir a la vez que M2 (carpetas distintas).

## [ ] M4 — Importar tarifa
**Dueños**: data_engineer + ui_engineer.
- Lectores CSV y XLSX, pegar texto, asignación de columnas, IVA incluido/no incluido.
- Feature `ImportTariff` (S8) con pantalla de revisión.
- Plantilla Excel descargable (columnas Nombre, Unidad, Precio) para compartir.
**Orden**: M4 se ejecuta justo después de M3 y antes de M5: sin la tarifa del usuario no hay nada que presupuestar.
**Hecho cuando**: una tarifa real de ejemplo (Excel y CSV) se importa y revisa en menos de 2 minutos.
**Estado (2026-10-18)**: implementado. Dominio en `Packages/QuoteCore/Sources/QuoteCore/Import` (39 tests con `swift test`), lectores en `App/Data/Import` y verificación de los 5 archivos de `Tests/ImportSamples` contra `expected_imports.json` en el target `AppTests` (9 tests con `xcodebuild test`). Queda la comprobación manual del flujo en el simulador (ver "Hecho cuando", menos de 2 minutos).

## [~] M4b — Flujo completo sin dictado
**Dueños**: architect + qa_engineer + domain_engineer + data_engineer + ui_engineer.
- Recorrido de punta a punta sin voz: onboarding → importar tarifa → catálogo → presupuesto a mano → PDF → compartir.
- Navegación: `TabView` con pestañas **Presupuestos**, **Precios** y **Ajustes**, que aparecen tras completar el onboarding; sin perfil guardado se abre `Onboarding` (S1) a pantalla completa.
- IVA por partida: `Item.vatRate` opcional; el IVA de una línea es el de la partida o, si no la tiene, el del presupuesto. La importación acepta una columna `IVA` opcional.
- Casos de uso de líneas: `AddLine`, `UpdateLineQuantity`, `RemoveLine`, `UpdateQuote`. El cálculo sigue siendo `QuoteCalculator` (no se duplica).
- Features nuevas: `QuoteList` (S2), presupuesto a mano (cliente, buscador de partidas, líneas con +/−, descuento, total fijo), presupuesto terminado con desglose de IVA y envío (S6) con `QuotePDFRenderer`.
- Sin dictado: `NewQuote` con voz (S3) y `MatchReview` (S4) quedan para M5.
**Hecho cuando**: desde una instalación limpia, onboarding → importar `Tests/ImportSamples/tarifa_desordenada.xlsx` → ver las partidas en Precios → crear un presupuesto con 3 partidas → el total coincide con el de `QuoteCalculator` → generar el PDF → se abre la hoja de compartir. Sin dictado y en menos de 3 minutos.
**Estado (2026-10-18)**: implementado. Dominio en `Packages/QuoteCore` (**63 tests** con `swift test`, 9 suites) y app en `Tests/AppTests` (**24 tests** con `xcodebuild test`, 8 suites): los 6 archivos de `Tests/ImportSamples` contra su oráculo, ViewModels de listado/edición de presupuesto, layout del PDF (IVA mixto, descuento, 25 y 80 líneas, logo y marca de agua) y migración del almacén v1→v2. Comprobado en el simulador (iPhone 18 Pro) con instalación limpia: la app arranca y muestra el onboarding. **Queda la pasada manual con toques** por el recorrido completo (onboarding → importar → Precios → presupuesto de 3 partidas → PDF → hoja de compartir): la automatización no puede pulsar la interfaz sin permisos de accesibilidad. Decisión de esquema en D-014 y semántica de errores en D-015. El pie de aceptación del PDF queda pendiente de decisión de producto (Q-005): hoy `Ajustes` no tiene ese texto.
**Estado (2026-10-18)**: implementado. Dominio: `swift test` con 63 tests en 9 suites (líneas, IVA por partida, columna `IVA`, errores por entidad). App: `xcodebuild test -only-testing:AppTests` con 23 tests en 8 suites (las 6 muestras de `Tests/ImportSamples`, el flujo con los ViewModels, el PDF y la migración v1→v2), sin warnings de compilación. Instalación limpia y arranque comprobados en el simulador iPhone 18 Pro: abre `Onboarding` sin crash. **Pendiente**: el recorrido con toques (importar el archivo, crear el presupuesto de 3 partidas y compartir el PDF) no se puede automatizar desde fuera de la app sin un target de UI tests; queda para revisión manual.

## [ ] M5 — Flujo de presupuesto
**Dueños**: ui_engineer + data_engineer + domain_engineer.
- `SpeechDictationService` (dictado nativo).
- Features `NewQuote` (S3), `MatchReview` (S4), `QuoteEditor` (S5), `Kits` (S9), `QuoteList` (S2).
- Aprendizaje de alias.
**Hecho cuando**: de "nuevo presupuesto" a presupuesto editable en menos de 2 minutos con una tarifa de prueba.

## [ ] M6 — PDF y envío
**Dueños**: data_engineer + ui_engineer.
- `QuotePDFRenderer`, feature `QuotePreview` (S6), compartir por WhatsApp/correo.
**Hecho cuando**: el PDF incluye todo lo de `PRODUCT.md` y se envía desde el selector del sistema.

## [ ] M7 — Límites, Pro y pulido
**Dueños**: ui_engineer + data_engineer.
- `QuotaPolicy`, marca de agua, `Paywall` (S11), adaptador de compras.
- Pasada de accesibilidad, textos, iconos, capturas, metadatos de App Store.
**Hecho cuando**: TestFlight listo para enseñar a fontaneros reales.

## Después del MVP (no tocar antes)
OCR de fotos y PDF, Android, IA opcional como función Pro, facturación, packs de partidas por oficio como mejora opcional (los sinónimos de oficio se mantienen como vocabulario del motor).
