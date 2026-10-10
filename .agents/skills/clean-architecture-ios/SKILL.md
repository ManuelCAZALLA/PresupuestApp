---
name: clean-architecture-ios
description: Reglas de Clean Architecture + MVVM de este proyecto iOS y cómo añadir código sin romper las capas. Úsala SIEMPRE que vayas a crear un archivo nuevo, añadir una feature, un caso de uso, un repositorio, tocar el AppContainer, o cuando dudes de en qué carpeta va algo, aunque no menciones la arquitectura.
---

# Clean Architecture + MVVM (PresupuestoApp)

Lee primero `docs/ARCHITECTURE.md`. Esta skill es el procedimiento.

## Regla de dependencias
`Presentation → QuoteCore ← Data`. Composition une las tres.
- QuoteCore: solo `import Foundation`.
- Data: puede importar SwiftData, PDFKit, Speech, UniformTypeIdentifiers.
- Presentation: SwiftUI + QuoteCore. Nunca SwiftData.

## ¿Dónde va esto?
| Si es… | Va en… |
|---|---|
| Regla de negocio, cálculo, entidad | `Packages/QuoteCore/Sources/QuoteCore/…` |
| Algo que habla con el sistema (disco, voz, PDF) | protocolo en `QuoteCore/Ports` o `Repositories`; implementación en `App/Data/…` |
| Pantalla | `App/Presentation/Features/<Feature>/` |
| Componente visual reutilizable | `App/Presentation/Shared/` |
| Creación de dependencias | `App/Composition/AppContainer.swift` |
| Texto visible | `App/Resources/Localizable.xcstrings` |

## Procedimiento para una feature nueva
1. Define (o confirma) el caso de uso en QuoteCore y escribe su test primero.
2. Si hay E/S: protocolo en QuoteCore, implementación en Data, test con repositorio falso.
3. Crea `<Feature>View` y `<Feature>ViewModel` (usa la skill `swiftui-feature-scaffold`).
4. Registra el caso de uso y el ViewModel en `AppContainer`; añade la ruta a `AppRoute`.
5. Textos en `Localizable.xcstrings`.
6. Ejecuta `swift test --package-path Packages/QuoteCore` y los tests de la app.
7. Anota en `docs/DECISIONS.md` si tomaste una decisión nueva.

## Casos de uso
```swift
public struct DuplicateQuote {
    private let quotes: QuoteRepository
    private let clock: Clock
    public init(quotes: QuoteRepository, clock: Clock) { ... }
    public func execute(id: Quote.ID) async throws -> Quote { ... }
}
```
Un tipo, un método `execute`, dependencias por `init`, errores como `DomainError`.

## Señales de que algo está mal
- Un ViewModel con `import SwiftData` o `ModelContext`.
- Un `@Model` devuelto por un repositorio.
- Lógica de precios o IVA en una vista o ViewModel.
- Un singleton (`static let shared`).
- Un `Double` para dinero.
Si lo ves, corrígelo o anótalo para el `reviewer`.
