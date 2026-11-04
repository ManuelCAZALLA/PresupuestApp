# M2 — Baseline antes de Fase 2

Medición ejecutada con `swift test --package-path Packages/QuoteCore --filter ParserEvaluation` sobre el working tree existente (antes de modificarlo). El test terminó con errores de métricas; los registros están resumidos abajo.

## Fontanería — por caso

| id | entrada | esperado | obtenido | categoría del fallo |
|---|---|---|---|---|
| c01 | cuatro urinarios | auto urinario ×4 | sin fallo reportado | — |
| c02 | 4 urinarios | auto urinario ×4 | sin fallo reportado | — |
| c03 | cuarenta urinarios | auto urinario ×40 | sin fallo reportado | — |
| c04 | un inodoro | auto inodoro ×1 | sin fallo reportado | — |
| c05 | dos wc | auto inodoro ×2 | sin fallo reportado | — |
| c06 | un par de inodoros | auto inodoro ×2 | no auto | cantidad |
| c07 | un plato de ducha de 90 | auto plato 90 ×1 | sin fallo reportado | — |
| c08 | un plato de ducha | ambiguous (platos 90/120) | ambiguous | — |
| c09 | plato de ducha de 120 centímetros | auto plato 120 ×1 asumida | sin fallo reportado | — |
| c10 | un termo | ambiguous (50/80/100) | sin fallo reportado | — |
| c11 | un termo de 80 litros | auto termo 80 ×1 | sin fallo reportado | — |
| c12 | un calentador de 100 | auto termo 100 ×1 | auto incorrecto | emparejamiento |
| c13 | un termo de 60 litros | ambiguous o none; no auto cercano | sin fallo reportado | — |
| c14 | 4 urinarios, un plato de ducha de 90 y un termo de 80 | 3 autos correctos | sin fallo reportado | — |
| c15 | dos grifos de lavabo | auto grifo lavabo ×2 | sin fallo reportado | — |
| c16 | un grifo | ambiguous (lavabo/ducha) | ambiguous | — |
| c17 | media docena de grifos de lavabo | auto grifo lavabo ×6 | sin fallo reportado | — |
| c18 | 10 metros de tubo de 20 | auto tubo PEX 20 ×10 m | sin fallo reportado | — |
| c19 | veinte metros de tubo de 25 | auto tubo PEX 25 ×20 m | sin fallo reportado | — |
| c20 | tres horas de mano de obra | auto mano de obra ×3 h | sin fallo reportado | — |
| c21 | dos coma cinco horas de mano de obra | auto mano de obra ×2,5 h | sin fallo reportado | — |
| c22 | un desatasco | auto desatasco ×1 | sin fallo reportado | — |
| c23 | desatasco | auto desatasco ×1 asumida | sin fallo reportado | — |
| c24 | una piscina | none | sin fallo reportado | — |
| c25 | plato de ducha de 90 y mampara | 2 autos ×1 asumidas | sin fallo reportado | — |
| c26 | cambiar un sifón de lavabo | auto sifón ×1 | sin fallo reportado | — |
| c27 | un termo de 80 litros más el desplazamiento | 2 autos ×1 | sin fallo reportado | — |
| c28 | 3 inodoros + 2 urinarios | autos inodoro ×3 y urinario ×2 | auto incorrecto | segmentación |
| c29 | monomando ducha | auto grifo ducha ×1 asumida | sin fallo reportado | — |
| c30 | diez metros cuadrados de baldosa | none | sin fallo reportado | — |

Totales: 35 líneas esperadas; 28 autos emitidos; 26 correctos; 2 falsos autos. `autoPrecision=26/28=0,929`; `falseAutoRate=2/35=0,057`; `ambiguousRecall=3/3=1,000`; `noneAccuracy=2/2=1,000`.

## Albañilería — por caso

| id | entrada | esperado | obtenido | categoría del fallo |
|---|---|---|---|---|
| a01 | 20 metros cuadrados de alicatado | auto alicatado ×20 m² | sin fallo reportado | — |
| a02 | veinte m2 de tabique | auto tabique ladrillo ×20 m² | auto incorrecto | normalización |
| a03 | demolición de tabique | auto demolición tabique ×1 asumida | auto incorrecto | emparejamiento |
| a04 | un tabique | ambiguous (tabique/demolición) | no ambiguous | estado |
| a05 | solera de hormigón de 10 | auto solera 10 ×1 asumida | esperaba auto (no auto) | emparejamiento |
| a06 | solera de hormigón | ambiguous (10/15) | no ambiguous | estado |
| a07 | solera de hormigón de 12 | ambiguous o none; nunca auto 10/15 | sin fallo reportado | — |
| a08 | dos sacos de cemento | auto saco cemento ×2 | auto incorrecto | emparejamiento |
| a09 | 3 metros cúbicos de escombros | auto retirada escombros ×3 m³ | auto incorrecto | emparejamiento |
| a10 | ocho horas de oficial | auto oficial ×8 h | sin fallo reportado | — |
| a11 | cuatro horas de ayudante | auto ayudante ×4 h | sin fallo reportado | — |
| a12 | mano de obra | ambiguous (oficial/ayudante) | no ambiguous | estado |
| a13 | 15 m2 de solado y 15 m2 de enfoscado | 2 autos ×15 m² | sin fallo reportado | — |
| a14 | cascotes | auto retirada escombros ×1 asumida | esperaba auto (no auto) | emparejamiento |
| a15 | azulejado de 12 metros cuadrados | auto alicatado ×1 asumida | auto incorrecto | cantidad |
| a16 | una piscina | none | sin fallo reportado | — |

Totales: 17 líneas esperadas; 10 autos emitidos; 5 correctos; 5 falsos autos. `autoPrecision=5/10=0,500`; `falseAutoRate=5/17=0,294`; `ambiguousRecall=0/3=0,000`; `noneAccuracy=1/1=1,000`.

## Electricidad y pintura — agregados únicamente

| oficio | líneas esperadas | autos emitidos | correctos | falsos autos | autoPrecision | falseAutoRate | ambiguousRecall | noneAccuracy |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Electricidad | 16 | 12 | 2 | 10 | 0,167 | 0,625 | 0/1 = 0,000 | 0/1 = 0,000 |
| Pintura | 12 | 8 | 3 | 5 | 0,375 | 0,417 | 0/1 = 0,000 | 1/1 = 1,000 |

Las categorías de fallo se asignan a partir del diagnóstico y del esperado de cada fixture; las categorías observables en los registros son cantidad: 2, segmentación: 1, normalización: 1, emparejamiento: 8, estado: 3. En fontanería y albañilería: cantidad 2, segmentación 1, normalización 1, emparejamiento 5, estado 3. No se reasignaron casos de electricidad ni pintura a categorías, según el alcance solicitado.

Nota: la instrumentación actual no imprime el resultado por caso ni el detalle de las líneas emitidas. “Sin fallo reportado” significa que el evaluador no registró una discrepancia para ese caso; no constituye una captura independiente de la salida. El siguiente paso de instrumentación debe conservar las salidas reales para que el informe final incluya `obtenido` verificable caso por caso.
