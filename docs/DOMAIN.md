# Dominio

Todo este documento vive en `Packages/QuoteCore`. Sin SwiftUI, SwiftData ni UIKit.

## Entidades
- **Trade**: `plumber`, `mason`, `electrician`, `other`.
- **MeasureUnit**: `unit` (ud), `meter` (m), `squareMeter` (m2), `cubicMeter` (m3), `hour` (h), `lumpSum` (global).
- **ItemKind**: `material`, `labor`, `travel`, `other`.
- **Item** (partida): `id`, `name`, `aliases: [String]`, `unit`, `unitPrice: Decimal` (sin IVA), `vatRate: Decimal?` (tipo propio; `nil` = el del presupuesto), `kind`, `category: String?`, `trade`.
- **Kit**: `id`, `name`, `entries: [(itemID, quantity)]`.
- **Client**: `name`, `phone`, `address`, `workAddress?` (todo texto libre).
- **QuoteLine**: `id`, `itemID?`, `name` (copia), `unit` (copia), `quantity: Decimal`, `unitPrice: Decimal` (copia, sin IVA), `vatRate: Decimal`, `origin` (`parser`, `manual`, `kit`).
- **Discount**: `none`, `percent(Decimal)`, `amount(Decimal)`.
- **QuoteStatus**: `draft`, `sent`, `accepted`, `rejected`.
- **Quote**: `id`, `number`, `date`, `validityDays`, `client`, `status`, `lines`, `discount`, `notes`, `defaultVATRate`.
- **BusinessProfile**: `name`, `taxID`, `phone`, `email`, `logo: Data?`, `defaultVATRate`, `terms`, `validityDays`, `numberPrefix`.

## Precios y redondeo (regla única)
- Todo con `Decimal`. Los precios unitarios se guardan con hasta 4 decimales (por la conversión desde precios con IVA) y se muestran con 2.
- Redondeo a 2 decimales con `NSDecimalNumber.RoundingMode.plain` (mitad hacia arriba). Se redondea SOLO en: total de línea, descuento, base por tipo de IVA y cuota de IVA.
- Importes en euros. Formato de presentación es-ES (coma decimal) en `Presentation/Shared`, nunca en el dominio.

## Cálculo de un presupuesto (`QuoteCalculator`)
1. `lineTotal = round2(quantity × unitPrice)`.
2. `subtotal = Σ lineTotal`.
3. Descuento: `percent(p)` → `round2(subtotal × p/100)`; `amount(a)` → `min(a, subtotal)`; `none` → 0.
4. Agrupar `lineTotal` por tipo de IVA, ordenando los grupos por tipo de IVA ascendente. Repartir el descuento: cada grupo recibe `round2(descuento × baseDelGrupo / subtotal)`; el último grupo (el de mayor tipo de IVA) recibe el resto para que la suma sea exacta.
5. Por grupo: `base = baseSinDescuento − descuentoDelGrupo`; `iva = round2(base × rate)`.
6. `total = Σ (base + iva)`.
Devuelve `QuoteTotals`: subtotal, descuento, desglose por tipo de IVA (base, cuota) y total.

### Vectores de prueba obligatorios
| # | Entrada | Resultado |
|---|---|---|
| 1 | 4 × 50,00 @21 % + 1 × 120,00 @21 % | subtotal 320,00; IVA 67,20; total 387,20 |
| 2 | 1 × 100,00 @21 % + 1 × 200,00 @10 % | subtotal 300,00; IVA21 21,00; IVA10 20,00; total 341,00 |
| 3 | 2,5 × 10,01 @21 % | línea 25,03 (25,025 redondea hacia arriba); IVA 5,26; total 30,29 |
| 4 | Vector 2 con descuento 10 % | descuento 30,00; bases 90,00 y 180,00; IVA21 18,90; IVA10 18,00; total 306,90 |
| 5 | Descuento fijo 500,00 sobre subtotal 300,00 | descuento 300,00 (nunca mayor que el subtotal); total 0,00 |
| 6 | Presupuesto sin líneas | `DomainError.emptyQuote` al intentar guardarlo como enviado |
| 7 | Vector 2 con descuento fijo 5,00 | descuento 5,00 repartido 3,33 (10 %) y 1,67 (21 %); bases 196,67 (10 %) y 98,33 (21 %); IVA10 19,67; IVA21 20,65; total 335,32 |
| 8 | Vector 2 con descuento fijo 10,00 | descuento 10,00 repartido 6,67 (10 %) y 3,33 (21 %); bases 193,33 (10 %) y 96,67 (21 %); IVA10 19,33; IVA21 20,30; total 329,63 |
| 9 | 1 × 150,00 @10 % + 1 × 150,00 @21 % con descuento fijo 0,01 | descuento 0,01 repartido 0,01 (10 %) y 0,00 (21 %); bases 149,99 (10 %) y 150,00 (21 %); IVA10 15,00; IVA21 31,50; total 346,49 |

