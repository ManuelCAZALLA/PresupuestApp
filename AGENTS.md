# AGENTS.md — PresupuestApp (nombre provisional)

App móvil para profesionales de oficios (fontanería, albañilería, electricidad). El usuario carga su tarifa de precios, describe un trabajo hablando o escribiendo y la app genera un presupuesto al instante, en PDF, con sus propios precios.

## Principios del producto (no negociables)
- Los precios salen SIEMPRE de la tarifa del usuario. Nunca se inventan ni se estiman.
- La v1 funciona sin IA y sin conexión. Ningún servicio de pago por uso.
- La v1 NO incluye facturación, firma del cliente, agenda, nube ni multiusuario.
- Ante la duda, la app pregunta al usuario; nunca elige en silencio (un falso acierto automático es el peor error).
- Detalle de producto: `docs/PRODUCT.md`.

## Plataforma y stack
- iOS 17 o superior (SwiftData lo exige), Swift, SwiftUI, SwiftData.
- Tests: Swift Testing o XCTest. El motor se prueba con `swift test`.
- Dependencias permitidas: ninguna al empezar. Un lector de `.xlsx` (p. ej. CoreXLSX) se admite en el hito M4. Cualquier otra requiere aprobación y se anota en `docs/DECISIONS.md`.

## Arquitectura (resumen; detalle en `docs/ARCHITECTURE.md`)
Clean Architecture + MVVM. Dependencias: `Presentation → QuoteCore (Domain) ← Data`.
- `Packages/QuoteCore`: dominio + motor de interpretación. Swift puro (solo Foundation). NO importa SwiftUI, SwiftData, UIKit, PDFKit ni Speech.
- `App/Data`: SwiftData, repositorios, importadores, PDF, dictado.
- `App/Presentation`: vistas SwiftUI y ViewModels por feature.
- `App/Composition`: raíz de composición (inyección de dependencias manual).

## Reglas de código
- Dinero: `Decimal`. Nunca `Double`/`Float`. Reglas de redondeo en `docs/DOMAIN.md`.
- Código e identificadores en inglés. Textos visibles en español, en `Localizable.xcstrings` (nunca literales sueltos en vistas).
- ViewModels: `@MainActor`, `@Observable`, sin importar SwiftData; reciben casos de uso por inicializador.
- Un caso de uso = un tipo con un método `execute`. Los repositorios son protocolos en QuoteCore.
- Los tipos `@Model` de SwiftData nunca salen de `App/Data`. Se traducen a entidades de dominio con mappers.
- Sin singletons, sin `try!`, sin `fatalError` fuera de tests, sin `print` (usar `Logger`).
- Accesibilidad: Dynamic Type, etiquetas de VoiceOver, botones principales de al menos 56 pt (se usa en obra, con una mano).
- Privacidad: los datos se quedan en el dispositivo. Sin analítica ni red en la v1.
- TDD en QuoteCore: primero el test, luego el código. Todo cambio en el motor añade casos a `Fixtures/`.

## Cómo trabajar
1. Lee `docs/ROADMAP.md` y trabaja solo en el hito actual.
2. Si la tarea coincide con una skill de `.agents/skills`, léela antes de empezar.
3. Cambios pequeños y verificables. Una rama por hito, commits en inglés y en imperativo.
4. Antes de dar algo por terminado: tests en verde, sin warnings nuevos, `docs/DECISIONS.md` actualizado si tomaste una decisión de arquitectura.
5. Si algo del producto no está definido, no lo inventes: anótalo en `docs/OPEN_QUESTIONS.md` y sigue con la opción más simple.

## Agentes y propiedad de carpetas
| Agente | Es dueño de | Notas |
|---|---|---|
| `architect` | `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, esqueleto de carpetas | Decide y documenta; no implementa features. |
| `domain_engineer` | `Packages/QuoteCore/Sources` | Entidades, cálculo, motor de interpretación. |
| `data_engineer` | `App/Data`, `App/Resources/Packs` | SwiftData, importadores, PDF, dictado. |
| `ui_engineer` | `App/Presentation`, `App/Composition` | SwiftUI, ViewModels, navegación, textos. |
| `qa_engineer` | `Packages/QuoteCore/Tests`, `Tests/` | Tests, fixtures, evaluación del motor. |
| `reviewer` | (solo lectura) | Revisa capas, dinero, privacidad y tests antes de cerrar un hito. |

Varios agentes pueden escribir a la vez solo si trabajan en carpetas distintas de la tabla. Si necesitas cambiar una carpeta ajena, pídelo al agente dueño o al agente principal.

## Qué NO hacer
- No añadir IA/LLM, analítica, publicidad, ni llamadas de red en la v1.
- No cambiar firma, certificados ni identificadores de la app.
- No inventar precios, ni siquiera en datos de ejemplo de producción (los datos de prueba se marcan como PRUEBA).
- No dar por buena la lógica fiscal: el IVA es editable y la app no sustituye a un gestor.
