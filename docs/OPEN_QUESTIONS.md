# Preguntas abiertas

Cosas que el producto o la técnica no definen y que **no se inventan**. Cada una con contexto y una opción provisional si bloquea el avance.

## Q-001 — Documentos de producto — RESUELTA
- **Contexto**: `AGENTS.md` y `docs/ARCHITECTURE.md` referencian `docs/PRODUCT.md`, `docs/DOMAIN.md` y `docs/PARSER.md` (pantallas S1–S11, vectores de cálculo, fixtures del parser).
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

