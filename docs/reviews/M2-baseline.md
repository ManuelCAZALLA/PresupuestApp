# M2 — Baseline observado

## Procedencia

El informe inicial del commit `c26326e` se midió sobre cambios sin commit. Esos seis archivos quedaron preservados en el commit aislado **`f541be2845186ff2b31ac7000db966f2bb297a8e`** (`WIP: previous agent engine state (measured baseline)`). La instrumentación se añadió después; no se cambiaron las fixtures. Las columnas “obtenido” de las tablas siguientes proceden de la salida `[PARSER_CASE]` del test `dumpObservedResults`, no de deducirlo del resultado de las aserciones.

## Reproducción de las observaciones

```sh
swift test --package-path Packages/QuoteCore --filter dumpObservedResults
```

Por caso se imprimen entrada, expectativa, cada línea obtenida (partida, cantidad, unidad y estado), y top-3 con puntuación. El test termina con error porque la implementación medida no cumple los objetivos del evaluador; las observaciones se escriben antes de las aserciones. Las tablas omiten aquí el top-3 por espacio; el comando anterior lo imprime íntegro.

## Fontanería — resultados por caso

| id | entrada | esperado | obtenido observado | categoría primaria |
|---|---|---|---|---|
| c01 | cuatro urinarios | auto urinario ×4 | Urinario ×4, auto | — |
| c02 | 4 urinarios | auto urinario ×4 | Urinario ×4, auto | — |
| c03 | cuarenta urinarios | auto urinario ×40 | Urinario ×40, auto | — |
| c04 | un inodoro | auto inodoro ×1 | Inodoro ×1, auto | — |
| c05 | dos wc | auto inodoro ×2 | Inodoro ×2, auto | — |
| c06 | un par de inodoros | auto inodoro ×2 | Inodoro ×2, ambiguous | estado |
| c07 | un plato de ducha de 90 | auto plato 90 ×1 | Plato 90 cm ×1, auto | — |
| c08 | un plato de ducha | ambiguous platos 90/120 | Plato 120 ×1, ambiguous | — |
| c09 | plato de ducha de 120 centímetros | auto plato 120 ×1 asumida | Plato 120 ×1, auto | — |
| c10 | un termo | ambiguous termos 50/80/100 | Termo 50 ×1, ambiguous | — |
| c11 | un termo de 80 litros | auto termo 80 ×1 | Termo 80 ×1, auto | — |
| c12 | un calentador de 100 | auto termo 100 ×1 | Grifo ducha ×1, auto | emparejamiento |
| c13 | un termo de 60 litros | ambiguous o none; sin auto cercano | Termo 50 ×1, ambiguous | — |
| c14 | 4 urinarios, un plato de ducha de 90 y un termo de 80 | 3 autos correctos | Urinario ×4 auto; Plato 90 ×1 auto; Termo 80 ×1 auto | — |
| c15 | dos grifos de lavabo | auto grifo lavabo ×2 | Grifo lavabo ×2, auto | — |
| c16 | un grifo | ambiguous lavabo/ducha | Grifo ducha ×1, ambiguous | — |
| c17 | media docena de grifos de lavabo | auto grifo lavabo ×6 | Grifo lavabo ×6, auto | — |
| c18 | 10 metros de tubo de 20 | auto tubo 20 ×10 m | Tubo 20 ×10 m, auto | — |
| c19 | veinte metros de tubo de 25 | auto tubo 25 ×20 m | Tubo 25 ×20 m, auto | — |
| c20 | tres horas de mano de obra | auto mano de obra ×3 h | Mano de obra ×3 h, auto | — |
| c21 | dos coma cinco horas de mano de obra | auto mano de obra ×2,5 h | Mano de obra ×2,5, sin unidad, auto | — |
| c22 | un desatasco | auto desatasco ×1 | Desatasco ×1, auto | — |
| c23 | desatasco | auto desatasco ×1 asumida | Desatasco ×1, auto | — |
| c24 | una piscina | none | sin candidato, none | — |
| c25 | plato de ducha de 90 y mampara | 2 autos ×1 | Plato 90 ×1 auto; Mampara ×1 auto | — |
| c26 | cambiar un sifón de lavabo | auto sifón ×1 | Sifón lavabo ×1, auto | — |
| c27 | un termo de 80 litros más el desplazamiento | 2 autos ×1 | Termo 80 ×1 auto; Desplazamiento ×1 auto | — |
| c28 | 3 inodoros + 2 urinarios | auto inodoro ×3 y urinario ×2 | Inodoro ×3 ambiguous; Urinario ×2 auto | estado |
| c29 | monomando ducha | auto grifo ducha ×1 asumida | Grifo ducha ×1 auto | — |
| c30 | diez metros cuadrados de baldosa | none | sin candidato, none | — |

## Albañilería — resultados por caso

