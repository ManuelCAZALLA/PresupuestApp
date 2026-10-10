---
name: quote-math-spain
description: Cálculo de presupuestos con IVA en España: redondeo, descuentos, desglose por tipo de IVA y precios con IVA incluido. Úsala siempre que toques totales, líneas de presupuesto, descuentos, IVA, redondeos, QuoteCalculator, o importes mostrados en pantalla o PDF, incluso si solo "cambias un cálculo pequeño".
---

# Cálculo de presupuestos

Fuente de verdad: `docs/DOMAIN.md` (sección "Cálculo" y "Vectores de prueba"). Esta skill resume cómo trabajar sin equivocarte.

## Reglas
1. `Decimal` siempre. Prohibido `Double`/`Float` en importes.
2. Redondeo a 2 decimales con `.plain`, solo en: total de línea, descuento, base por tipo de IVA y cuota de IVA.
3. Orden: línea → subtotal → descuento → reparto del descuento por tipo de IVA → IVA por grupo → total.
4. El descuento nunca supera el subtotal.
5. El IVA es editable por presupuesto y por línea. No hardcodear 21 % ni 10 % en la lógica; son valores por defecto de configuración.
6. Las líneas guardan copia de precio y nombre. Cambiar el catálogo no cambia presupuestos hechos.
7. El formato de moneda (coma decimal, símbolo €) va SOLO en Presentation.

## Procedimiento
1. Antes de cambiar nada, ejecuta los vectores existentes y confirma que pasan.
2. Si añades una regla, añade primero un vector nuevo a `docs/DOMAIN.md` y un test.
3. Implementa en `QuoteCore/Calculation`.
4. Prueba también: cantidad 0, cantidad con decimales, precio con 4 decimales, un solo tipo de IVA, varios tipos, descuento en % y fijo.

## Esqueleto de redondeo
```swift
extension Decimal {
    func rounded2() -> Decimal {
        var value = self, result = Decimal()
        NSDecimalRound(&result, &value, 2, .plain)
        return result
    }
}
```

## Nota fiscal
La app calcula; no asesora. Los tipos de IVA correctos para cada obra los decide el usuario con su gestor. No añadas lógica que "adivine" el IVA.
