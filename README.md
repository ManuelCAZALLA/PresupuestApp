# PresupuestApp

App para profesionales de oficios: carga tu tarifa de precios, describe un trabajo y obtén un presupuesto en PDF con tus propios precios. Sin IA y sin conexión.

Estado: hito **M0** (arranque). Ver `docs/ROADMAP.md`.

## Estructura
- `Packages/QuoteCore` — dominio puro (solo Foundation) y motor de interpretación. Tests: `swift test --package-path Packages/QuoteCore`.
- `App/` — app SwiftUI: `Composition` (inyección), `Data` (SwiftData, import, voz, PDF), `Presentation` (vistas y ViewModels), `Resources` (textos, assets).
- `PresupuestApp.xcodeproj` — proyecto de la app.
- `docs/` — producto, arquitectura, dominio, hoja de ruta y decisiones.

## Tests del dominio
```
swift test --package-path Packages/QuoteCore
```

## Arrancar la app
Abre `PresupuestApp.xcodeproj` en Xcode y ejecuta en un simulador de iOS 17 o superior.