### Precios con IVA incluido (importación)
`netPrice = round4(priceWithVAT / (1 + rate))`. Ejemplo: 121,00 con IVA 21 % → 100,0000. 25,00 → 20,6612.

La importación admite una **columna opcional `IVA`** por fila, con el tipo de esa partida. Formato aceptado: `21`, `21%`, `0,21`, `10` → 21, 21, 21 y 10 (se guarda como porcentaje). Reglas:
- Si la fila trae IVA y el interruptor "los precios incluyen IVA" está activo, el tipo de la fila es el que se usa para convertir el precio (`round4(precio / (1 + tipo))`).
- Si la fila trae IVA y el interruptor está inactivo, el precio se copia tal cual y la partida queda con ese tipo.
- Si la fila no trae IVA (o la columna no está asignada), se usa el tipo del interruptor global de la importación.
- Un valor ilegible no corta la importación: la partida se crea con el tipo por defecto y la revisión muestra un aviso.

### IVA por partida
- El IVA de una línea es `Item.vatRate` si la partida lo tiene; si es `nil`, el `Quote.defaultVATRate` del presupuesto (que copia el `BusinessProfile.defaultVATRate` al crearlo).
- El tipo se copia a la línea en el momento de añadirla: es un snapshot, como el nombre, la unidad y el precio. Cambiar el IVA de una partida no altera presupuestos ya hechos; tampoco cambiar el IVA por defecto del negocio.
- Un presupuesto puede tener líneas con tipos distintos: `QuoteCalculator` ya agrupa por `line.vatRate`.

## Reglas
1. Cambiar el precio de una partida NO modifica presupuestos existentes (las líneas son copias).
2. Duplicar un presupuesto copia las líneas tal cual (precios del momento), el descuento, las notas, el tipo de IVA por defecto y los datos del cliente; asigna número nuevo, fecha de hoy y estado `draft`. Una acción aparte "actualizar precios" puede recalcular desde el catálogo.
3. Numeración: `<prefijo>-<año>-<secuencia de 4 dígitos>`, p. ej. `P-2026-0001`. La secuencia reinicia cada año.
4. Estados: `draft → sent`; `sent → accepted`, `sent → rejected`, `sent → draft`. `accepted` y `rejected` son estados terminales en el MVP: cualquier otra transición lanza `DomainError.invalidTransition(from:to:)`.
5. Plan Pro: sin límite de presupuestos (límite nulo). Plan gratuito: 5 presupuestos creados por mes natural (`QuotaPolicy`, con `Clock` inyectado); el contador se reinicia al cambiar de mes. El plan lo decide `EntitlementProvider` (puerto).

## Alias aprendidos
Cuando el usuario resuelve una línea ambigua o sin coincidencia, `LearnAlias` guarda la frase normalizada (sin cantidad ni unidad) como alias de la partida elegida. Reglas: único por partida, máximo 20 por partida, nunca duplica el nombre ni otro alias existente de la misma partida.

## Casos de uso (nombres)
`InterpretRequest`, `ResolveAmbiguousLine`, `LearnAlias`, `CalculateQuote`, `CreateQuote`, `UpdateQuote` (guarda cliente, descuento, notas y líneas ya construidas), `AddLine`, `UpdateLineQuantity`, `RemoveLine`, `DuplicateQuote`, `ChangeQuoteStatus`, `AddKitToQuote`, `ListQuotes`, `ManageItems` (crear/editar/borrar), `ManageKits`, `ImportTariff` (aplica el mapeo de columnas ya revisado), `LoadTradePack`, `SaveBusinessProfile`, `CheckQuota`, `ExportQuotePDF` (usa el puerto `QuotePDFRenderer`).
