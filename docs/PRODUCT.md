# Producto — MVP

## Objetivo
Que un fontanero, albañil o electricista, en menos de 5 minutos desde que instala la app, tenga su tarifa cargada y pueda sacar un presupuesto en PDF para enviar por WhatsApp.

## Usuarios y oficios (v1)
Fontanería, albañilería y electricidad. Cada oficio trae un "pack" de partidas (nombre, unidad, sinónimos) SIN precio. El usuario pone los suyos.

## Principios
1. Los precios salen siempre de la tarifa del usuario.
2. Todo es editable antes de enviar.
3. Funciona sin conexión.
4. Manejable con una mano, en obra: botones grandes, pocos pasos.
5. Prefiere preguntar de más a acertar de menos.

## Pantallas
Cada pantalla es una carpeta en `App/Presentation/Features/`.

| Id | Feature (carpeta) | Para qué sirve | Criterio de aceptación |
|---|---|---|---|
| S1 | `Onboarding` | Elegir oficio, datos de empresa, IVA por defecto, cargar pack o importar tarifa | Se completa en menos de 5 min; se puede saltar el logo |
| S2 | `QuoteList` | Lista de presupuestos con estado y búsqueda; botón grande "Nuevo presupuesto" | Estados: borrador, enviado, aceptado, rechazado; duplicar desde aquí |
| S3 | `NewQuote` | Datos del cliente + zona de dictado o escritura | Dictado nativo sin red; texto editable antes de interpretar |
| S4 | `MatchReview` | Revisar lo que la app entendió, línea por línea | Verde = automática, naranja = ambigua (2-3 opciones), rojo = sin coincidencia; nunca se avanza con líneas rojas sin resolver |
| S5 | `QuoteEditor` | Líneas con +/−, buscar partida, añadir kit, horas de mano de obra, desplazamiento, descuento, IVA, total | Total recalculado al instante; coincide con los vectores de `docs/DOMAIN.md` |
| S6 | `QuotePreview` | Vista previa del PDF y envío (WhatsApp, correo, guardar) | PDF con logo, datos, líneas, IVA, condiciones y validez |
| S7 | `Catalog` | Lista por categorías, búsqueda, crear/editar partida (nombre, alias, unidad, precio, tipo) | Cambiar un precio no altera presupuestos ya hechos |
| S8 | `ImportTariff` | Cargar tarifa: Excel, CSV, pegar texto; asignar columnas; revisar; marcar si los precios llevan IVA | Nada se guarda sin pantalla de revisión |
| S9 | `Kits` | Paquetes de partidas ("cambio de termo") | Un kit se añade a un presupuesto de un toque |
| S10 | `Settings` | Empresa, logo, IVA por defecto, condiciones, validez, numeración | Cambios aplican a presupuestos nuevos, no a los antiguos |
| S11 | `Paywall` | Planes Pro | Solo se muestra al llegar al límite o desde Ajustes |

Los clientes NO tienen pantalla propia: se guardan dentro del presupuesto.

## Funcionalidades
- Importación de tarifa (Excel, CSV, texto pegado, alta manual, pack del oficio, compartir archivo desde otra app). Foto/PDF con OCR: después del MVP.
- Motor de interpretación sin IA (ver `docs/PARSER.md`).
- Cálculo con IVA editable por presupuesto y por línea (ver `docs/DOMAIN.md`).
- PDF generado en el dispositivo.
- Duplicar presupuesto.
- Aprendizaje de alias: al corregir, la frase se guarda como alias de la partida elegida.
- Copia de seguridad: exportar/importar catálogo.

## Fuera del MVP
Facturación, firma del cliente, agenda, nube/sincronización, multiusuario, IA, precios de mayoristas, formato BC3, foto/PDF con OCR.

## Modelo de negocio (propuesto, por confirmar)
- Gratis: hasta 5 presupuestos al mes, con marca de agua discreta en el PDF.
- Pro: ilimitado, sin marca, kits ilimitados, logo, exportación. Suscripción mensual/anual.
