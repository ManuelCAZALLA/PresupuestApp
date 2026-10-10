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
- Packs por oficio (JSON sin precios) + `LoadTradePack`.
- Features `Onboarding` (S1), `Catalog` (S7), `Settings` (S10).
**Hecho cuando**: se puede elegir oficio, cargar el pack, poner precios y cerrar/abrir la app sin perder nada.
**Paralelismo**: puede ir a la vez que M2 (carpetas distintas).

## [ ] M4 — Importar tarifa
**Dueños**: data_engineer + ui_engineer.
- Lectores CSV y XLSX, pegar texto, asignación de columnas, IVA incluido/no incluido.
- Feature `ImportTariff` (S8) con pantalla de revisión.
**Hecho cuando**: una tarifa real de ejemplo (Excel y CSV) se importa y revisa en menos de 2 minutos.

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
OCR de fotos y PDF, Android, IA opcional como función Pro, facturación.
