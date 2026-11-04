# Motor de interpretación (sin IA)

Convierte una frase ("4 urinarios, un plato de ducha de 90 y un termo de 80") en líneas de presupuesto emparejadas con el catálogo del usuario. Vive en `QuoteCore/Engine`. Es una función pura: mismo texto + mismo catálogo = mismo resultado.

## Entrada y salida
- Entrada: `text: String`, `catalog: [Item]` (con alias del usuario), `synonyms: SynonymTable`.
- Salida: `[ParsedLine]`.
```
ParsedLine {
  originalText: String
  quantity: Decimal
  quantityWasAssumed: Bool      // true si no se dijo cantidad y se asumió 1
  spokenUnit: MeasureUnit?      // "metros", "horas"...
  candidates: [(item: Item, score: Double)]   // ordenados, máx. 3
  status: auto | ambiguous | none
  warnings: [unitMismatch]
}
```

## Pipeline
1. **Normalizar**: minúsculas, quitar tildes, unificar espacios, coma decimal → punto, quitar signos salvo `+` y `,`. Convertir "m2", "m²", "metros cuadrados", "metro cuadrado" → `m2`. Quitar verbos de orden ("cambiar", "instalar", "poner", "colocar", "montar") y palabras vacías ("de", "del", "la", "el", "los", "las", "para", "con") SOLO al puntuar (no al leer cantidades).
2. **Segmentar**:
   - Separadores fuertes: coma, punto y coma, salto de línea, `+`, "más".
   - Para " y ": probar dos hipótesis (segmento unido / separado) y quedarse con la de mayor confianza media; en empate, separado. Así "plato de ducha y mampara" da dos líneas.
3. **Cantidad** (por segmento):
   - Número al inicio: dígitos o palabras ("un", "una" = 1, "dos"… "noventa y nueve", "veinte", "cuarenta").
   - Coloquiales: "un par de" = 2, "media docena" = 6, "una docena" / "docena" = 12, "dos coma cinco" = 2,5, "tres y medio" = 3,5.
   - Cantidad con unidad: "10 metros de…", "3 horas de…" → `quantity` y `spokenUnit`.
   - Un número que NO está al inicio es una **especificación** (medida, litros, potencia) y se conserva para puntuar: "tubo de 20", "termo de 80".
   - Sin cantidad → 1 y `quantityWasAssumed = true`.
   - Las palabras-número se reconocen por coincidencia EXACTA (nunca aproximada): "cuarenta" no es "cuatro".
4. **Puntuar** cada partida (nombre + alias del usuario + sinónimos):
   `score = 0.45 × solapePalabras(IDF) + 0.35 × similitudTrigramas + 0.20 × bonusAlias`
   - `solapePalabras`: proporción de palabras del segmento presentes en la partida, pesando más las raras del catálogo.
   - `bonusAlias`: 1 si el texto normalizado coincide con un alias o sinónimo.
   - **Regla de números**: si el segmento trae una especificación numérica y la partida tiene OTRO número en la misma posición semántica (80 vs 50), `score × 0,5` y nunca será `auto`.
5. **Decidir**:
   - `auto`: mejor ≥ 0,85 y ventaja sobre la segunda ≥ 0,10, sin conflicto de números.
   - `ambiguous`: mejor ≥ 0,45 → mostrar hasta 3 candidatos.
   - `none`: resto.
6. **Unidades**: si el usuario dijo "metros" y la partida está en "ud" (o similar), `warning = unitMismatch`. No se calcula en silencio.
7. **Aprender**: al resolver una línea, `LearnAlias` guarda la frase como alias.

Los umbrales (0,85 / 0,10 / 0,45) y pesos son valores iniciales: se ajustan con las fixtures, nunca a ojo.

## Datos configurables (JSON, sin código)
- `Resources/Packs/synonyms_es.json`: grupos de sinónimos por oficio.
- `Resources/Packs/number_words_es.json`: palabras-número.
- `Resources/Packs/stopwords_es.json`: palabras vacías y verbos de orden.
Estos JSON y las fixtures son el "contrato" del motor: si algún día hay versión Android, se reimplementa el algoritmo y debe pasar las mismas fixtures.

## Evaluación (obligatoria en cada cambio del motor)
Un test `ParserEvaluationTests` carga `Fixtures/catalog_*.sample.json` y `Fixtures/parser_cases_*.json`, ejecuta cada caso y mide:

**Fórmulas exactas:**
- **autoPrecision** = líneas `auto` correctas / líneas `auto` emitidas. Una línea automática es correcta solo si acierta partida, cantidad y unidad (si el caso la especifica). Una cantidad equivocada cuenta como falso automático.
- **falseAutoRate** = líneas `auto` incorrectas / líneas esperadas totales. Objetivo ≤ 2 %. Si sube, el cambio se rechaza.
- **ambiguousRecall** = de los casos ambiguos esperados, % donde la partida correcta está entre los 3 candidatos. Objetivo ≥ 90 %.
- **noneAccuracy** = casos sin coincidencia esperados que salen `none` (o `ambiguous` con score bajo, nunca `auto`).
- **top3Recall** = en las líneas que no salen `auto`, porcentaje donde la partida correcta está entre los 3 candidatos. Objetivo ≥ 95 %.

La salida imprime numerador/denominador de cada métrica por fixture y total.

Formato de un caso:
```json
{ "id": "c01", "input": "cuatro urinarios",
  "expect": [ { "item": "urinario", "qty": 4, "status": "auto" } ] }
```
Campos opcionales por línea esperada: `candidatesInclude`, `statusIn`, `mustNotAuto`, `assumedQuantity`, `unit`.
Los datos de prueba llevan precios de PRUEBA (no reales). Cuando haya tarifas reales de fontaneros (con su permiso), se añaden como fixtures nuevas.

### Notas sobre el recuento (M2)
- **Discrepancia albañilería "5/12 con 6 falsos":** Con el recuento anterior, `falseAutoRate` se calculaba sobre número de casos y la corrección de `auto` era más laxa; ahora `autoPrecision = líneas auto correctas / líneas auto emitidas` (solo si acierta partida, cantidad y unidad si se especifica) y `falseAutoRate = líneas auto incorrectas / líneas esperadas totales` (suma de todas las expectativas). Una cantidad equivocada es falso automático.
- **c27 fontanería "1 fallo qty":** Con el recuento anterior el fallo de cantidad se registraba pero no restaba de `autoPrecision` de la misma forma; con las reglas nuevas, cantidad incorrecta cuenta como línea auto incorrecta/falso automático, por lo que afecta a las métricas.
