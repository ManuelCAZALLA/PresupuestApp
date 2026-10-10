# Preguntas abiertas

Cosas que el producto o la técnica no definen y que **no se inventan**. Cada una con contexto y una opción provisional si bloquea el avance.

## Q-001 — Documentos de producto no disponibles
- **Contexto**: `AGENTS.md` y `docs/ARCHITECTURE.md` referencian `docs/PRODUCT.md`, `docs/DOMAIN.md` y `docs/PARSER.md` (pantallas S1–S11, vectores de cálculo, fixtures del parser). Al arrancar este proyecto nuevo no se han aportado esos documentos.
- **Bloquea**: no a M0. Sí a M1 (vectores de `DOMAIN.md`) y M2 (fixtures del parser).
- **Propuesta**: aportarlos antes de empezar M1.

## Q-002 — Nombre comercial y bundle identifier definitivos
- **Contexto**: `PresupuestApp` es provisional (D-001).
- **Bloquea**: no a M0. Sí a la publicación (M7).
- **Propuesta**: confirmar el nombre comercial antes de crear el App ID definitivo en el portal.

## Q-003 — Firma y equipo de desarrollo
- **Contexto**: M0 compila en simulador sin firma. Para dispositivo y TestFlight hará falta un equipo y un certificado.
- **Bloquea**: no a M0.
- **Propuesta**: configurar el *Team* en Xcode cuando se pruebe en dispositivo físico.
