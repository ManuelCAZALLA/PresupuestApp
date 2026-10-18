# Producto — MVP

## Objetivo
Que un fontanero, albañil o electricista, en menos de 5 minutos desde que instala la app, tenga su tarifa cargada y pueda sacar un presupuesto en PDF para enviar por WhatsApp.

## Usuarios y oficios (v1)
Fontanería, albañilería y electricidad. La app NO trae partidas: el usuario carga su propia tarifa (Excel, CSV, lista pegada o a mano). El oficio solo aporta un vocabulario de sinónimos para el motor de interpretación.

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
| S1 | `Onboarding` | Elegir oficio, datos de empresa e IVA por defecto; el catálogo arranca vacío y ofrece tres caminos: importar Excel/CSV, pegar una lista y añadir a mano | Se completa en menos de 5 min; se puede saltar el logo |
| S2 | `QuoteList` | Lista de presupuestos con estado y búsqueda; botón grande "Nuevo presupuesto" | Estados: borrador, enviado, aceptado, rechazado; duplicar desde aquí |
| S3 | `NewQuote` | Datos del cliente + zona de dictado o escritura | Dictado nativo sin red; texto editable antes de interpretar |
| S4 | `MatchReview` | Revisar lo que la app entendió, línea por línea | Verde = automática, naranja = ambigua (2-3 opciones), rojo = sin coincidencia; nunca se avanza con líneas rojas sin resolver |
| S5 | `QuoteEditor` | Líneas con +/−, buscar partida, añadir kit, horas de mano de obra, desplazamiento, descuento, IVA, total | Total recalculado al instante; coincide con los vectores de `docs/DOMAIN.md` |
| S6 | `QuotePreview` | Vista previa del PDF y envío (WhatsApp, correo, guardar) | PDF con logo, datos, líneas, IVA, condiciones y validez |
| S7 | `Catalog` | Lista por categorías, búsqueda, crear/editar partida (nombre, alias, unidad, precio, tipo) | Cambiar un precio no altera presupuestos ya hechos |
| S8 | `ImportTariff` | Cargar la tarifa del usuario: Excel/CSV, pegar una lista; asignar columnas; revisar; marcar si los precios llevan IVA; plantilla Excel descargable con columnas Nombre, Unidad y Precio | Nada se guarda sin pantalla de revisión |
| S9 | `Kits` | Paquetes de partidas ("cambio de termo") | Un kit se añade a un presupuesto de un toque |
| S10 | `Settings` | Empresa, logo, IVA por defecto, condiciones, validez, numeración | Cambios aplican a presupuestos nuevos, no a los antiguos |
| S11 | `Paywall` | Planes Pro | Solo se muestra al llegar al límite o desde Ajustes |

Los clientes NO tienen pantalla propia: se guardan dentro del presupuesto.

## Recorrido principal (sin dictado)
Tras el onboarding la app tiene tres pestañas: **Presupuestos**, **Precios** y **Ajustes**.
1. Primera apertura → `Onboarding` (S1): oficio, datos de empresa e IVA por defecto.
2. **Precios** (`Catalog` S7): el catálogo vacío ofrece importar archivo (Excel/CSV), pegar una lista o añadir a mano; el botón de importar (S8) está siempre accesible.
3. **Presupuestos** (`QuoteList` S2): "Nuevo presupuesto" → datos del cliente + añadir partidas del catálogo; las líneas se ajustan con +/−, se borran, se aplica descuento y el total se recalcula al instante.
4. Presupuesto terminado: desglose de IVA, "Ver PDF" (S6) y "Enviar" con la hoja de compartir del sistema (WhatsApp, correo, Archivos).

El dictado (S3) y la revisión de lo entendido (S4) llegan en M5: el recorrido de arriba funciona escribiendo y tocando, sin voz.

## IVA por partida
El IVA de una línea es el de la partida (`Item.vatRate`) si la tiene; si no, el del presupuesto, que a su vez viene del IVA por defecto del negocio. La importación admite una columna opcional `IVA` por fila. Ver `docs/DOMAIN.md`.

## Funcionalidades
- Catálogo 100 % del usuario: la app no trae partidas. El catálogo vacío ofrece importar Excel/CSV, pegar una lista o añadir a mano.
- Importación de tarifa (Excel, CSV, texto pegado, alta manual, compartir archivo desde otra app) y plantilla Excel descargable con columnas Nombre, Unidad y Precio. Foto/PDF con OCR: después del MVP.
- Motor de interpretación sin IA (ver `docs/PARSER.md`).
- Cálculo con IVA editable por presupuesto y por línea (ver `docs/DOMAIN.md`).
- PDF generado en el dispositivo.
- Duplicar presupuesto.
- Aprendizaje de alias: al corregir, la frase se guarda como alias de la partida elegida.
- Copia de seguridad: exportar/importar catálogo.

## Fuera del MVP
Facturación, firma del cliente, agenda, nube/sincronización, multiusuario, IA, precios de mayoristas, formato BC3, foto/PDF con OCR, packs de partidas por oficio (los sinónimos de oficio se mantienen como vocabulario del motor).

## Modelo de negocio (propuesto, por confirmar)
- Gratis: hasta 5 presupuestos al mes, con marca de agua discreta en el PDF.
- Pro: ilimitado, sin marca, kits ilimitados, logo, exportación. Suscripción mensual/anual.
