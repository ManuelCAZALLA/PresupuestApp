---
name: quote-pdf-export
description: Generación del PDF del presupuesto en el dispositivo y envío por WhatsApp o correo: contenido obligatorio, maquetación, marca de agua del plan gratuito y pruebas. Úsala siempre que toques QuotePDFRenderer, QuotePreview, el diseño del documento, la hoja de compartir o la marca de agua.
---

# PDF del presupuesto

Puerto `QuotePDFRenderer` en QuoteCore; implementación en `App/Data/PDF`; pantalla S6 `QuotePreview`.

## Contenido obligatorio (en este orden)
1. Cabecera: logo (si hay), nombre o empresa, NIF, teléfono, correo.
2. Título "Presupuesto", número, fecha, validez ("válido hasta …").
3. Cliente: nombre, teléfono, dirección y, si existe, dirección de la obra.
4. Tabla de líneas: concepto, unidad, cantidad, precio unitario, total de línea (sin IVA).
5. Subtotal, descuento (si lo hay), desglose por tipo de IVA (base y cuota), total con IVA, destacado.
6. Notas y condiciones (forma de pago, plazos, exclusiones).
7. Pie con el texto de aceptación si se define en ajustes. Sin firma digital en el MVP.
8. Marca de agua discreta SOLO en el plan gratuito.

## Reglas técnicas
- Generar con `UIGraphicsPDFRenderer` (o PDFKit) en el dispositivo, sin red.
- A4, márgenes de 18 mm. La tabla se parte en varias páginas con cabecera repetida; el total nunca queda solo en una página nueva.
- Importes con formato es-ES a partir de `QuoteTotals`; el renderer NO recalcula nada.
- Tipografía del sistema, tamaño mínimo 9 pt, buen contraste en impresión en blanco y negro.
- Nombre de archivo: `Presupuesto-<número>-<cliente>.pdf` (sin caracteres raros).
- Envío con la hoja de compartir del sistema (`ShareLink`) para WhatsApp, correo, Archivos.

## Pruebas
- Un PDF generado de un presupuesto de ejemplo con 3, 25 y 80 líneas.
- Comprobar que el texto del PDF contiene número, total y desglose de IVA (extraer texto con PDFKit en el test).
- Con y sin logo, con y sin descuento, con y sin marca de agua.
