---
name: catalog-import
description: Importación de la tarifa del usuario (Excel .xlsx, CSV, texto pegado, alta manual, packs por oficio) con asignación de columnas, detección de unidades, IVA incluido o no, y pantalla de revisión. Úsala siempre que toques importadores, lectores de archivos, ColumnMapper, el parseo de listas de precios o la pantalla ImportTariff.
---

# Importación de tarifa

Pantalla S8 (`ImportTariff`) y caso de uso `ImportTariff`. Los lectores viven en `App/Data/Import`; el caso de uso, en QuoteCore.

## Flujo (siempre igual)
1. **Origen**: archivo (.xlsx, .csv), texto pegado o recibido desde "Abrir con".
2. **Lectura** → tabla cruda (filas × columnas) + hoja elegida si hay varias.
3. **Asignación de columnas**: nombre, precio, unidad (opcional), categoría (opcional). Sugerir por cabeceras ("precio", "pvp", "importe", "ud", "unidad", "concepto", "descripción").
4. **Interruptor**: "Los precios incluyen IVA" sí/no y tipo de IVA. Convertir con `round4(precio / (1 + tipo))`.
5. **Pantalla de revisión**: lista de partidas detectadas con avisos (sin precio, precio ≤ 0, unidad desconocida, nombre duplicado). Se pueden editar o descartar filas.
6. **Confirmar**: aplicar con modo "añadir" o "reemplazar partidas del mismo nombre". Nada se guarda antes de este paso.

## Reglas
- Un importador devuelve `ImportResult { rows, warnings }`; nunca falla en silencio ni inventa datos.
- Precio: aceptar "25", "25,5", "25.50", "1.234,50", "25 €", "25€/ud". Si es ambiguo ("1.234"), pedir confirmación en la revisión.
- Unidad: reconocer "ud", "u", "unidad", "m", "ml", "metro", "m2", "m²", "h", "hora", "global", "pa" → `MeasureUnit`. Desconocida → `unit` con aviso.
- Detectar y saltar filas de título, vacías o de totales.
- Codificación CSV: probar UTF-8 y, si falla, Windows-1252; separador `,` o `;` (en España el Excel exporta con `;`).
- XLSX: lector externo permitido en M4 (p. ej. CoreXLSX). Leer valores, no fórmulas; fechas no interesan.
- Texto pegado: una línea por partida; precio = último número de la línea; unidad = token "/ud", "€/m", "/h" si existe; el resto es el nombre.
- Los datos del usuario no salen del dispositivo. No subir ni registrar el contenido de la tarifa en logs.

## Pruebas
Archivos de ejemplo en `Tests/` (xlsx con cabeceras en español, csv con `;` y coma decimal, texto pegado de WhatsApp, un archivo con filas basura). Cada archivo con su resultado esperado.

## Después del MVP
Foto de una tarifa en papel (OCR en el dispositivo con Vision/ML Kit) y PDF con texto. Mismo flujo, mismo paso de revisión, pero con avisos de baja confianza.
