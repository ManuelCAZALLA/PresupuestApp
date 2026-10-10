# KICKOFF — Arranque del proyecto (M0)

Pasos para dejar el proyecto listo para desarrollar. El repo ya trae `Packages/QuoteCore` y el esqueleto de `App/`; si el `.xcodeproj` no existe todavía, créalo aquí.

## 1. Crear el proyecto Xcode (si no existe)
1. Xcode → **File > New > Project… > iOS > App**.
2. Product Name: `PresupuestApp`. Team: (tu equipo). Organization Identifier: `com.manuelcazalla`.
3. Interface: **SwiftUI**. Language: **Swift**. Testing System: **Swift Testing**. Storage: **None**.
4. Guarda el proyecto en la raíz del repo, **junto a** `Packages/` y `App/` (la carpeta `.xcodeproj`, no un subdirectorio nuevo).
5. Borra la carpeta de fuentes que Xcode crea por defecto (`PresupuestApp/` si aparece) y deja los fuentes dentro de `App/` (ver `docs/ARCHITECTURE.md`).

## 2. Enlazar el paquete local QuoteCore
1. **File > Add Package Dependencies… > Add Local…**
2. Selecciona la carpeta `Packages/QuoteCore`.
3. En la ventana de opciones, añádelo al target de la app **PresupuestApp** (Add to Target).
4. En el target → **General > Frameworks, Libraries, and Embedded Content**, comprueba que aparece `QuoteCore`.

## 3. Verificar
```
swift test --package-path Packages/QuoteCore
```
Y en Xcode: selecciona un simulador iOS 17+ y **Run** (⌘R). Debe arrancar una pantalla vacía.
