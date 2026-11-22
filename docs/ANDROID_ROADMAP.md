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
- Edición de partidas conservando su identificador.
- Perfil local del negocio en Room: nombre, teléfono, NIF, IVA por defecto y finalización del primer acceso; migración de esquema v1→v2.
- El IVA por defecto del perfil se usa al crear presupuestos nuevos.
- Acceso desde la pantalla principal a editar los datos del negocio.
- Carrusel de bienvenida de tres pasos, saltable y reabrible desde la pantalla principal.
- Pendiente: pruebas Room y ViewModel.
- **Estado (2026-11-22)**: perfil básico, onboarding inicial y carrusel implementados; alta, edición y borrado manual del catálogo. Compilación `:app:assembleDebug` correcta.

## [~] A2 — Presupuestos
- Lista, alta y edición de borradores con partidas snapshot del catálogo, cantidades, descuento porcentual o fijo e IVA por línea.
- Total calculado en dominio y persistido localmente.
- Al editar, los precios y datos de las líneas existentes se conservan como snapshot; las partidas nuevas copian los valores actuales de la tarifa.
- Las cantidades se pueden escribir o ajustar con controles de suma/resta; al llegar a cero la partida se quita.
- Pendiente: pruebas de casos de uso/ViewModels.
- **Estado (2026-11-22)**: edición de borradores y líneas, cantidades y descuentos porcentuales/fijos implementados. Compilación `:app:assembleDebug` correcta.

## [~] A3 — PDF y compartir
- Generación local de PDF con descripción/cantidad, subtotal, descuento, bases por IVA, cuota y total; hoja del sistema para compartir.
- Pendiente: perfil/estilo profesional, vista previa, guardar y revisión visual en emulador.

## [ ] A4 — Importar tarifa
- CSV, XLSX, PDF con texto y texto pegado con revisión antes de guardar.
- Reutilizar los formatos y reglas de importación descritos en `docs/PRODUCT.md` y `docs/DOMAIN.md`.

## [ ] A5 — Paridad y publicación
- Pasada de accesibilidad, privacidad, tamaños de pantalla y errores de archivos.
- Confirmar Q-010, firma, versionado, capturas y metadatos de Play Store.
