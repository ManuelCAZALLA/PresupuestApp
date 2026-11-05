# M2 — Baseline con evaluador por UUID y posición

## Procedencia y método

Medición del motor actual, sin cambios en `Packages/QuoteCore/Sources`. Se ejecutó el evaluador tras incluir la quinta fixture `parser_cases_sintetico.json`. Las fixtures no se modificaron.

**Las cifras de informes anteriores usaban otro evaluador y no son comparables.** El evaluador actual crea UUID deterministas por ID del catálogo, empareja por índice, consume cada línea una sola vez, cuenta salidas sobrantes y valida `mustNotAuto` por UUID. Las métricas siguientes proceden de las salidas observadas del motor.

Comando:

```sh
swift test --package-path Packages/QuoteCore --filter evaluateAllFixtures
```

## Métricas observadas

Cada razón incluye numerador y denominador. `n/a` indica denominador cero.

| fixture | totalExpectedLines | autoEmitted | correctAuto | falseAuto | autoPrecision | autoRecall | falseAutoRate | ambiguousRecall | noneAccuracy | top3Recall |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Fontanería | 35 | 27 | 25 | 2 | 25/27 = 0,926 | 27/29 = 0,931 | 2/35 = 0,057 | 3/3 = 1,000 | 2/2 = 1,000 | 5/5 = 1,000 |
| Albañilería | 17 | 12 | 8 | 4 | 8/12 = 0,667 | 10/12 = 0,833 | 4/17 = 0,235 | 1/3 = 0,333 | 1/1 = 1,000 | 3/3 = 1,000 |
| Electricidad | 16 | 13 | 10 | 3 | 10/13 = 0,769 | 12/13 = 0,923 | 3/16 = 0,188 | 1/1 = 1,000 | 0/1 = 0,000 | 1/2 = 0,500 |
| Pintura | 12 | 11 | 8 | 3 | 8/11 = 0,727 | 8/8 = 1,000 | 3/12 = 0,250 | 0/1 = 0,000 | 1/1 = 1,000 | n/a |
| Sintético | 19 | 12 | 9 | 3 | 9/12 = 0,750 | 10/15 = 0,667 | 3/19 = 0,158 | 1/1 = 1,000 | 1/1 = 1,000 | 6/6 = 1,000 |

## Fontanería — casos observados

| id | entrada | esperado | obtenido | categoría primaria |
|---|---|---|---|---|
| c01 | cuatro urinarios | auto urinario ×4 | urinario ×4, auto | — |
| c02 | 4 urinarios | auto urinario ×4 | urinario ×4, auto | — |
| c03 | cuarenta urinarios | auto urinario ×40 | urinario ×40, auto | — |
| c04 | un inodoro | auto inodoro ×1 | inodoro ×1, auto | — |
| c05 | dos wc | auto inodoro ×2 | inodoro ×2, auto | — |
| c06 | un par de inodoros | auto inodoro ×2 | inodoro ×2, ambiguous | estado |
| c07 | un plato de ducha de 90 | auto plato-ducha-90 ×1 | plato-ducha-90 ×1, auto | — |
| c08 | un plato de ducha | ambiguous platos 90/120 | plato-ducha-120 ×1, ambiguous | — |
| c09 | plato de ducha de 120 centímetros | auto plato-ducha-120 ×1 | plato-ducha-120 ×1, auto | — |
| c10 | un termo | ambiguous termos 50/80/100 | termo-50l ×1, ambiguous | — |
| c11 | un termo de 80 litros | auto termo-80l ×1 | termo-80l ×1, auto | — |
| c12 | un calentador de 100 | auto termo-100l ×1 | grifo-ducha ×1, auto | emparejamiento |
| c13 | un termo de 60 litros | ambiguous o none | termo-50l ×1, ambiguous | — |
| c14 | 4 urinarios, un plato de ducha de 90 y un termo de 80 | 3 autos correctos | urinario ×4 auto; plato-ducha-90 ×1 auto; termo-80l ×1 auto | — |
| c15 | dos grifos de lavabo | auto grifo-lavabo ×2 | grifo-lavabo ×2, auto | — |
| c16 | un grifo | ambiguous lavabo/ducha | grifo-ducha ×1, ambiguous | — |
| c17 | media docena de grifos de lavabo | auto grifo-lavabo ×6 | grifo-lavabo ×6, auto | — |
| c18 | 10 metros de tubo de 20 | auto tubo-pex-20 ×10 m | tubo-pex-20 ×10 m, auto | — |
| c19 | veinte metros de tubo de 25 | auto tubo-pex-25 ×20 m | tubo-pex-25 ×20 m, auto | — |
| c20 | tres horas de mano de obra | auto mano-obra-hora ×3 h | mano-obra-hora ×3 h, auto | — |
| c21 | dos coma cinco horas de mano de obra | auto mano-obra-hora ×2,5 h | mano-obra-hora ×2,5, sin unidad, auto | emparejamiento |
| c22 | un desatasco | auto desatasco ×1 | desatasco ×1, auto | — |
| c23 | desatasco | auto desatasco ×1 | desatasco ×1, auto | — |
| c24 | una piscina | none | sin candidato, none | — |
| c25 | plato de ducha de 90 y mampara | 2 autos ×1 | plato-ducha-90 ×1 auto; mampara-ducha ×1 auto | — |
| c26 | cambiar un sifón de lavabo | auto sifon ×1 | sifon ×1, auto | — |
| c27 | un termo de 80 litros más el desplazamiento | 2 autos ×1 | termo-80l ×1 auto; desplazamiento ×1 auto | — |
| c28 | 3 inodoros + 2 urinarios | auto inodoro ×3; auto urinario ×2 | inodoro ×3 ambiguous; urinario ×2 auto | estado |
| c29 | monomando ducha | auto grifo-ducha ×1 | grifo-ducha ×1, auto | — |
| c30 | diez metros cuadrados de baldosa | none | sin candidato, none | — |

