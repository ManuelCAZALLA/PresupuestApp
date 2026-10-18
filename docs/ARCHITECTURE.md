# Arquitectura

Clean Architecture + MVVM. Objetivo: que cada agente trabaje en su carpeta sin pisar a otro, y que el compilador impida saltarse las capas.

## Capas y regla de dependencias
```
Presentation (SwiftUI + ViewModels)  ──►  QuoteCore (Domain)  ◄──  Data (SwiftData, PDF, import, voz)
                         └──────────── Composition (une todo) ────────────┘
```
- **QuoteCore** (paquete Swift local, solo Foundation): entidades, cálculo, motor de interpretación, casos de uso, protocolos (repositorios y "puertos"). No conoce a nadie.
- **Data** implementa los protocolos de QuoteCore. Es la única capa que importa SwiftData, PDFKit, Speech, UniformTypeIdentifiers.
- **Presentation** usa casos de uso de QuoteCore. No conoce SwiftData ni la implementación de Data.
- **Composition** crea las implementaciones concretas y las inyecta (a mano, sin librerías).

Si un `import` rompe esta regla, es un error de arquitectura. El `reviewer` lo bloquea.

## Estructura de carpetas
```
PresupuestApp/
├─ AGENTS.md  CLAUDE.md
├─ docs/
├─ Packages/QuoteCore/
│  ├─ Package.swift
│  ├─ Sources/QuoteCore/
│  │  ├─ Entities/        Item, Kit, Quote, QuoteLine, Client, BusinessProfile, Trade, MeasureUnit, VATRate
│  │  ├─ Calculation/     QuoteCalculator, RoundingPolicy, QuoteTotals
│  │  ├─ Engine/          Normalizer, NumberWords, Segmenter, QuantityExtractor, Scorer, Matcher, RequestInterpreter, SynonymTable
│  │  ├─ Import/          ColumnMapper, PriceParser, UnitParser, entidades de importación
│  │  ├─ Ports/           protocolos externos: DictationService, QuotePDFRenderer, Clock, EntitlementProvider, TariffImportSource, TariffTemplateProviding
│  │  ├─ Repositories/    protocolos: ItemRepository, KitRepository, QuoteRepository, ProfileRepository, AliasRepository
│  │  ├─ UseCases/        un tipo por caso de uso
│  │  └─ Errors/          DomainError
│  └─ Tests/QuoteCoreTests/ (+ Fixtures/)
├─ App/
│  ├─ PresupuestApp.swift
│  ├─ Composition/        AppContainer, AppRouter
│  ├─ Data/
│  │  ├─ Persistence/     modelos @Model, ModelContainer, mappers
│  │  ├─ Repositories/    SwiftData*Repository
│  │  ├─ Import/          CSVReader, XLSXReader, PastedTextParser, LocalTariffSource, FileTariffTemplateProvider, ImportFileTypes
│  │  ├─ Speech/          SpeechDictationService
│  │  ├─ PDF/             QuotePDFRenderer
│  │  └─ Packs/           TradePackLoader
│  ├─ Presentation/
│  │  ├─ Shared/          componentes, tema, formateadores (moneda es-ES)
│  │  └─ Features/<Feature>/  <Feature>View.swift, <Feature>ViewModel.swift
│  └─ Resources/          Localizable.xcstrings, Assets, Packs/*.json
└─ Tests/                 AppTests (target de tests unitarios, `xcodebuild test`), UITests, ImportSamples/ (archivos de ejemplo y `expected_imports.json`, no se editan)
```

## MVVM en este proyecto
- **View**: SwiftUI puro, sin lógica. Lee propiedades del ViewModel y llama a sus métodos.
- **ViewModel**: `@MainActor @Observable final class`. Recibe casos de uso por `init`. Expone estado (`var`), acciones (métodos `func`) y un estado de carga/error. Traduce `DomainError` a texto en español.
- **Estado de pantalla**: enum `ViewState { idle, loading, loaded, failed(message) }` cuando haya carga; propiedades simples en el resto.
- **Navegación**: `NavigationStack` con una ruta tipada (`enum AppRoute: Hashable`) en `AppRouter` (`@Observable`), creado en Composition.
- **Casos de uso**: `struct` con dependencias protocolo y un método `execute(...)`. Síncronos si son puros (motor, cálculo); `async` si hay E/S.

## Persistencia
- SwiftData solo dentro de `App/Data/Persistence`. Un `@Model` por entidad persistida, más mappers `toDomain()` / `init(domain:)`.
- La línea de presupuesto guarda copia del nombre, unidad y precio en el momento (snapshot). Nunca referencia viva al precio.
- Cambios de esquema: versionar con `VersionedSchema` desde la primera versión publicada.

## Errores
- `DomainError` (enum) en QuoteCore: `.invalidPrice`, `.unitMismatch`, `.emptyQuote`, `.quotaExceeded`, `.importFailed(reason)`, etc.
- Data traduce errores del sistema a `DomainError`. Presentation traduce `DomainError` a mensajes localizados.

## Pruebas por capa
| Capa | Qué se prueba | Cómo |
|---|---|---|
| QuoteCore | Cálculo, motor, casos de uso | `swift test`; vectores de `DOMAIN.md`; fixtures del parser; repositorios falsos en memoria |
| Data | Mappers, repositorios, importadores | Tests con `ModelContainer` en memoria y archivos de ejemplo de `Tests/ImportSamples`, en el target `AppTests` (`xcodebuild test`) |
| Presentation | ViewModels | Casos de uso falsos; sin SwiftUI |
| UI | Flujo principal | UITests mínimos: onboarding → presupuesto → PDF |

## Cómo añadir una feature (checklist)
1. ¿Hace falta lógica nueva? Primero en QuoteCore, con test.
2. Protocolo de repositorio/puerto en QuoteCore si hay E/S; implementación en Data.
3. Carpeta `Features/<Feature>/` con `View` y `ViewModel`.
4. Textos en `Localizable.xcstrings`.
5. Conectar en `AppContainer` y en `AppRoute`.
6. Tests del ViewModel.
7. Actualizar `ROADMAP.md` y, si procede, `DECISIONS.md`.

## Dependencias externas
Ninguna al empezar. Admitida en M4: lector `.xlsx` (p. ej. CoreXLSX). RevenueCat se estudiará en M7 (ver `DECISIONS.md`).
