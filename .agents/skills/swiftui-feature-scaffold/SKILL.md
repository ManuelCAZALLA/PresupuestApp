---
name: swiftui-feature-scaffold
description: Plantilla para crear una pantalla (feature) SwiftUI con MVVM en este proyecto: vista, ViewModel @Observable, estados, textos en español, accesibilidad y pruebas. Úsala siempre que crees o modifiques una pantalla, una vista, un ViewModel o la navegación, o cuando te pidan "añade una pantalla de…".
---

# Scaffold de feature

Una feature = carpeta `App/Presentation/Features/<Feature>/` con `<Feature>View.swift` y `<Feature>ViewModel.swift`. Lista de features y criterios en `docs/PRODUCT.md`.

## ViewModel
```swift
@MainActor
@Observable
final class CatalogViewModel {
    enum ViewState: Equatable { case idle, loading, loaded, failed(String) }

    private(set) var state: ViewState = .idle
    private(set) var items: [Item] = []
    var searchText = ""

    private let listItems: ListItems
    private let saveItem: SaveItem

    init(listItems: ListItems, saveItem: SaveItem) {
        self.listItems = listItems
        self.saveItem = saveItem
    }

    func load() async {
        state = .loading
        do { items = try await listItems.execute(); state = .loaded }
        catch { state = .failed(Self.message(for: error)) }
    }
}
```
- Sin `import SwiftData`. Dependencias = casos de uso del dominio.
- `message(for:)` traduce `DomainError` a texto localizado.

## Vista
- SwiftUI puro: lee estado, llama a métodos. Sin cálculos ni reglas.
- Textos: `Text("catalog.title")` con clave en `Localizable.xcstrings`, nunca literales.
- Moneda: formateador compartido de `Presentation/Shared` (es-ES).
- Botones principales ≥ 56 pt de alto; zonas táctiles ≥ 44 pt.
- Dynamic Type: sin alturas fijas en texto; probar el tamaño más grande.
- VoiceOver: `accessibilityLabel` en iconos y acciones.
- Tema claro y oscuro; contraste suficiente a pleno sol (se usa en la calle).

## Navegación
`AppRoute` (enum `Hashable`) + `AppRouter` (`@Observable`) con un `NavigationStack`. Cada vista recibe acciones de navegación por cierre o por el router; el ViewModel no crea otras vistas.

## Pruebas
- Test del ViewModel con casos de uso falsos: estado inicial, éxito, error, y cada acción.
- No se prueban vistas con snapshots en el MVP; sí un UITest del flujo principal en M5.

## Lista de comprobación antes de terminar
- [ ] Compila sin warnings nuevos.
- [ ] Sin lógica de precios/IVA en la vista ni en el ViewModel.
- [ ] Textos en español en `Localizable.xcstrings`.
- [ ] Estados vacío, carga y error diseñados.
- [ ] Funciona con una mano y con el tamaño de letra más grande.
