# Preguntas abiertas

Cosas que el producto o la técnica no definen y que **no se inventan**. Cada una con contexto y una opción provisional si bloquea el avance.

## Q-001 — Documentos de producto — RESUELTA
- **Contexto**: `AGENTS.md` y `docs/ARCHITECTURE.md` referencian `docs/PRODUCT.md`, `docs/DOMAIN.md` y `docs/PARSER.md` (pantallas S1–S12, vectores de cálculo, fixtures del parser).
- **Estado**: resuelta el 2026-10-10; los tres documentos ya están en `docs/`. M1 y M3 pueden empezar.

## Q-002 — Nombre comercial y bundle identifier definitivos
- **Contexto**: `PresupuestApp` es provisional (D-001).
- **Bloquea**: no a M0. Sí a la publicación (M7).
- **Propuesta**: confirmar el nombre comercial antes de crear el App ID definitivo en el portal.

## Q-003 — Firma y equipo de desarrollo
- **Contexto**: M0 compila en simulador sin firma. Para dispositivo y TestFlight hará falta un equipo y un certificado.
- **Bloquea**: no a M0.
- **Propuesta**: configurar el *Team* en Xcode cuando se pruebe en dispositivo físico.

## Q-004 — Desktop gestionado por iCloud rompe la firma de los tests
- **Contexto**: el repo vive en `~/Desktop`, que en este Mac está gestionado por iCloud. `swift test` falla al firmar el `.xctest` (`resource fork, Finder information, or similar detritus not allowed`). Se resuelve apuntando `.build` a `~/Library/Caches/PresupuestApp/QuoteCore-build` (ver `docs/KICKOFF.md`, sección 4).
- **Bloquea**: no, con el enlace funciona.
- **Propuesta**: mover el repo a una carpeta fuera de iCloud (p. ej. `~/Developer`) cuando se pueda; entonces `.build` normal ya sirve.

## Q-005 — Pie de aceptación del PDF
- **Contexto**: la skill `quote-pdf-export` pide, como punto 7 del contenido obligatorio, un pie con el texto de aceptación "si se define en ajustes". Hoy no está definido en ninguna parte: `PRODUCT.md` (criterio de S6) pide "logo, datos, líneas, IVA, condiciones y validez", y `Ajustes` (S10) solo tiene `BusinessProfile.terms` ("Condiciones"), que el PDF ya imprime bajo ese título. El footer no se dibuja, siguiendo la regla de no inventar contenido.
- **Bloquea**: no a M4b: el PDF cumple el criterio de `PRODUCT.md` y el resto de la skill.
- **Propuesta**: decidir si el texto de aceptación reutiliza `terms` o es un campo nuevo en Ajustes (`BusinessProfile.acceptanceText`); la segunda opción añade esquema v3 y su etapa de migración. Encaja en M6 (PDF y envío).

## Q-006 — Congelar el esquema SwiftData antes de TestFlight
- **Contexto**: el test que crea un almacén v1 y lo abre con el plan actual falla con `unknownDataStoreSchema`. Las definiciones históricas comparten algunos modelos `@Model` actuales; deben verificarse contra el esquema que realmente se publicó.
- **Bloquea**: validar que las instalaciones anteriores pueden arrancar y conservar sus datos.
- **Tarea**: Antes de TestFlight: fijar el esquema SwiftData definitivo (incluidos los campos del PDF nuevo) y escribir entonces los tests de migración.

## Q-007 — Borrado de presupuestos y cuota mensual
- **Contexto**: `CreateQuote` comprueba la cuota gratuita contando los presupuestos fechados en el mes actual; `DuplicateQuote` no consulta `CheckQuota`. Borrar un presupuesto del mes reduce ese conteo y podría liberar una plaza para crear otro presupuesto.
- **Bloquea**: no a la lista S2 de la v1; no activar ni ampliar la lógica de cuota en esta tarea.
- **Tarea previa a TestFlight**: StubEntitlements usa .free por defecto, así que la app aplica hoy el límite de 5 presupuestos al mes; la 1.0 debe salir sin límite. Dejar el plan por defecto sin límite en una tarea aparte con su test.
- **Propuesta**: antes de activar el límite mensual/Paywall, decidir cómo deben tratarse duplicados y presupuestos borrados para que el conteo no permita eludir la cuota.

## Q-008 — Reutilización del número más alto al borrar
- **Contexto**: la numeración usa el máximo número existente del año más uno. Si se borra el presupuesto con el número más alto, una creación posterior puede reutilizar ese número.
- **Bloquea**: no a S2; no cambiar el algoritmo ni el esquema en esta tarea.
- **Solución prevista**: Al borrar el presupuesto con el número más alto, ese número se reutiliza. Solución prevista: contador persistente por año en el perfil del negocio, al congelar el esquema. No escribir un test que consagre la reutilización.

## Q-009 — ¿Clientes como entidad propia?
- **Contexto**: la pestaña **Clientes** (D-021) agrupa por nombre normalizado los datos que cada presupuesto guarda. Dos clientes distintos con el mismo nombre se fusionan; un presupuesto sin nombre no aparece; y no se puede editar ni fusionar un cliente desde el directorio. Crear un presupuesto desde un cliente reutiliza la copia del presupuesto más reciente.
- **Bloquea**: no a la cuarta pestaña ni a la v1. Sí a una gestión de clientes con edición, fusión o alta antes del primer presupuesto.
- **Propuesta**: mantener el directorio derivado mientras no haya una necesidad real. Si se pide editar/fusionar, añadir `ClientRecord` con identificador estable, relación opcional desde `QuoteRecord` y migración; decidir entonces si los presupuestos antiguos se reescriben o conservan su copia (hoy se conserva).

