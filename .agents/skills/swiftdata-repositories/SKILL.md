---
name: swiftdata-repositories
description: Persistencia con SwiftData confinada a App/Data: modelos @Model, mappers a entidades de dominio, repositorios, snapshot de precios y versionado de esquema. Úsala siempre que crees o cambies un @Model, un repositorio, un mapper, el ModelContainer o la migración de datos.
---

# SwiftData + repositorios

## Reglas
1. `@Model` solo en `App/Data/Persistence`. Nunca en QuoteCore, nunca en Presentation.
2. Cada repositorio implementa un protocolo de `QuoteCore/Repositories`. Devuelve entidades de dominio, jamás `@Model`.
3. Mappers explícitos: `extension ItemRecord { func toDomain() -> Item; convenience init(domain: Item) }`.
4. Las líneas de presupuesto guardan copia (nombre, unidad, precio, IVA). `itemID` es opcional y solo informativo.
5. Dinero: guardar `Decimal`. Si SwiftData da problemas con `Decimal` en tu versión, guarda como `String` o enteros de milésimas con conversión en el mapper y deja un test que lo cubra (registra la decisión en `DECISIONS.md`).
6. Esquema versionado desde la primera versión publicada (`VersionedSchema` + `SchemaMigrationPlan`).
7. Operaciones de escritura en el `ModelContext` correcto; repositorios `async`.

## Esqueleto
```swift
@Model final class ItemRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var aliases: [String]
    var unitRaw: String
    var unitPrice: Decimal
    var kindRaw: String
    var category: String?
    var tradeRaw: String
    init(...) { ... }
}

struct SwiftDataItemRepository: ItemRepository {
    let container: ModelContainer
    func all() async throws -> [Item] { ... }
    func save(_ item: Item) async throws { ... }
    func delete(id: Item.ID) async throws { ... }
}
```

## Pruebas
- `ModelContainer` en memoria (`ModelConfiguration(isStoredInMemoryOnly: true)`).
- Ida y vuelta de cada entidad: dominio → registro → dominio igual.
- Borrar una partida no rompe presupuestos existentes.
- Cambiar un precio no cambia líneas de presupuestos guardados.

## Copia de seguridad
Exportar/importar el catálogo como JSON versionado (`schemaVersion`) y legible, para que el usuario pueda llevarse sus datos.