| id | entrada | esperado | obtenido observado | categoría primaria |
|---|---|---|---|---|
| a01 | 20 metros cuadrados de alicatado | auto alicatado ×20 m² | Alicatado paredes ×20 m², auto | — |
| a02 | veinte m2 de tabique | auto tabique ladrillo ×20 m² | Demolición tabique ×20 m², auto | emparejamiento |
| a03 | demolición de tabique | auto demolición tabique ×1 asumida | Demolición tabique ×1, auto | emparejamiento (oráculo) |
| a04 | un tabique | ambiguous tabique/demolición | Demolición tabique ×1, auto | estado |
| a05 | solera de hormigón de 10 | auto solera 10 ×1 asumida | Solera 10 ×10, ambiguous | cantidad |
| a06 | solera de hormigón | ambiguous soleras 10/15 | Solera 10 ×1, ambiguous; top candidates incluyen 10 y 15 | emparejamiento (oráculo) |
| a07 | solera de hormigón de 12 | ambiguous o none; no auto 10/15 | Solera 10 ×12, ambiguous | — |
| a08 | dos sacos de cemento | auto saco cemento ×2 | Saco cemento ×2, auto | emparejamiento (oráculo) |
| a09 | 3 metros cúbicos de escombros | auto retirada escombros ×3 m³ | Retirada escombros ×3 m³, auto | emparejamiento (oráculo) |
| a10 | ocho horas de oficial | auto oficial ×8 h | Mano de obra oficial ×8 h, auto | — |
| a11 | cuatro horas de ayudante | auto ayudante ×4 h | Mano de obra ayudante ×4 h, auto | — |
| a12 | mano de obra | ambiguous oficial/ayudante | Mano de obra ayudante ×1, auto | estado |
| a13 | 15 m2 de solado y 15 m2 de enfoscado | 2 autos ×15 m² | Solado ×15 m², auto; Enfoscado ×15 m², auto | — |
| a14 | cascotes | auto retirada escombros ×1 asumida | Retirada escombros ×1, ambiguous | estado |
| a15 | azulejado de 12 metros cuadrados | auto alicatado ×1 asumida | Solado ×12 m², auto | cantidad |
| a16 | una piscina | none | sin candidato, none | — |

Las etiquetas de `a03`, `a08` y `a09` coinciden semánticamente con el resultado observado, pero el evaluador los contó como incorrectos porque compara claves de fixture con nombre/alias del catálogo. Se documentan como discrepancias de emparejamiento del oráculo/evaluador, no como salida distinta del motor. `a06` sí produjo ambiguous y las dos partidas esperadas aparecen en el top-3; el fallo de recall también proviene del chequeo de claves de fixture contra nombres/alias.

## Electricidad y pintura — solo agregados

| fixture | líneas esperadas | autos emitidos | autos correctos | falsos automáticos | autoPrecision | falseAutoRate | ambiguousRecall | noneAccuracy | top3Recall |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Electricidad | 16 | 12 | 2 | 10 | 2/12 = 0,167 | 10/16 = 0,625 | 0/1 = 0,000 | 0/1 = 0,000 | 0/2 = 0,000 |
| Pintura | 12 | 8 | 3 | 5 | 3/8 = 0,375 | 5/12 = 0,417 | 0/1 = 0,000 | 1/1 = 1,000 | 0/1 = 0,000 |

## Métricas de referencia

| fixture | líneas esperadas | auto emitidas | auto correctas | falsos auto | autoPrecision | falseAutoRate | ambiguousRecall | noneAccuracy | top3Recall |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Fontanería | 35 | 28 | 26 | 2 | 26/28 = 0,929 | 2/35 = 0,057 | 3/3 = 1,000 | 2/2 = 1,000 | 4/4 = 1,000 |
| Albañilería | 17 | 10 | 5 | 5 | 5/10 = 0,500 | 5/17 = 0,294 | 0/3 = 0,000 | 1/1 = 1,000 | 0/5 = 0,000 |
| Electricidad | 16 | 12 | 2 | 10 | 2/12 = 0,167 | 10/16 = 0,625 | 0/1 = 0,000 | 0/1 = 0,000 | 0/2 = 0,000 |
| Pintura | 12 | 8 | 3 | 5 | 3/8 = 0,375 | 5/12 = 0,417 | 0/1 = 0,000 | 1/1 = 1,000 | 0/1 = 0,000 |

## Fallos categorizados (casos; categoría primaria)

| oficio | cantidad | segmentación | normalización | emparejamiento | estado | total discrepancias |
|---|---:|---:|---:|---:|---:|---:|
| Fontanería | 0 | 0 | 0 | 1 | 2 | 3 |
| Albañilería | 2 | 0 | 0 | 5 | 3 | 10 |

La evaluación cuenta discrepancias por línea esperada, mientras que este desglose agrupa por caso y asigna una categoría primaria. `a03`, `a06`, `a08` y `a09` se marcan como emparejamiento del oráculo: las salidas reales contienen las partidas semánticamente esperadas (y `a06` incluso tiene el estado y candidatos esperados), pero el chequeo compara claves de fixture con nombres/alias y da fallo. `a05` y `a15` se clasifican como cantidad porque el extractor consume una especificación numérica como cantidad; el resto de discrepancias de estado son `a04`, `a12` y `a14`.
