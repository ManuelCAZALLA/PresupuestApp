# Hoja de ruta Android

Aplicación Android nativa en Kotlin y Jetpack Compose, sin conexión y con persistencia solo en el dispositivo. La lógica fiscal se contrasta con los vectores Swift mediante una fixture común.

## [x] A0 — Base y cálculo
- Proyecto Gradle con módulos `app` y `domain`.
- `QuoteCalculator` en Kotlin con `BigDecimal` y redondeo HALF_UP.
- Fixture compartida en `Packages/QuoteCore/Tests/QuoteCoreTests/Fixtures/quote_calculator_vectors.tsv`.
- App Compose nativa compilable; pruebas del dominio ejecutables.

## [~] A1 — Perfil y catálogo
- Room guarda partidas sin datos sembrados ni copias automáticas.
- Tarifa vacía con alta manual y borrado de partidas.
- Pendiente: perfil del negocio, onboarding, edición y pruebas Room.

## [~] A2 — Presupuestos
- Lista y alta de borradores con partidas snapshot del catálogo, cantidades, descuento porcentual e IVA por línea.
- Total calculado en dominio y persistido localmente.
- Pendiente: edición, descuento fijo, gestión completa de líneas y pruebas de casos de uso/ViewModels.

## [~] A3 — PDF y compartir
- Generación local de PDF con descripción/cantidad, subtotal, descuento, bases por IVA, cuota y total; hoja del sistema para compartir.
- Pendiente: perfil/estilo profesional, vista previa, guardar y revisión visual en emulador.

## [ ] A4 — Importar tarifa
- CSV, XLSX, PDF con texto y texto pegado con revisión antes de guardar.
- Reutilizar los formatos y reglas de importación descritos en `docs/PRODUCT.md` y `docs/DOMAIN.md`.

## [ ] A5 — Paridad y publicación
- Pasada de accesibilidad, privacidad, tamaños de pantalla y errores de archivos.
- Confirmar Q-010, firma, versionado, capturas y metadatos de Play Store.
