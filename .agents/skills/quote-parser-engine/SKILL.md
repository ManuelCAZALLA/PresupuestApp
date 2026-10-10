---
name: quote-parser-engine
description: Motor que convierte frases dictadas o escritas ("4 urinarios, un plato de ducha y un termo") en líneas de presupuesto sobre el catálogo del usuario, sin IA. Úsala siempre que toques normalización, números en palabras, cantidades, sinónimos, alias, puntuación de coincidencias, umbrales, fixtures de parser o ParserEvaluationTests.
---

# Motor de interpretación

Especificación completa en `docs/PARSER.md`. Esta skill dice cómo desarrollar y medir.

## Ciclo de trabajo (siempre este orden)
1. **Mide antes**: ejecuta `swift test --package-path Packages/QuoteCore --filter ParserEvaluation` y anota autoPrecision, falseAutoRate, ambiguousRecall, noneAccuracy.
2. **Escribe el caso**: añade el caso nuevo (o el fallo) a `Fixtures/parser_cases_*.json` ANTES de tocar código.
3. **Cambia una cosa**: una regla, un peso o un umbral por vez.
4. **Mide después**: si `falseAutoRate` sube o cualquier métrica baja del objetivo, revierte.
5. Documenta el cambio de umbrales en `docs/PARSER.md`.

## Principios
- Un falso acierto automático es peor que preguntar de más. Ante la duda, `ambiguous`.
- Los números en palabras se reconocen por coincidencia EXACTA ("cuarenta" ≠ "cuatro").
- Un número fuera del inicio es una especificación (80 litros, tubo de 20) y entra en la puntuación; si no coincide con la partida, nunca `auto`.
- El motor es una función pura: sin red, sin hora, sin aleatoriedad, sin estado oculto. Mismo input, mismo output.
- Los sinónimos, palabras vacías y números viven en JSON, no en código.

## Estructura de módulos (`QuoteCore/Engine`)
`Normalizer` → `Segmenter` → `QuantityExtractor` → `Scorer` → `Matcher` (decide `auto/ambiguous/none`) → `RequestInterpreter` (orquesta). `SynonymTable` y `NumberWords` cargan los JSON.

## Casos que SIEMPRE deben estar en las fixtures
- Cantidad en dígitos y en palabras; "un par de", "media docena", "dos coma cinco".
- Plurales y sinónimos ("wc", "calentador").
- Especificación numérica correcta, incorrecta y ausente (termo de 80 / 60 / sin dato).
- Frases con "y" que son una cosa y frases con "y" que son dos.
- Unidad dicha que no cuadra con la de la partida.
- Texto sin ninguna coincidencia.
- Errores típicos de dictado ("m2" / "metros cuadrados").

## Ajuste de umbrales
Se hace con datos: prueba una rejilla (p. ej. auto 0,80-0,90; ventaja 0,05-0,15) sobre las fixtures y elige el punto con `falseAutoRate` ≤ 2 % y mejor autoPrecision. Guarda el resultado en `DECISIONS.md`.