Recuento primario: cantidad 0, segmentación 0, normalización 0, emparejamiento 2, estado 2.

## Albañilería — casos observados

| id | entrada | esperado | obtenido | categoría primaria |
|---|---|---|---|---|
| a01 | 20 metros cuadrados de alicatado | auto alicatado ×20 m² | alicatado ×20 m², auto | — |
| a02 | veinte m2 de tabique | auto tabique-ladrillo ×20 | demolicion-tabique ×20, auto | emparejamiento |
| a03 | demolición de tabique | auto demolicion-tabique ×1 asumida | demolicion-tabique ×1, auto | — |
| a04 | un tabique | ambiguous tabique-ladrillo/demolicion-tabique | demolicion-tabique ×1, auto | estado |
| a05 | solera de hormigón de 10 | auto solera-10 ×1 | solera-10 ×10, ambiguous | cantidad |
| a06 | solera de hormigón | ambiguous solera-10/solera-15 | solera-10 ×1, ambiguous; top-3 incluye ambas | — |
| a07 | solera de hormigón de 12 | ambiguous o none; no auto cercano | solera-10 ×12, ambiguous | — |
| a08 | dos sacos de cemento | auto saco-cemento ×2 | saco-cemento ×2, auto | — |
| a09 | 3 metros cúbicos de escombros | auto retirada-escombros ×3 m³ | retirada-escombros ×3 m³, auto | — |
| a10 | ocho horas de oficial | auto oficial ×8 h | oficial ×8 h, auto | — |
| a11 | cuatro horas de ayudante | auto ayudante ×4 h | ayudante ×4 h, auto | — |
| a12 | mano de obra | ambiguous oficial/ayudante | ayudante ×1, auto | estado |
| a13 | 15 m2 de solado y 15 m2 de enfoscado | 2 autos ×15 m² | solado ×15 m² auto; enfoscado ×15 m² auto | — |
| a14 | cascotes | auto retirada-escombros ×1 | retirada-escombros ×1, ambiguous | estado |
| a15 | azulejado de 12 metros cuadrados | auto alicatado ×1 | solado ×12 m², auto | cantidad |
| a16 | una piscina | none | sin candidato, none | — |

Recuento primario: cantidad 2, segmentación 0, normalización 0, emparejamiento 1, estado 3.

## Electricidad y pintura — examen sellado, solo agregados

Los datos agregados están en la tabla de métricas. No se incluye tabla por caso ni diagnóstico específico.

## Sintético — casos con discrepancias

| id | entrada | esperado | obtenido | causa observada |
|---|---|---|---|---|
| s01 | cinco quelmos | auto quelmo ×5 | quelmo ×5, ambiguous | salió ambiguous en vez de auto |
| s05 | un zorba de 19 | ambiguous o none; no auto | pluma ×1, auto | auto en expectativa ambiguous/none |
| s07 | tirvo de 9 | auto tirvo-9 ×1 | tirvo-7 ×9, auto | UUID de partida y cantidad incorrectos |
| s10 | un nabo de 175 litros | ambiguous o none; no auto | pluma ×1, auto | auto en expectativa ambiguous/none |
| s12 | 7 quelmos | auto quelmo ×7 | quelmo ×7, ambiguous | salió ambiguous en vez de auto |
| s13 | 17 quelmos | auto quelmo ×17 | quelmo ×17, ambiguous | salió ambiguous en vez de auto |
| s15 | quelmo y zorba de 23 | auto quelmo ×1; auto zorba-23 ×1 | quelmo ×1 auto; zorba-17 ×23 ambiguous | segunda línea no salió auto; la cifra 23 pasó a cantidad |
| s16 | kelmo | auto quelmo ×1 | quelmo ×1, ambiguous | salió ambiguous en vez de auto |

### Hipótesis sobre QuantityExtractor

Los resultados coinciden parcialmente con la hipótesis. En `s07`, la medida `9` se consume como cantidad (`×9`) y la partida emitida tiene UUID distinto del esperado. En `s15`, `23` también acaba como cantidad (`×23`) y no como especificación; la salida queda ambiguous. Son evidencias compatibles con la regla observada en `QuantityExtractor.swift:108`, que protege un conjunto cerrado de cifras. `s05` y `s10` son falsos automáticos de emparejamiento/puntuación y no los explica esa regla.

## Categorías primarias — fontanería y albañilería

| oficio | cantidad | segmentación | normalización | emparejamiento | estado | total de casos discrepantes |
|---|---:|---:|---:|---:|---:|---:|
| Fontanería | 0 | 0 | 0 | 2 | 2 | 4 |
| Albañilería | 2 | 0 | 0 | 1 | 3 | 6 |
