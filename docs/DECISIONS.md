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
- **Decisión**: los tests de `Packages/QuoteCore` usan **Swift Testing** (`import Testing`, `@Test`, `#expect`), disponibles en Swift 6.4.
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
