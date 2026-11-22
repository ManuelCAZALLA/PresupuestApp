# PresupuestApp

App para profesionales de oficios: carga tu tarifa de precios, describe un trabajo y obtén un presupuesto en PDF con tus propios precios. Sin IA y sin conexión.

Versión **1.0.1** (marketing) · build **2**. Ver `docs/ROADMAP.md`.

## Estructura
- `Packages/QuoteCore` — dominio puro (solo Foundation), cálculo, importación y puertos. Tests: `swift test --package-path Packages/QuoteCore`.
- `App/` — app SwiftUI: `Composition` (inyección), `Data` (SwiftData, importación, PDF), `Presentation` (vistas y ViewModels), `Resources` (textos, assets).
- `PresupuestApp.xcodeproj` — proyecto de la app.
- `Android/` — app nativa Kotlin/Compose; dominio puro con vectores compartidos de cálculo.
- `docs/` — producto, arquitectura, dominio, hoja de ruta y decisiones.

## Ramas
- `main` — versión estable.
- `develop` — integración de la siguiente entrega.
- `release` — rama de publicación; versión 1.0.1.

## Tests
```
swift test --package-path Packages/QuoteCore
xcodebuild test -scheme PresupuestApp -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' CODE_SIGNING_ALLOWED=NO
```

## Arrancar la app
Abre `PresupuestApp.xcodeproj` en Xcode y ejecuta en un simulador de iOS 17 o superior.

## Importar una tarifa
Formatos admitidos: `.xlsx`, `.xlsm`, `.csv`, PDF con texto seleccionable y listas de texto pegadas. Los PDF escaneados como imagen aún requieren OCR; los `.xls` binarios antiguos deben guardarse como `.xlsx` desde Excel. La app también acepta archivos compartidos desde el selector del sistema o «Abrir con».
